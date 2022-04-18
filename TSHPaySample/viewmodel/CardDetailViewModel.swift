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
 ViewModel to retrive the card details and notify the UI.
 */
class CardDetailViewModel: BaseViewModel {
    @Published var cardDetail:CardDetail = CardDetail(pan: "", name: "", cardExpiryDateMonth: "", cardExpiryDateYear: "", cvv: "", backgroundColors: [Color(#colorLiteral(red: 0.927985847, green: 0.685954392, blue: 0.6621723175, alpha: 1)), Color.red], cardState: .DIGITALIZED_CARD_STATE_ACTIVE)
    @Published var isDefaultCard: Bool = false
    @Published var isQrPaymentTypeSupported: Bool = false
    @Published var deletedTokenizedCardId: String?
    @Published var suspendedCard: Bool = false
    
    /**
     Retrieves the card details.
     
     @param tokenizedCardId Card ID.
     */
    public func getCardDetail(tokenizedCardId: String) {
        if let digitalizedCard: DigitalizedCard = SdkHelper.shared().cardListHelper.getDigitalizedCard(tokenizedCardId) {
            digitalizedCard.getDetails { (cardDetails: DigitalizedCardDetails?, error: Error?) in
                if let error = error {
                    self.notifyError(error: error)
                } else if let cardDetails = cardDetails {
                    let cardState: DigitalizedCardState = digitalizedCard.getDigitalCardState(nil)
                    self.cardDetail = CardDetail(pan: cardDetails.lastFourDigits ?? "",
                                                 name: DataPersistance.getCardHolder(panSuffix: cardDetails.lastFourDigits ?? ""),
                                                 cardExpiryDateMonth: cardDetails.panExpiry ?? "",
                                                 cardExpiryDateYear: cardDetails.panExpiry ?? "",
                                                 cvv: "",
                                                 backgroundColors: [Color(#colorLiteral(red: 0.3306755424, green: 0.7205328345, blue: 0.9244166613, alpha: 1)), Color.blue],
                                                 cardState: cardState)
                    digitalizedCard.isDefaultCard({ (isDefault: Bool, error: Error?) in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.notifyError(error: error)
                            } else {
                                self.isDefaultCard = isDefault
                                self.isQrPaymentTypeSupported = cardDetails.isPaymentTypeSupported(.QR)
                            }
                        }
                    })
                }
            }
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
                } else if (isSuccess){
                        self.deletedTokenizedCardId = tokenizedCardId
                }
            }
        }
    }
    
    /**
     Suspends the card.
     
     @param tokenizedCardId Card ID.
     */
    public func suspendCard(tokenizedCardId: String) {
//        setDefultCard(tokenizedCardId: tokenizedCardId)
        SdkHelper.shared().cardListHelper.suspendCard(tokenizedCardId: tokenizedCardId) { (isSuccess: Bool, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self.notifyError(error: error)
                } else {
                    self.suspendedCard = isSuccess
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
                } else {
                    self.suspendedCard = false
                }
            }
        }
    }
    
    /**
     Sets the card as default.
     
     @param tokenizedCardId Card ID.
     */
    public func setDefultCard(tokenizedCardId: String) {
        if let digitalizedCard: DigitalizedCard = SdkHelper.shared().cardListHelper.getDigitalizedCard(tokenizedCardId) {
            digitalizedCard.setDefault { (isSuccess: Bool, error: Error?)  in
                DispatchQueue.main.async {
                    if let error = error {
                        self.notifyError(error: error)
                    } else {
                        self.isDefaultCard = isSuccess
                    }
                }
            }
        }
    }
    
    /**
     Unsets the default card.
     */
    public func unsetDefultCard() {
        DigitalizedCardManager.sharedInstance().unsetDefaultCard { (isSuccess: Bool, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self.notifyError(error: error)
                } else if isSuccess {
                    self.isDefaultCard = false
                }
            }
        }
    }
}
