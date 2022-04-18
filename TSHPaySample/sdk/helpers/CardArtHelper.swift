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

public typealias CardArtCompletionBlock = (_ result: CardBitmap?, _ error: Error?) -> Void

/**
 Helper class to retrieve the card art (bank logo, scheme logo, card background etc.) of the provisioned card.
 */
public class CardArtHelper {
    
    //MARK: public API
    
    /**
     Retrieves the bank logo.
     
     @param tokenizedCardId: Tokenized card ID
     @param completion Callback handler.
     */
    public func getBankLogo(tokenizedCardId: String, completion: @escaping CardArtCompletionBlock) {
        getCardArt(tokenizedCardId: tokenizedCardId, type: .BANK_LOGO, completion: completion)
    }
    
    /**
     Retrieves the card background.
     
     @param tokenizedCardId: Tokenized card ID
     @param completion Callback handler.
     */
    public func getCardBackground(tokenizedCardId: String, completion: @escaping CardArtCompletionBlock) {
        getCardArt(tokenizedCardId: tokenizedCardId, type: .CARD_BACKGROUND, completion: completion)
    }
    
    /**
     Retrieves the combined card background.
     
     @param tokenizedCardId: Tokenized card ID
     @param completion Callback handler.
     */
    public func getCardBackgroundCombined(tokenizedCardId: String, completion: @escaping CardArtCompletionBlock) {
        getCardArt(tokenizedCardId: tokenizedCardId, type: .CARD_BACKGROUND_COMBINED, completion: completion)
    }
    
    /**
     Retrieves the CO brand logo.
     
     @param tokenizedCardId: Tokenized card ID
     @param completion Callback handler.
     */
    public func getCoBrandLogo(tokenizedCardId: String, completion: @escaping CardArtCompletionBlock) {
        getCardArt(tokenizedCardId: tokenizedCardId, type: .CO_BRAND_LOGO, completion: completion)
    }
    
    /**
     Retrieves the card icon.
     
     @param tokenizedCardId: Tokenized card ID
     @param completion Callback handler.
     */
    public func getCardIcon(tokenizedCardId: String, completion: @escaping CardArtCompletionBlock) {
        getCardArt(tokenizedCardId: tokenizedCardId, type: .CARD_ICON, completion: completion)
    }
    
    //MARK: private API

    private func getCardArt(tokenizedCardId: String, type: CardArtType, completion: @escaping CardArtCompletionBlock) {
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (tokenizedCardId: String?, error: Error?) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let tokenizedCardId = tokenizedCardId {
                do {
                    try MobileGatewayManager.sharedInstance().getCardArt(tokenizedCardId).getBitmap(type) { (result: MGAsyncResult?) in
                        if let result = result, result.isSuccessful() {
                            if let cardBitmap = result.getResult() {
                                completion(cardBitmap, nil)
                            }
                        } else {
                            completion(nil, NSError.make(localizedMessage: "Cannot retrieve card art"))
                        }
                    }
                } catch {
                    completion(nil, error)
                }
            }
        }
    }
}
