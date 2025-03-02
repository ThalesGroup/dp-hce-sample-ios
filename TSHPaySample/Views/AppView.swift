//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import SwiftUI

struct AppView: View {
    @EnvironmentObject private var appDelegate: AppDelegate

    var body: some View {
        
        NavigationStack(path: $appDelegate.navPath) {
            CardListView(cardListModel: CardListModel(), paymentModel: PaymentModel())
                .navigationDestination(for: AppDelegate.Destination.self) { destination in
                    switch destination {
                    case .addCard:
                        AddCardView(cardFront: CardFrontModel(pan: serverEnvironment.sampleCardPan, exp: serverEnvironment.sampleCardExp, cvv: serverEnvironment.sampleCardCvv))
                    }
                }
        }
        
        // Add common elements for toast and progressbar
        notificationViewModifier(data: $appDelegate.toastData)
    }
}

