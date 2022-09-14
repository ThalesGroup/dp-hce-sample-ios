//
// Copyright © 2021-2022 THALES. All rights reserved.
// 

import Foundation

public typealias DeleteCardCompletionBlock = (_ isSuccess: Bool, _ error: Error?) -> Void
public typealias SuspendCardCompletionBlock = (_ isSuccess: Bool, _ error: Error?) -> Void
public typealias ResumeCardCompletionBlock = (_ isSuccess: Bool, _ error: Error?) -> Void
public typealias PendingCardActivationCompletionBlock = (_ result: PendingCardActivation?, _ error: Error?) -> Void

/**
 Helper class for card related operations.
 */
public class CardListHelper {
    
    //MARK: public API
    
    /**
     Retrieves the list of available cards.
     
     @param completion Callback handler.
     */
    public func getAllCards(completion: @escaping ([DigitalizedCard]?, Error?) -> ()) {
        DigitalizedCardManager.sharedInstance().getAllCards ({ (cardList: [String]?, error: Error?) in
            if let cards = cardList {
                completion(self.getDigitalCardForTokenIds(cards), nil)
            } else {
                AppLoggerHelper.log(.error, "\(CardListHelper.typeName) getAllCards", Bundle.main.localizedString(forKey:"cards_error", value:nil, table: nil))
                completion(nil, error)
            }
        })
    }
    
    /**
     Retrieves the list of available cards. Application password verification (Wallet PIN)
     
     @param completion Callback handler.
     */
    public func getAllCardsPasswordVerification(completion: @escaping ([DigitalizedCard]?, Error?) -> ()) {
        setAppCode { (appCode: Bool, error: Error?)  in
            if appCode {
                DigitalizedCardManager.sharedInstance().getAllCards ({ (cardList: [String]?, error: Error?) in
                    if let cards = cardList {
                        completion(self.getDigitalCardForTokenIds(cards), nil)
                    } else {
                        AppLoggerHelper.log(.error, "\(CardListHelper.typeName) getAllCards", Bundle.main.localizedString(forKey:"cards_error", value:nil, table: nil))
                        completion(nil, error)
                    }
                })
            }
        }
    }
    
    /**
     Retrieves the list of cards coresponding the the provided token id list.
     
     @param cardList List of token ids.
     
     @return completion List of cards.
     */
    public func getDigitalCardForTokenIds(_ cardList: [String]) -> [DigitalizedCard]? {
        var digitalCardList:[DigitalizedCard]? = [DigitalizedCard]()
        for tokenId in cardList {
            let digitalCard = getDigitalizedCard(tokenId)
            digitalCardList?.append(digitalCard!)
        }
        
        return digitalCardList
    }
    
    /**
     Retrieves the card for the specific token id.
     
     @param tokenId Token id.
     
     @return completion Card.
     */
    public func getDigitalizedCard(_ tokenId: String) -> DigitalizedCard? {
        if let digitalCard = DigitalizedCardManager.sharedInstance().getDigitalizedCard(tokenId) {
            return digitalCard
        }
        return nil
    }
    
