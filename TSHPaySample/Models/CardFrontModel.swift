//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import TSHPaySDK
import UIKit

private let EMPTY_VALUE = "--"

class FormatedString: ObservableObject {
    private let formater: (String?) -> String
    private let validator: (String?) -> Bool
    
    @Published var valueIsValid: Bool = false
    @Published var valueFormated: String = EMPTY_VALUE
    @Published var value: String { didSet {
        valueFormated = formater(value)
        valueIsValid = validator(value)
    }}
    
    init(formater: @escaping (String?) -> String,
         validator: @escaping (String?) -> Bool) {
        self.value = EMPTY_VALUE
        self.validator = validator
        self.formater = formater
        
        // Init does not trigger didSet. It needs to be dome manualy.
        self.valueIsValid = validator(value)
        self.valueFormated = formater(value)
    }
}

class CardFrontModel: ToastHelper, ObservableObject {

    // MARK: - Defines
    
    public enum CardType {
        case manualEntry, data
    }
    
    @Published var digitalCardID: String
    
    @Published var type: CardType
    
    @Published var cardPan = FormatedString { value in
        if let value = value {
            return String(value.enumerated().map { $0 > 0 && $0 % 4 == 0 ? [" ", $1] : [$1]}.joined())
        } else {
            return EMPTY_VALUE
        }
    } validator: { value in
        return value?.count ?? 0 > 0
    }
    
    @Published var cardExp = FormatedString { value in
        if var value = value {
            if value.count == 3 || value.count == 4 {
                value.insert(contentsOf: " / ", at: value.index(value.startIndex, offsetBy: value.count - 2))
                return value
            } else {
                return EMPTY_VALUE
            }
        } else {
            return EMPTY_VALUE
        }
    } validator: { value in
        let count = value?.count ?? 0
        return count == 3 || count == 4
    }

    @Published var cardCvv = FormatedString { value in
        return value ?? EMPTY_VALUE
    } validator: { value in
        return value?.count ?? 0 > 0
    }
    
    @Published var cardState: DigitalCard.State
    @Published var needsReplenishment: Bool
    @Published var isDefaultCard: Bool
    @Published var cardBackground: UIImage?
    
       
    // MARK: - Lifecycle

    init(_ card: DigitalCard) async {
        type = .data
        self.digitalCardID = card.digitalCardID
        self.cardState = DigitalCard.State.unknown
        self.needsReplenishment = false
        self.isDefaultCard = false
        super.init()
                
        // Load card metadata.. it might require backend call so it's asynchronous.
        do {
            let metaData = try await card.cardMetaData
            self.cardState = try await card.state
            self.needsReplenishment = try await card.paymentKeyInfo.needsReplenishment
            self.isDefaultCard = try await card.isDefaultCard
            if let last4 = metaData.panLastDigits  {
                self.cardPan.value = "************\(last4)"
            } else {
                self.cardPan.value = "--"
            }
            self.cardExp.value = metaData.panExpiry ?? "--"
            self.cardCvv.value = "***"
        } catch {
            //TODO: HANDLE ERROR
        }
        
        // Load card background image either from cache or from the scheme.
        Task.detached() {
            let cardArt = try await card.cardArt
            if let bitmap = try await cardArt.bitmap(forArtType: .cardBackground).resource() {
                await MainActor.run {
                    self.cardBackground = UIImage(data: bitmap)
                }
            }
        }
    }
    
    init(pan: String, exp: String, cvv: String, needsReplenishment: Bool, isDefaultCard: Bool) {
        type = .manualEntry
        self.cardState = DigitalCard.State.unknown
        self.needsReplenishment = needsReplenishment
        self.isDefaultCard = isDefaultCard
        self.digitalCardID = ""
        super.init()

        cardPan.value = pan
        cardExp.value = exp
        cardCvv.value = cvv
    }
    
    init(pan: String, exp: String, cvv: String) {
        type = .manualEntry
        self.cardState = DigitalCard.State.unknown
        self.needsReplenishment = false
        self.isDefaultCard = false
        self.digitalCardID = ""
        super.init()
        
        cardPan.value = pan
        cardExp.value = exp
        cardCvv.value = cvv
    }
    
    // MARK: - TSHPay methods
    
    /**
     Request pull-mode request to replenish the card.
    */
    public func triggerReplenishment() {
        Task {
            do {
                let digitalCard = await DigitalCardManager().digitalCard(forID: self.digitalCardID)
                if try await digitalCard!.state == .active {
                    let replenishmentService = ReplenishmentService()
                    try await replenishmentService.replenish(digitalCardID: self.digitalCardID)
                    self.needsReplenishment = false
                }
            } catch let error {
                toastShow(caption: "Replenishment", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    /**
     Removes the current default payment card.
    */
    public func unsetDefaultCard() {
        Task {
            do {
                _ = try await DigitalCardManager().unsetDefaultCard()
                DispatchQueue.main.async {
                    self.isDefaultCard = false
                }
            } catch let error {
                toastShow(caption: "Un-set default card", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    /**
     Sets the DigitalCard as the default payment card.
     
     */
    public func setDefultCard() {
        Task {
            do {
                let digitalCard = await DigitalCardManager().digitalCard(forID: self.digitalCardID)
                guard (digitalCard != nil) else {
                    toastShow(caption: "Default card", description: "error during retrieving digital card", type: .error)
                    return
                }
                let isDefaultCard = try await digitalCard!.isDefaultCard
                if !isDefaultCard {
                    guard try await digitalCard!.setDefault() else {
                        toastShow(caption: "Default card", description: "isn't set default card", type: .error)
                        return
                    }
                    DispatchQueue.main.async {
                        self.isDefaultCard = true
                    }
                    return
                }
            } catch let error {
                toastShow(caption: "Default card", description: error.localizedDescription, type: .error)
            }
        }
    }
    
    /**
     Perform a management action on a specific DigitalCard.
     
     @param CardManagementAction The actions.
     */
    public func changeCardState(cardManagmentAction: DigitalCardManager.CardManagementAction) {
        Task {
            do {
                _ = try await DigitalCardManager().manage(digitalCardID: self.digitalCardID, action: cardManagmentAction)
                let cardState = try await DigitalCardManager().digitalCard(forID: self.digitalCardID)?.state
                DispatchQueue.main.async {
                    self.cardState =  cardState ?? DigitalCard.State.unknown
                }
            } catch {
                toastShow(caption: "change card state", description: error.localizedDescription, type: .error)
            }
        }
    }
}
