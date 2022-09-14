//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation
import SwiftUI

public extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
