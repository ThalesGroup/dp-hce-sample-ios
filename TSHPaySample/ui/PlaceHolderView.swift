//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

struct TappableTextFieldStyle: TextFieldStyle {
    @FocusState private var textFieldFocused: Bool
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .focused($textFieldFocused)
            .onTapGesture {
                textFieldFocused = true
            }
    }
}

/**
 Place holder view.
 */
struct PlaceHolderView: View {
    
    var placeholder: Text
    @Binding var text: String
    var editingChanged: (Bool)->() = { _ in }
    var commit: ()->() = { }
    var alignment: Alignment

    var body: some View {
        ZStack(alignment: alignment) {
            if text.isEmpty { placeholder }
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
                .autocapitalization(UITextAutocapitalizationType.words)
                .textFieldStyle(TappableTextFieldStyle())
        }
    }
}
