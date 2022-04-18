/*
 MIT License
 
 Copyright (c) 2021 Thales DIS
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */
  

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
