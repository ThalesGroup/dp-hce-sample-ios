//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import SwiftUI
import TSHPaySDK

/**
 ViewModel to retrive the card list and notify the UI.
 */
class CardListModel: ObservableObject {

    // MARK: - Defines
    
    @Published var cardList:[CardFrontModel]

    // MARK: - Lifecycle
    
    init() {
        cardList = []
    }
    
    init(_ cardList: [CardFrontModel]) {
        self.cardList = cardList
    }

    @MainActor public func realoadCardList() async {
        // Preview do not want to reload cards.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        
        Task {
            // Remove cards that are no longer part of the list.
            let newCardList = try await DigitalCardManager().cardList
            cardList.removeAll { oldCard in
                return !newCardList.contains { newCard in
                    return newCard.digitalCardID == oldCard.digitalCardID
                }
            }
            
            // Add or reload the list of cards and check for replenishment.
            for loopNewCard in newCardList {
                if let foundCard = cardList.first(where: { $0.digitalCardID == loopNewCard.digitalCardID }) {
                    await foundCard.reloadCarddata(loopNewCard)
                } else {
                    await self.cardList.append(CardFrontModel(loopNewCard))
                }
                
                // Check for replenishment.
                await AppModel.triggerReplenishmentIfNeeded(digitalCard: loopNewCard)
            }
        }
    }
    
}
