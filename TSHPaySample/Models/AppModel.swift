//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import SwiftUI
import TSHPaySDK
import FirebaseMessaging

class AppModel: ToastHelper, ObservableObject {
    // MARK: - Defines
    
    public enum Destination: Codable, Hashable {
        case addCard
    }
    
    private var wseState: WalletSecureEnrollmentService.State?
    private var lastServerMessage: String?
    
    @Published var navPath = NavigationPath()
    @Published var currentEnrollmentState = EnrollmentState.notStarted
    @Published var cardForManualPayment: String?
    @Published var reloadCardList: Bool = false
    
    // MARK: - Router
    
    func navigate(to destination: Destination) {
        DispatchQueue.main.async { [self] in
            navPath.append(destination)
        }
    }
    
    func navigateBack() {
        DispatchQueue.main.async { [self] in
            navPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        DispatchQueue.main.async { [self] in
            navPath.removeLast(navPath.count)
        }
    }
        
    // MARK: - TSHPay methods
       
    public func invokeWSEIfNeeded()  {
        Task {
            do {
                let wse = WalletSecureEnrollmentService()
                if try await !wse.isEnrolled() {
                    try await wse.enroll()
                    for await state in await wse.eventStream {
                        switch state {
                        case .started:
                            wseState = .started
                            toastShow(caption: "Wallet secure enrollment", description: "WSE started", type: .info)
                        case .completed:
                            wseState = .completed
                            toastShow(caption: "Wallet secure enrollment", description: "WSE completed", type: .info)
                        case .errorEncountered(let error):
                            wseState = .errorEncountered(error)
                            toastShow(caption: "Wallet secure enrollment", description: "WSE error. \(error)", type: .error)
                        @unknown default:
                            fatalError("Unexpected WSE state.")
                        }
                    }
                } else {
                    wseState = .completed
                }
            } catch {
                toastShow(caption: "Wallet secure enrollment", description: "WSE initialize error. \(error)", type: .error)
            }
        }
    }
    
    public func enrollCard(pan: String, exp: String, cvv: String) {
        // Allow only one enrollment at time.
        guard case .notStarted = currentEnrollmentState else {
            toastShow(caption: "Enrollment warning", description: "Previous enrollment did not finished yet.")
            return
        }
        
        // Enrollment without push notification token is not possible since the last part is delivered through push notification.
        if Messaging.messaging().fcmToken == nil {
            toastShow(caption: "Enrollment error", description: "It's not possible to enroll card without walid push notification token.", type: .error)
            return
        }
        
        // Enrollment is also not possible without WSE
        // Actual application might want to wait for the WSE result and continue automatically to the desired action (enrollment) is possible.
        // For the simplification sample app only check that it's in required state.
        if case .started = wseState {
            toastShow(caption: "Enrollment warning", description: "Wallet secure enrollment is still ongoing. Please wait for the results.", type: .warning)
            return
        } else if case .errorEncountered(let err) = wseState {
            toastShow(caption: "Enrollment error", description: "Wallet secure enrollment failed with error \(err). Staring a new one.", type: .error)
            invokeWSEIfNeeded()
            return
        } else if case .none = wseState {
            toastShow(caption: "Enrollment warning", description: "Wallet secure enrollment was not started. Running enrollmnet first.", type: .warning)
            invokeWSEIfNeeded()
            return
        }
        
        withAnimation {
            currentEnrollmentState = .started
        }
        
        // All prerequirements are met, we can start the actual enrollment.
        Task {
            do {
                // Try to encrypt card data.
                // Application should use this feature for manual entry yellow flow.
                // Green flow should always get encrypted data from the backend.
                guard let data = "{\"fpan\":\"\(pan)\",\"exp\":\"\(exp)\",\"cvv\":\"\(cvv)\"}".data(using: .utf8),
                      let encryptedCardInfo = CryptoUtil.encryptDataWithPKCS7(data, pubKey: serverEnvironment.publicKey.hexadecimal) else {
                    await enrollmentEndded()
                    toastShow(caption: "Enrollment error", description: "Failed to generate encrypted data.", type: .error)
                    return
                }
                
                // Sample application covers only manual entry. Let's create instrumented data from entered values.
//                let instrumentDataComponent = CardDigitizationService.InstrumentDataComponents(encryptedCardData: encryptedCardInfo)
                let instrumentDataComponent = CardDigitizationService.InstrumentDataComponents(encryptedCardData: encryptedCardInfo,
                                                                                               publicKeyIdentifier: serverEnvironment.keyIdentifier)
                
                // Language is used for getting the TnC asset from scheme.
                let eligibilityData = CardDigitizationService.EligibilityDataComponents(inputMethod: .manual, language: "en").eligibilityData()
                
                // 1] Check card eligibility and fetch terms and conditions in case of eligeble card.
                let acceptanceData = try await CardDigitizationService().checkEligibility(eligibilityData, instrumentData: instrumentDataComponent.instrumentData())
                
                // 2] Present T&C to the end user and wait for accept
                await MainActor.run {
                    withAnimation {
                        currentEnrollmentState = .termsAndConditions(acceptanceData: acceptanceData)
                    }
                }
            } catch {
                await enrollmentEndded()
                toastShow(caption: "Enrollment error", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    public func enrollCard() {
        // Try to accept T&C. It will crash if we are in the incorrect state.
        let tnc = currentEnrollmentState.acceptTermsAndConditions()
            
        Task {
            do {
                // Token should be already available since it was checked before card eligibility, but it could not harm anything to be sure.
                guard let fcmToken = Messaging.messaging().fcmToken else {
                    await enrollmentEndded()
                    
                    toastShow(caption: "Enrollment error", description: "It's not possible to enroll card without walid push notification token.", type: .error)
                    return
                }
                
                // Update UI.
                await MainActor.run {
                    withAnimation {
                        currentEnrollmentState = .digitization
                    }
                }
                
                let cardEnrollmentService = CardDigitizationService()
                try await cardEnrollmentService.digitizeCard(withTNC: tnc.accept(), pushToken: fcmToken, language: "en")
                
                // Enrollment stream is common for initial enrollment as well as resuming of pending activation during Yellow flow.
                // Only differenc is the screen who is handling the state. We do not want to lock user on adding card because of activation.
                await handleEnrollmentStream(cardEnrollmentService, fromAddCardScreen: true)
            }
            catch {
                await enrollmentEndded()
                
                toastShow(caption: "Enrollment error", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    public func resumePendingActivation(_ digitalCardID: String) {
        Task {
            do {
                let cardEnrollmentService = CardDigitizationService()
                guard let pendingActivationSession = await cardEnrollmentService.getPendingCardActivationSession(forDigitalCardID: digitalCardID), try await pendingActivationSession.state() != .aborted else {
                    toastShow(caption: "Pending activation", description: "Activation is cancelled.", type: .warning)
                    return
                }
                
                // Update UI.
                await MainActor.run {
                    withAnimation {
                        currentEnrollmentState = .activation
                    }
                }
                
                // Trigger the pending activation
                try await pendingActivationSession.resume()
                
                // Enrollment stream is common for initial enrollment as well as resuming of pending activation during Yellow flow.
                // Only differenc is the screen who is handling the state. We do not want to lock user on adding card because of activation.
                await handleEnrollmentStream(cardEnrollmentService, fromAddCardScreen: false)
            }
            catch {
                await enrollmentEndded()
                
                toastShow(caption: "Resume pending activation error", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    public func checkContactlessEligibility() {
        Task {
            var eligible = false
            var eligibilityText = "Device is not eligible for contactless payments."
            do {
                let contactlessEligibility = await TSHPay.shared.deviceEligibility.contactlessPaymentEligibility
                switch contactlessEligibility {
                case .supported:
                    eligible = true
                case .deviceNotSupported(let reason):
                    eligibilityText = eligibilityText.appending("(\(reason))")
                case .iosVersionNotSupported(let version):
                    eligibilityText = eligibilityText.appending("(iOS \(version))")
                case .systemNotEligible:
                    break
                @unknown default:
                    fatalError("Unexpected contactless payment.")
                }
                toastShow(caption: "Eligibility check:", description: eligibilityText)
                if eligible {
                    //TODO: set view for payments
                }
            }
        }
    }
    
    public func processIncomingNotification(_ userInfo: [AnyHashable : Any])  {
        lastServerMessage = nil
        
        Task {
            do {
                // Unsupported notification content.. We can ignore this message.
                guard let userInfo = userInfo as? [String: Any] else {
                    AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Unsupported push notification content.")
                    return
                }
                
                let notification = NotificationService()
                try await notification.processNotification(forUserInfo: userInfo)
                for await state in await notification.notificationEventStream{
                    switch state {
                    case .completed:
                        // Messages depends on the scheme. This is example for MC and PURE
                        // 1. NotificationService.KnownMessage.requestInstallCard
                        // 2. NotificationService.KnownMessage.requestResumeCard
                        
                        if lastServerMessage == NotificationService.KnownMessage.requestResumeCard.rawValue ||
                            lastServerMessage == NotificationService.KnownMessage.requestSuspendCard.rawValue ||
                            lastServerMessage == NotificationService.KnownMessage.requestDeleteCard.rawValue ||
                            lastServerMessage == NotificationService.KnownMessage.requestResumeCard.rawValue {
                            await MainActor.run {
                                withAnimation {
                                    reloadCardList = true
                                }
                            }
                        }
                        lastServerMessage = nil
                    case .unsupportedPushContent(pushMessage: let pushMessage):
                        AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Unsupported push message: \(String(describing: pushMessage))")
                        break
                    case .serverMessage(let serverMessage, let digitalcardid):
                        AppLogger.log(.info, "\(String(describing: self)) - \(#function)", "Server message received. Message: \(String(describing: serverMessage)). digitalcard ID: \(String(describing: digitalcardid))")
                        
                        guard let serverMessage = serverMessage else {
                            AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "MessageCode is null for some reason")
                            break
                        }
                        lastServerMessage = serverMessage.code
                    case .errorEncountered(let error, userInfo: _):
                        AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Error encounter: \(error.description)")
                    @unknown default:
                        AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "State not handled.")
                        break
                    }
                }
            } catch {
                let errorMessage = getNotificationServiceErrorMessage(error: error)
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Catch an error: \(errorMessage)")
            }
        }
    }
        
    // MARK: - Private helpers
    
    private func handleEnrollmentStream(_ service: CardDigitizationService, fromAddCardScreen: Bool) async {
        for await digitizeCardState in await service.eventStream {
            switch digitizeCardState {
            case .digitizationApproved(let digitalCardID):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Digitization approved: \(digitalCardID)")
                
                toastShow(caption: "Enrollment:", description: "digitizationApproved: \(digitalCardID)", type: .info)
                await enrollmentEndded()
                if fromAddCardScreen {
                    navigateBack()
                }
            case .digitizationApprovedWithIDV(let digitalCardID, let idvMethodSelector):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Digitization approved with IDV: \(digitalCardID), \(idvMethodSelector)")
                
                await enrollmentEndded(differentState: .digitizationApprovedWithIDV(digitalCardID: digitalCardID, idvMethodSelector: idvMethodSelector))
                if fromAddCardScreen {
                    // We will return from the add card page because card was already approved and main screen will ask for the OTP.
                    // Main screen because the card can be activated even from there if needed. We do not want to block user on the enrollment screen.
                    navigateBack()
                }
            case .activationRequired(let pendingCardActivation):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Activation required: \(pendingCardActivation)")
                                
                await enrollmentEndded(differentState: .activationRequired(pendingActivation: pendingCardActivation))
            case .invalidInput(let message):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Invalid input: \(message)")
                
                toastShow(caption: "Enrollment:", description: "Invalid input: \(message)", type: .warning)
                await enrollmentEndded()
            case .cancelled:
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Cancelled")
                
                toastShow(caption: "Enrollment:", description: "Cancelled", type: .warning)
                await enrollmentEndded()
            case .activatedByIDV(let digitalCardID):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Activated by IDV: \(digitalCardID)")
                
                toastShow(caption: "Enrollment:", description: "Activated by IDV: \(digitalCardID)", type: .info)
                await enrollmentEndded()
            case .errorEncountered(let error):
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Error encountered: \(error)")
                
                toastShow(caption: "Enrollment:", description: "Error encountered: \(error.localizedDescription)", type: .error)
                await enrollmentEndded()
            case .digitizationDeclined:
                AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Digitization declined")
                
                toastShow(caption: "Enrollment:", description: "Digitization declined", type: .warning)
                await enrollmentEndded()
            @unknown default:
                fatalError("Unexpected digitization state.")
            }
        }
    }
    
    private func getNotificationServiceErrorMessage(error: Swift.Error) -> String {
        var errorMessage: String = "Notification Service status: Failed!"
        if let error = error as? NotificationService.Error {
            switch error {
            case .deviceEnvironmentUnsafe(let err):
                errorMessage = err.localizedDescription
            case .clientError(let message):
                errorMessage = message
            case .serverError(let message):
                errorMessage = "Error: \(message)"
            case .networkError:
                errorMessage = "Error: \(error.description)"
            case .unknown(let err):
                errorMessage = "Error: \(err.localizedDescription)"
            @unknown default:
                errorMessage = "Failed with unknown error"
            }
        }
        return errorMessage
    }
    
    private func enrollmentEndded(differentState: EnrollmentState = .notStarted) async {
        await MainActor.run {
            withAnimation {
                currentEnrollmentState = differentState
            }
        }
    }
}
