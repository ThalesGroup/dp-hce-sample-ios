//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation
import SwiftUI

struct Card: Identifiable {
    var id: String //tokenizedCardId
    
    let pan: String
    var defaultPayment: Bool
    var suspend: Bool
    var resume: Bool
    var qrPaymentTypeSupported: Bool
    var state: DigitalizedCardState
    let panExpiry: String
    let backgroundImage: Data?
    let pendingCardActivation:PendingCardActivation?
}
