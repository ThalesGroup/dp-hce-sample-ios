//
// Copyright © 2021-2022 THALES. All rights reserved.
//  

import SwiftUI

/**
 Progress indicator view
 */
struct LoadingView: View {
    
    let title: LocalizedStringKey
    
    var body: some View {
        ZStack {
            ProgressView(title).progressViewStyle(CircularProgressViewStyle(tint: .blue))

        }.padding()
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(title:"Enrolling card")
    }
}
