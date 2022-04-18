/*
 MIT License
 
 Copyright (c) 2021 Thales DIS
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

import Foundation
import SwiftUI

/**
 ViewModel to retrive the card list and notify the UI.
 */
class CardListViewModel: BaseViewModel {

    @Published var cardList:[Card] = [Card]()
    
    //MARK: public API

    /**
     Retrieves the card list.
     */
    public func getCardList() {
        var cardListLocal: [Card] = [Card]()

        let cardListHelper: CardListHelper = SdkHelper.shared().cardListHelper
        cardListHelper.getAllCards { (digitalizedCardList: [DigitalizedCard]?, error: Error?)  in
            if let error = error {
                self.notifyError(error: error)
                return
            }

            if let digitalizedCardList = digitalizedCardList {
                self.cardList = [Card]()
                for digitalizedCard in digitalizedCardList {
                    digitalizedCard.getDetails { (cardDetails: DigitalizedCardDetails?, error: Error?) in
                        if let error = error {
                            self.notifyError(error: error)
                            return
                        }
                        self.checkReplenishmentDigitilizedCard(digitalizedCard)
                        
                        digitalizedCard.isDefaultCard { (isDefaultCard: Bool, error: Error?) in
                            if let error = error {
                                self.notifyError(error: error)
                                return
                            }
                            var stateError: NSError?
                            let cardState = digitalizedCard.getDigitalCardState(&stateError)
                            let suspendState = self.isCardSuspended(cardState)
                            cardListHelper.pendingCardActivation(tokenizedCardId: digitalizedCard.tokenizedCardId) { (result: PendingCardActivation?, error: Error?) in
                                let pendingCardActivation = result
                                var resume = false
                                if (suspendState && pendingCardActivation == nil) {
                                    resume = true
                                }
                                var isQrPaymentTypeSupported: Bool = false
                                if (cardDetails != nil) {
                                    isQrPaymentTypeSupported = cardDetails!.isPaymentTypeSupported(.QR)
                                }
                                if let backgroundImage = DataPersistance.getBackgroundImage(tokenizedCardId: digitalizedCard.tokenizedCardId) {
                                    let card: Card = Card(id: digitalizedCard.tokenizedCardId, pan:cardDetails?.lastFourDigits ?? "", defaultPayment: isDefaultCard, suspend: suspendState, resume: resume, qrPaymentTypeSupported:isQrPaymentTypeSupported, state: cardState, panExpiry: cardDetails?.panExpiry ?? DataPersistance.getPanExpiration(panSuffix: cardDetails?.lastFourDigits ?? ""), backgroundImage: backgroundImage, pendingCardActivation: pendingCardActivation)
                                    DispatchQueue.main.async {
                                        cardListLocal.append(card)
                                        self.cardList = cardListLocal
                                    }
                                } else {
                                    SdkHelper.shared().cardArtHelper.getCardBackground(tokenizedCardId: digitalizedCard.tokenizedCardId, completion: { (cardBitmap, error) -> Void in
                                        var backgroundImage: Data?
                                        if (cardBitmap != nil) {
                                            backgroundImage = cardBitmap!.getResource()
                                            DataPersistance.saveBackgroundImage(backgroundImage!, tokenizedCardId: digitalizedCard.tokenizedCardId)
                                        }
                                        let card: Card = Card(id: digitalizedCard.tokenizedCardId, pan:cardDetails?.lastFourDigits ?? "", defaultPayment: isDefaultCard, suspend: suspendState, resume: resume, qrPaymentTypeSupported:isQrPaymentTypeSupported, state: cardState, panExpiry: cardDetails?.panExpiry ?? DataPersistance.getPanExpiration(panSuffix: cardDetails?.lastFourDigits ?? ""), backgroundImage: backgroundImage, pendingCardActivation: pendingCardActivation)
                                        DispatchQueue.main.async {
                                            cardListLocal.append(card)
                                            self.cardList = cardListLocal
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     Retrieves information about card state.
     
     @param cardState Digitalized Card State.
     */
    public func getDigitalizedCardState(_ cardState: DigitalizedCardState) -> String {
        switch(cardState) {
            case DigitalizedCardState.DIGITALIZED_CARD_STATE_ACTIVE:
                return Bundle.main.localizedString(forKey:"digitalized_card_state_active", value:nil, table: nil)
            case DigitalizedCardState.DIGITALIZED_CARD_STATE_SUSPENDED:
                return Bundle.main.localizedString(forKey:"digitalized_card_state_suspended", value:nil, table: nil)
            case DigitalizedCardState.DIGITALIZED_CARD_STATE_RETIRED:
                return Bundle.main.localizedString(forKey:"digitalized_card_state_retired", value:nil, table: nil)
            case DigitalizedCardState.DIGITALIZED_CARD_STATE_UNKNOWN:
                return Bundle.main.localizedString(forKey:"digitalized_card_state_unkown", value:nil, table: nil)
            default:
                return Bundle.main.localizedString(forKey:"digitalized_card_state_unkown", value:nil, table: nil)
        }
    }
    
    /**
     Deletes the card.
     
     @param tokenizedCardId Card ID.
     */
    public func deleteCard(tokenizedCardId: String) {
        SdkHelper.shared().cardListHelper.deleteCard(tokenizedCardId: tokenizedCardId) { (isSuccess: Bool, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self.notifyError(error: error)
                }
            }
        }
    }
    
    /**
     Suspends the card.
     
     @param tokenizedCardId Card ID.
     */
    public func suspendCard(tokenizedCardId: String) {
        SdkHelper.shared().cardListHelper.suspendCard(tokenizedCardId: tokenizedCardId) { (isSuccess: Bool, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self.notifyError(error: error)
                }
            }
        }
    }
    
    /**
     Resumes the card.
     
     @param tokenizedCardId Card ID.
     */
    public func resumeCard(tokenizedCardId: String) {
        SdkHelper.shared().cardListHelper.resumeCard(tokenizedCardId: tokenizedCardId) { (isSuccess: Bool, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self.notifyError(error: error)
                }
            }
        }
    }
    
    /**
     Defaults card.
     
     @param tokenizedCardId Card ID.
     */
    public func setDefultCard(tokenizedCardId: String) {
        if let digitalizedCard: DigitalizedCard = SdkHelper.shared().cardListHelper.getDigitalizedCard(tokenizedCardId) {
            digitalizedCard.setDefault { (isSuccess: Bool, error: Error?)  in
                DispatchQueue.main.async {
                    if let error = error {
                        self.notifyError(error: error)
                    } else {
                        for (index, var card) in self.cardList.enumerated() {
                            if (card.id == tokenizedCardId) {
                                card.defaultPayment = true
                                self.cardList[index] = card
                            }
                        }
                    }
                }
            }
        }
    }

    
    //MARK: private API
    
    private func checkReplenishmentDigitilizedCard(_ digitalizedCard: DigitalizedCard) {
        digitalizedCard.getStatus { digitalizedCardStatus, error in
            if (digitalizedCardStatus != nil) {
                SdkHelper.shared().paymentHelper.replenishKeys(digitalizedCard.tokenizedCardId, digitalizedCardStatus!)
            }
        }
    }

    private func isCardSuspended(_ cardState: DigitalizedCardState) -> Bool {
        if (cardState == DigitalizedCardState.DIGITALIZED_CARD_STATE_SUSPENDED) {
            return true
        }
        return false
    }

}
