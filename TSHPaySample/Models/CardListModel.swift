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
            var retList: [CardFrontModel] = []
            for loopCard in try await DigitalCardManager().cardList {
                // Add card to UI
                await retList.append(CardFrontModel(loopCard))
                
                // Check for replenishment.
                await triggerReplenishmentIfNeeded(digitalCard: loopCard)
            }
            
            await MainActor.run {
                self.cardList = retList
            }
            
        }
    }
    
    public func triggerReplenishmentIfNeeded(digitalCard: DigitalCard) async {
        do {
            if try await digitalCard.state == .active {
                let replenishmentService = ReplenishmentService()
                try await replenishmentService.replenish(digitalCardID: digitalCard.digitalCardID)
            }
        } catch let error {
            // It is not super critical, we will try to replenish next time. Unless we have 0 keys, it should not be visible for the end user.
            AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Replenishment failed with error: \(error)")
        }
    }
}
