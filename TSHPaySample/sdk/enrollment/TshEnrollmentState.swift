//
// Copyright © 2021-2022 THALES. All rights reserved.
//  

import Foundation

/**
 Class the hold the state of the payment card enrollment process.
 */
public enum TshEnrollmentState {
    
    case inactive
    // Eligibility
    case eligibilityCheckStart
    case eligibilityCheckError
    case eligibilityCheckFinished

    // Digitization
    case digitizationStart
    case digitizationActivationCodeAcquired
    case digitizationError
    case digitizationFinished // This event is not always triggered before enrolling starts. Sometimes it's not triggered at all. Do not relay on it.

    // Enrolling
    case selectIdMethod
    case activationCodeRequired
    case enrollingCodeRequired
    case enrollingStart
    case enrollingError
    case enrollingFinished
    case pendingCardActivationIDVSelection

    // Waiting for profile activation and token replenish through push notifications.
    case waitingForServer
    case cardInstalled       // REQUEST_INSTALL_CARD
    case kyesReplanished     // REQUEST_REPLENISH_KEYS
    
    // Wallet secure enrollment
    case wseCheckStart
    case wseCheckFinished
    case wseCheckError

    /**
     * Return whether state represent some error.
     */
    func isErrorState() -> Bool {
        switch self {
            case .eligibilityCheckError, .digitizationError, .enrollingError:
                return true
            default:
                return false
        }
    }
    
    /**
     * Return if status represent ongoing process.
     */
    func isProgressState() -> Bool {
        if (self != TshEnrollmentState.inactive && self != TshEnrollmentState.eligibilityCheckError && self != TshEnrollmentState.digitizationError
            && self != TshEnrollmentState.enrollingError && self != TshEnrollmentState.kyesReplanished && self != TshEnrollmentState.cardInstalled) {
            return true
        }
        return false
    }
}
