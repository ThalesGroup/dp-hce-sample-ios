//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Radio button view group.
 */
struct RadioButtonGroupView: View {
    let items : [String]

    @State var selectedId: String = ""

    let callback: (String) -> ()

    var body: some View {
        VStack {
            ForEach(0..<items.count, id:\.self) { index in
                RadioButtonView(self.items[index], callback: self.radioGroupCallback, selectedID: self.selectedId)
            }
        }
    }

    func radioGroupCallback(id: String) {
        selectedId = id
        callback(id)
    }
}

