//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import SwiftUI
import TSHPaySDK
import LocalAuthentication
import CoreNFC

class PaymentModel: ToastHelper, ObservableObject {
    
    var isPaymentOngoing = false
    let session = ContactlessPaymentSession()
        
    // MARK: - private methods
    
    private func biometricType() -> LABiometryType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            return authContext.biometryType
        }
        return LABiometryType.none
    }
    
    // MARK: - TSHPay methods
    
    func handleFieldDetect(){
        // to tell if it is a normal field detect or we consider as readerDetect for ongoing paymentSession
        // only for iOS 18 +
        if #available(iOS 18, *), isPaymentOngoing {
            // it is iOS 18 + where ongoing payment had received readerDetect event
            Task {
                try await self.session.startEmulation()
            }
        } else {
            // handle field detect normally on following scenario:
            // - iOS 17.4+, regardless payment ongoing OR not ongoing.
            // - iOS 18.x, payment not ongoing.
            let biometricType = biometricType()
            // start payment directly for fingerprint
            if biometricType == .touchID {
                startContactlessPayment()
            } else {
                toastShow(caption: "Reader Detect", description: "Please Double-click to start the payment", type: .info)
            }
        }
    }

    /*
     Initiate contactless payment
     */
    func startContactlessPayment(withDigitalCardID digitalCardID: String? = nil) {
        Task {
            isPaymentOngoing = false

            do {
                if(!PresentmentIntentAssertion.isValid()) {
                    try await PresentmentIntentAssertion.acquire()
                }
            } catch {
                /// Handle failure to acquire NFC presentment intent assertion. We have to directly start emulation, at least we wont get app re-directed
                toastShow(caption: "NFCPresentmentIntentAssertion", description: "start emulation", type: .info)
            }
            
            if let digitalCardID {
                toastShow(caption: "StartPayment", description: "with digitalCardID", type: .info)
                await session.startPayment(withDigitalCardID: digitalCardID)
            } else {
                toastShow(caption: "StartPayment", description: "without digitalCardID", type: .info)
                await session.startPayment()
            }
            
            for await state in await session.eventStream {
                switch state {
                case .authenticationRequired(let authentication):
                    toastShow(caption: "ContactlessPayment", description: "authenticationRequired", type: .info)
                    // proceed with authentication. Biometric authentication will be prompted
                    Task {
                        authentication.proceed()
                    }
                case .authenticationCompleted:
                    toastShow(caption: "ContactlessPayment", description: "authenticationCompleted", type: .info)
                    isPaymentOngoing = true
                    // authentication is success.
                    try await session.startEmulation()
                    await session.setAlertMessage("Authentication Completed")
                    break
                case .posConnected:
                    // informative: application and show information to end user
                    toastShow(caption: "ContactlessPayment", description: "posConnected", type: .info)
                    await session.setAlertMessage("POS Connected")
                    break
                case .posDisconnected:
                    // informative: application and show information to end user
                    toastShow(caption: "ContactlessPayment", description: "posDisconnected", type: .info)
                    await session.setAlertMessage("POS Disconnected")
                    break
                case .transactionCompleted(let transactionContext):
                    // display UI to end user
                    toastShow(caption: "ContactlessPayment", description: "transactionCompleted:\(transactionContext.amount) \(transactionContext.currencyCode)", type: .info)
                    break
                case .errorEncountered(let error):
                    let errorDescription = error.localizedDescription
                    // display UI to end user
                    toastShow(caption: "ContactlessPayment", description: "error: \(errorDescription)", type: .error)
                    break
                @unknown default:
                    fatalError("fixme: ContactlessPayment encountered unknown case")
                }
            }
            isPaymentOngoing = false
            PresentmentIntentAssertion.presentmentIntent = nil /// Release presentment intent assertion.
        }
    }
}