    /**
     Deletes a card.
     
     @param tokenizedCardId Token id.
     @param completion Callback handler.
     */
    public func deleteCard(tokenizedCardId: String, completion: @escaping DeleteCardCompletionBlock) {
        guard let cardLifeCycleManager: MGCardLifeCycleManager = MobileGatewayManager.sharedInstance().getCardLifeCycle() else {
            completion(false, NSError.make(localizedMessage: "Cannot retrieve MGCardLifeCycleManager"))
            return
        }
        
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (tokenizedCardId: String?, error: Error?) in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let tokenizedCardId = tokenizedCardId {
                cardLifeCycleManager.deleteCard(tokenizedCardId) { (cardId: String?, mobileGatewayError: MobileGatewayError?, error: Error?) in
                    if (error == nil && mobileGatewayError == nil) {
                        completion(true, nil)
                    } else {
                        if let error = error {
                            completion(false, error)
                        } else if let mobileGatewayError = mobileGatewayError {
                            completion(false, NSError.make(localizedMessage: mobileGatewayError.getMessage() ?? "undef error"))
                        }
                    }
                }
            }
        }
    }
    
    /**
     Suspends a card.
     
     @param tokenizedCardId Token id.
     @param completion Callback handler.
     */
    public func suspendCard(tokenizedCardId: String, completion: @escaping SuspendCardCompletionBlock) {
        guard let cardLifeCycleManager: MGCardLifeCycleManager = MobileGatewayManager.sharedInstance().getCardLifeCycle() else {
            completion(false, NSError.make(localizedMessage: "Cannot retrieve MGCardLifeCycleManager"))
            return
        }
        
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (tokenizedCardId: String?, error: Error?) in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let tokenizedCardId = tokenizedCardId {
                cardLifeCycleManager.suspendCard(tokenizedCardId) { (cardId: String?, mobileGatewayError: MobileGatewayError?, error: Error?) in
                    if (error == nil && mobileGatewayError == nil) {
                        completion(true, nil)
                    } else {
                        if let error = error {
                            completion(false, error)
                        } else if let mobileGatewayError = mobileGatewayError {
                            completion(false, NSError.make(localizedMessage: mobileGatewayError.getMessage() ?? "undef error"))
                        }
                    }
                }
            }
        }
    }
    
    /**
     Resumes a card.
     
     @param tokenizedCardId Token id.
     @param completion Callback handler.
     */
    public func resumeCard(tokenizedCardId: String, completion: @escaping ResumeCardCompletionBlock) {
        guard let cardLifeCycleManager: MGCardLifeCycleManager = MobileGatewayManager.sharedInstance().getCardLifeCycle() else {
            completion(false, NSError.make(localizedMessage: "Cannot retrieve MGCardLifeCycleManager"))
            return
        }
        
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (tokenizedCardId: String?, error: Error?) in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let tokenizedCardId = tokenizedCardId {
                cardLifeCycleManager.resumeCard(tokenizedCardId) { (cardId: String?, mobileGatewayError: MobileGatewayError?, error: Error?) in
                    if (error == nil && mobileGatewayError == nil) {
                        completion(true, nil)
                    } else {
                        if let error = error {
                            completion(false, error)
                        } else if let mobileGatewayError = mobileGatewayError {
                            completion(false, NSError.make(localizedMessage: mobileGatewayError.getMessage() ?? "undef error"))
                        }
                    }
                }
            }
        }
    }
    
    /**
     Retrieves pending state for card
     
     @param tokenizedCardId Token id.
     */
    public func pendingCardActivation(tokenizedCardId: String, completion: @escaping PendingCardActivationCompletionBlock) {
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (digitalCardId: String?, error: Error?) in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(MobileGatewayManager.sharedInstance().getCardEnrollmentService()?.getPendingCardActivation(digitalCardId!), nil)
            return
       }
    }
    
    //MARK: private API

    /**
     
     Set App Code before calling on getAllCard
     */
    private func setAppCode(completion: @escaping (Bool, Error?) -> ()) {
        let appCodeStatus:AppCodeStatus = DeviceCVMManager.sharedInstance().appCodeStatus()
        ///notExisting: the app code is not set
        if (appCodeStatus == .notExisting) {
            do {
              try DeviceCVMManager.sharedInstance().setAppCode { (publicKeyRef : SecKey) -> Unmanaged<CFData>? in
                //retrieve appCode in CFData format
                  let appCode : CFData = SdkHelper.getAppCode()
                if let encryptedData = SecKeyCreateEncryptedData(publicKeyRef, SecKeyAlgorithm.rsaEncryptionOAEPSHA256, appCode, nil) {
                    completion(true, nil)
                    return Unmanaged.passRetained(encryptedData)
                } else {
                    completion(true, nil)
                    return nil
                }
              }
            } catch {
                AppLoggerHelper.log(.error, "\(CardListHelper.typeName) setAppCode", Bundle.main.localizedString(forKey:"app_code", value:nil, table: nil))
                completion(false, error)
            }
        }
        completion(true, nil)
    }

    private static var typeName: String {
        return String(describing: self)
    }
}
