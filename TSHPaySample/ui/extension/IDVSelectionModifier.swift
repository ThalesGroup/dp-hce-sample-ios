//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

struct IDVSelectionModifier: ViewModifier {
    
    let listIdvMethod: [String]
    
    func body(content: Content) -> some View {
        Group {
            if listIdvMethod.isEmpty {
                Text(LocalizedStringKey("error_idv_selction"))
            } else {
                content
            }
        }
    }
}
