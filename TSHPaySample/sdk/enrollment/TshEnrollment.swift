//
// Copyright © 2021-2022 THALES. All rights reserved.
//  

import Foundation

import TSHPaySDK

/**
 Class to handle the card enrollment process.
 */
public class TshEnrollment: NSObject {
        
    let internalNotifications: InternalNotifications

    private var panSuffix: String?
    private var expiryDate: String?
    private var activationCode: Data?
    private var enrollmentState: TshEnrollmentState = TshEnrollmentState.inactive
    private var enrollmentError: String?
    private var termsCondition : TermsAndConditionSession?
    private var cardListHelper: CardListHelper?
    private var mgDigitizationDelegate: MGDigitizationDelegate?
        
    public override init() {
        self.internalNotifications = InternalNotifications()
        self.cardListHelper = CardListHelper.init()
        self.enrollmentState = .inactive
        super.init()
    }
    
    //MARK: public API

    /**
     Enrolls the payment card.
     
     @param pan PAN.
     @param expiryData Expiry Date.
     @param cvv CVV.
     */
    public func enrollCard(_ pan: String, expiryDate:String, cvv: String) {
        self.panSuffix = String(pan.suffix(4))
        self.expiryDate = expiryDate
        updateEnrollmentState(.wseCheckStart)
        SdkHelper.shared().tshInitBase?.performWseIfNeeded({ isSuccess, error in
            if(isSuccess) {
                self.updateEnrollmentState(.wseCheckFinished)
                self.checkDeviceEligibility(pan, expiryDate, cvv)
            } else {
                self.updateEnrollmentState(.wseCheckError, error?.localizedDescription)
            }
        })
    }
    
    /**
     Accpets the Terms and Conditions.
     
     @param termsConditionsObj The Terms and Conditions object.
     */
    public func acceptTermsCondition(_ termsConditionsObj: TermsAndConditions?) {
        if let token = termsConditionsObj?.accept() {
            let enrollmentService = MobileGatewayManager.sharedInstance().getCardEnrollmentService()
            self.mgDigitizationDelegate = TshEnrollmentMGDigitizationDelegate.init(self)
            enrollmentService?.digitizeCard(token, authenticationCode: nil, authenticationCodeToken: nil, mgDigitizationDelegate: self.mgDigitizationDelegate!)
            self.updateEnrollmentState(TshEnrollmentState.digitizationStart);
        }
    }
    
