//
// Copyright © 2024 THALES. All rights reserved.
//

import TSHPaySDK

public enum EnrollmentState: Equatable {
    public static func == (lhs: EnrollmentState, rhs: EnrollmentState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),(.started, .started), (.digitization, .digitization),
            (.waitingForResponse, .waitingForResponse), (.activation, .activation),
            (.termsAndConditions(acceptanceData: _), .termsAndConditions(acceptanceData: _)),
            (.digitizationApprovedWithIDV(digitalCardID: _, idvMethodSelector: _), .digitizationApprovedWithIDV(digitalCardID: _, idvMethodSelector: _)),
            (.activationRequired(pendingActivation: _), .activationRequired(pendingActivation: _)):
            return true
        default:
            return false
        }
    }
    
    case notStarted
    case started
    case digitization
    case activation
    case termsAndConditions(acceptanceData: TSHPaySDK.CardDigitizationService.EligibilityAcceptableData?)
    case digitizationApprovedWithIDV(digitalCardID: String, idvMethodSelector: CardDigitizationService.IDVMethodSelector)
    case activationRequired(pendingActivation: CardDigitizationService.PendingCardActivation)
    case waitingForResponse
    
    func isWaitingState() -> Bool {
        switch self {
        case .digitization, .started, .activation:
            return true
        default:
            return false
        }
    }
    
    func waitingText() -> String {
        switch self {
        case .started:
            return "Enrollment started.\n Waiting for server to check card eligiblity."
        case .digitization:
            return "Card digitization in progress."
        case .activation:
            return "Card activation in progress."
        default:
            fatalError("Enum is not waiting state.")
        }
    }
    
    func termsAndConditionsText() -> String {
        if case .termsAndConditions(let acceptanceData) = self {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                return String(localized: "LoremIpsum")
            } else {
                return (acceptanceData?.termsAndConditions.content)!
            }
        } else {
            fatalError("T&C text is only available for that specific event value.")
        }
    }
    
    func acceptTermsAndConditions() -> TSHPaySDK.CardDigitizationService.TermsAndConditions {
        if case .termsAndConditions(let acceptanceData) = self {
            return acceptanceData!.termsAndConditions
        } else {
            fatalError("T&C text is only available for that specific event value.")
        }
    }
}

