//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

struct CardDetail {
    let pan:String
    let cardExpiryDate: String
    let cvv: String
    let backgroundImage: Data?
    let cardState: DigitalizedCardState
    
    func cardExpiryDateMonth() -> String {
        return String(cardExpiryDate.prefix(2))
    }
    
    func cardExpiryDateYear() -> String {
        if (cardExpiryDate.count == 3) {
            return String(cardExpiryDate.suffix(1))
        } else if (cardExpiryDate.count == 4) {
            return String(cardExpiryDate.suffix(2))
        } else {
            return ""
        }
    }
}