    /**
     Selects the Identification and Verification method.
     
     @param idvMethodSelector Identification and Verification selector object.
     @param idvId Selected Identification and Verification ID.
     */
    public func selectIdv(_ idvMethodSelector: IDVMethodSelector?, _ idvId: String) {
        self.updateEnrollmentState(TshEnrollmentState.enrollingStart)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  //Async block is just for UI behaviour because trigger method select is so fast and UI doesn't launch Loading View
            do {
                try idvMethodSelector?.select(idvId)
            } catch {
                AppLoggerHelper.log(.error, "\(TshEnrollment.typeName) selectIdv", error.localizedDescription)
            }

        }
    }
    
    /**
     Submits the activation code.
     
     @param activationCode Activation code.
     @param pendingCardActivation Pending activation object.
     */
    public func submitActivationCode(_ activationCode: ContiguousArray<CChar>, pendingCardActivation: PendingCardActivation?) {
        self.updateEnrollmentState(TshEnrollmentState.enrollingStart)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  //Async block is just for UI behaviour because trigger method select is so fast and UI doesn't launch Loading View
            var activationCodeString = String()
            for char:Int8 in activationCode {
                activationCodeString.append(Character(UnicodeScalar(UInt8(char))))
            }
            activationCodeString = activationCodeString.replacingOccurrences(of: "\0", with: "", options: NSString.CompareOptions.literal, range:nil)// \0 (null character)
            var data = activationCodeString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            if (data != nil) {
                do {
                    try pendingCardActivation?.activate(data!, mgDigitizationDelegate: self.mgDigitizationDelegate!, error : ())
                } catch {
                    AppLoggerHelper.log(.error, "\(TshEnrollment.typeName) selectIdv", error.localizedDescription)
                }
            }
            data = nil
            activationCodeString = ""
        }
    }
    
    /**
     MGDigitization Delegate for continue pending card activation  process.
     */
    public func getMGDigitizationDelegate() -> MGDigitizationDelegate {
        if (mgDigitizationDelegate == nil) {
            self.mgDigitizationDelegate = TshEnrollmentMGDigitizationDelegate.init(self)
        }
        return self.mgDigitizationDelegate!
    }

    //MARK: private API

    /**
     TSH Pay SDK requires secure enclave coprocessor to function. Hence, it is mandatory to check for the device eligibility before any enrollment attempt is made
     */
    private func checkDeviceEligibility(_ pan: String, _ expiryDate:String, _ cvv: String) {
        self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckStart);
        let enrollmentService = MobileGatewayManager.sharedInstance().getCardEnrollmentService()
        let enrollingBusinessService = ProvisioningServiceManager.sharedInstance().getEnrollingBusinessService()
        guard let eligibility = enrollingBusinessService?.checkDeviceEligibility() else {
            return
        }
        switch eligibility {
            case .HARDWARE_NOT_SUPPORTED:
            AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) updateToken", Bundle.main.localizedString(forKey:"enrollment_eligibility_hardware_support_error", value:nil, table: nil))
                self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckError, Bundle.main.localizedString(forKey:"enrollment_eligibility_hardware_support_error", value:nil, table: nil));
            case .NO_CONFIGURATION_FOUND:
                AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) updateToken", Bundle.main.localizedString(forKey:"enrollment_eligibility_biometric_error", value:nil, table: nil))
                self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckError, Bundle.main.localizedString(forKey:"enrollment_eligibility_biometric_error", value:nil, table: nil));
            case .SATISFIED:
                AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) updateToken", "Proceed with enrollment!")
                let serialNumber = getUUID()
                let encrypt = MGCardInfoEncryptor.encrypt(SdkConstants.publicKey, withIdentifier: SdkConstants.subjectIdentifier, withPan: pan, withExpiry: expiryDate, withCVV: cvv)
                if (encrypt != nil) {
                    enrollmentService?.checkCardEligibility(encrypt!, inputMethod: InputMethodEnum.MANUAL, language: "en", serialNumber: serialNumber, completionBlock: { termsAndConditions, issuerData, mobielGatewayError, error in
                        if (mobielGatewayError != nil) {
                            self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckError, mobielGatewayError!.getMessage());
                        } else if (error != nil) {
                            self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckError);
                        } else {
                            NotificationCenter.default.post(name: .receivedTermsAndConditions, object: termsAndConditions)
                            self.updateEnrollmentState(TshEnrollmentState.eligibilityCheckFinished);
                        }
                    })
                }
            default:
                updateEnrollmentState(TshEnrollmentState.eligibilityCheckError, Bundle.main.localizedString(forKey:"enrollment_eligibility_error", value:nil, table: nil));
                fatalError("\(TshEnrollment.typeName)" + Bundle.main.localizedString(forKey:"enrollment_eligibility_error", value:nil, table: nil))
        }
    }

    private func getUUID() -> String {
        let uuid = NSUUID().uuidString
        return uuid
    }
    
    private func updateEnrollmentState(_ state: TshEnrollmentState) {
        updateEnrollmentState(state, nil)
    }
    
    private func updateEnrollmentState(_ state: TshEnrollmentState, _ errorMessage: String?) {
        // Store last state so it can be read onResume when app was not in foreground.
        enrollmentState = state;
        enrollmentError = errorMessage;
        internalNotifications.updateEnrollmentState(enrollmentState, enrollmentError)
    }

    private static var typeName: String {
        return String(describing: self)
    }
    
    //MARK: EnrollingServiceDelegate API
    
    private class TshEnrollmentEnrollingServiceDelegate:  EnrollingServiceDelegate {
        
        let tshEnrollment: TshEnrollment
        
        init(_ tshEnrollment: TshEnrollment) {
            self.tshEnrollment = tshEnrollment
        }
        
        public func onStarted(_ businessService: BusinessService) {
            // Notify logic layer and update any possible UI.
//            tshEnrollment.updateEnrollmentState(TshEnrollmentState.enrollingStart)
        }
        
        public func onCompleted(_ businessService: BusinessService) {
            // Notify logic layer and update any possible UI.
//            tshEnrollment.updateEnrollmentState(TshEnrollmentState.enrollingFinished)
        }

        public func onError(_ businessService: BusinessService, error: ProvisioningServiceError) {
            // Notify logic layer and update any possible UI.
            tshEnrollment.updateEnrollmentState(TshEnrollmentState.enrollingError, error.errorMessage)
        }
        
        public func onCodeRequired(_ businessService: BusinessService, codeInput codeInputHandler: CHCodeInput) {
            // Notify logic layer and update any possible UI.
//            tshEnrollment.updateEnrollmentState(TshEnrollmentState.enrollingCodeRequired)
            
            // Set activation code to SDK.
            if tshEnrollment.activationCode != nil {
                let secureCodeInputer = codeInputHandler.secureCodeInputer()
                tshEnrollment.activationCode!.forEach({ (byte) in
                    _ = secureCodeInputer.input(Int8(byte))
                })
                do {
                    try secureCodeInputer.finish()
                } catch {
                    AppLoggerHelper.log(.error, "\(TshEnrollment.typeName) localizedDescription: \(error.localizedDescription)", "error: \(error);")
                }
                // Wipe after use
                for i in 0..<tshEnrollment.activationCode!.count {
                    tshEnrollment.activationCode![i] = 0
                }
                tshEnrollment.activationCode = nil
            }
        }
    }
    
    //MARK: MGDigitizationDelegate API
    
    private class TshEnrollmentMGDigitizationDelegate: NSObject, MGDigitizationDelegate {
        
        let tshEnrollment: TshEnrollment
        private var enrollingServiceDelegate: EnrollingServiceDelegate?

        init(_ tshEnrollment: TshEnrollment) {
            self.tshEnrollment = tshEnrollment
            super.init()
        }
        
        /**
         Triggered once the digitization process is initiated and the CPS activationCode is sent from the MobileGateway server.
         At this point you can trigger in parallel the provisioning session.
        */
        public func onCPSActivationCodeAcquired(_ digitalCardId: String, activationCode: Data) {
            // Notify logic layer and update any possible UI.
            tshEnrollment.updateEnrollmentState(TshEnrollmentState.digitizationActivationCodeAcquired);
                        
            tshEnrollment.activationCode = activationCode
            
            let enrollingBusinessService = ProvisioningServiceManager.sharedInstance().getEnrollingBusinessService()
            let provisioningBusinessService = ProvisioningServiceManager.sharedInstance().getProvisioningBusinessService()
            
            //WalletID of MG SDK is userID of CPS SDK Enrollment process
            let userId: String = (MobileGatewayManager.sharedInstance().getCardEnrollmentService()?.getWalletId())!
            
            let status = enrollingBusinessService?.isEnrolled
            self.enrollingServiceDelegate = TshEnrollmentEnrollingServiceDelegate.init(tshEnrollment)
            switch (status) {
                case .ENROLLMENT_NEEDED:
                    //first time enroll
                    let firebaseToken:String? = getFirebaseToken()
                    if (!firebaseToken!.isEmpty) {
                        enrollingBusinessService?.enroll(userId, fcmToken: firebaseToken!, userLanguange: "en", delegate: self.enrollingServiceDelegate!)
                    }
                case .ENROLLMENT_IN_PROGRESS:
                    //continue of enrolment process as breaks before completion
                    enrollingBusinessService?.continueEnrollment("en", delegate: self.enrollingServiceDelegate!)
                case .ENROLLMENT_COMPLETED:
                    //send activation code
                    do {
                        try provisioningBusinessService?.sendActivationCode(with: self.enrollingServiceDelegate!)
                    } catch {
                        AppLoggerHelper.log(.error, "\(TshEnrollment.typeName) localizedDescription: \(error.localizedDescription)", "error: \(error);")
                    }
                default:
                    AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) onCPSActivationCodeAcquired", "Unhandled status:")
            }
        }
            
        /**
         YELLOW FLOW only
         Triggered to provide the list of possible ID&V methods accepted.
         You've to provide this list to the user so that a method of authentication can be selected.
        */
        public func onSelectIDVMethod(_ idvMethodSelector: IDVMethodSelector) {
            AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) onSelectIDVMethod", nil)
            NotificationCenter.default.post(name: .receivedIdvMethodSelector, object: idvMethodSelector)
            self.tshEnrollment.updateEnrollmentState(TshEnrollmentState.selectIdMethod);
        }
        
        /**
         YELLOW FLOW only
         Only if OTP ord 3DS is REQUIRED.
        */
        public func onActivationRequired(_ pendingCardActivation: PendingCardActivation) {
            AppLoggerHelper.log(.info, "\(TshEnrollment.typeName) onActivationRequired", nil)
            NotificationCenter.default.post(name: .activationRequired, object: pendingCardActivation)
            self.tshEnrollment.updateEnrollmentState(TshEnrollmentState.activationCodeRequired);
        }
        
        /**
         Triggered when the card digitization process is completed.
        */
        public func onComplete(_ digitalCardId: String) {
            if (self.tshEnrollment.expiryDate != nil && self.tshEnrollment.panSuffix != nil) {
                DataPersistance.savePanExpiration(self.tshEnrollment.expiryDate!, panSuffix: self.tshEnrollment.panSuffix!)
            }
            // Notify logic layer and update any possible UI.
            NotificationCenter.default.post(name: .digitizationFinished, object: digitalCardId)
            tshEnrollment.updateEnrollmentState(TshEnrollmentState.digitizationFinished);
        }
        
        /**
         Triggered when there is an error occurred during the digitization process.
         The mobile application has to parse the error accordingly
        */
        public func onError(_ digitalCardId: String?, error: MobileGatewayError?) {
            // Notify logic layer and update any possible UI.
            tshEnrollment.updateEnrollmentState(TshEnrollmentState.digitizationError, error?.getMessage())
        }
        
        //MARK: private API
        private func getFirebaseToken() -> String? {
            let waitSeconds: Int = 5
            var firebaseToken:String? = SdkHelper.shared().tshPush?.getPushTokenLocal()
            let dispatchQueueProcess = DispatchQueue.global(qos: .userInteractive)
            let semaphore = DispatchSemaphore(value: 0)
            dispatchQueueProcess.async {
                if (firebaseToken!.isEmpty) {
                    let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".timer")
                    let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: queue)
                    timer.schedule(deadline: .now(), repeating: .milliseconds(500))
                    timer.setEventHandler {
                        firebaseToken = SdkHelper.shared().tshPush?.getPushTokenLocal()
                        if (firebaseToken != nil) {
                            timer.cancel()
                            semaphore.signal()
                        }
                    }
                    timer.activate()
                }
            }
            if (semaphore.wait(timeout: DispatchTime.now() + .seconds(waitSeconds)) == .timedOut && firebaseToken!.isEmpty) {
                self.tshEnrollment.updateEnrollmentState(TshEnrollmentState.digitizationError, Bundle.main.localizedString(forKey:"push_token_error", value:nil, table: nil))
            }
            return firebaseToken
        }

    }
}
