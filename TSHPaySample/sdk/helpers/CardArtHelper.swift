//
// Copyright © 2021-2022 THALES. All rights reserved.
//

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
