//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

struct Transaction: Identifiable {
    var id: Int
    
    let title: String
    let time: Date
    let amount: String
    let currency: String
    let description: String
}
