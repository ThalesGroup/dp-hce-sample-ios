//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

public typealias TransactionHistoryCompletionBlock = (_ result: [MGTransactionRecord]?, _ error: Error?) -> Void

/**
 Helper class to retrieve the transaction history for a specific card.
 */
public class TransactionHistoryHelper {
    private var transactionHistoryCompletionBlock: TransactionHistoryCompletionBlock?
    
    //MARK: public API
    
    /**
     Retrieves the transaction history.
     
     @param tokenizedCardId Tokenized card ID reprezenting a specific card.
     @param completionBlock Callback.
     */
    public func getTransactionHistory(tokenizedCardId: String, completionBlock: @escaping TransactionHistoryCompletionBlock) {
        self.transactionHistoryCompletionBlock = completionBlock
        
        guard let provisioningBusinessService: ProvisioningBusinessService = ProvisioningServiceManager.sharedInstance().getProvisioningBusinessService() else {
            self.transactionHistoryCompletionBlock?(nil, NSError.make(localizedMessage: "Cannot retrieve ProvisioningBusinessService"))
            return
        }
        
        DigitalizedCardManager.sharedInstance().getDigitalizedCardId(tokenizedCardId) { (tokenizedCardId: String?, error: Error?) in
            if let error = error {
                self.transactionHistoryCompletionBlock?(nil, error)
                return
            }
            
            if let tokenizedCardId = tokenizedCardId {
                do {
                    try provisioningBusinessService.getAccessToken(tokenizedCardId, mode: .REFRESH, delegate: self)
                } catch {
                    self.transactionHistoryCompletionBlock?(nil, error)
                }
            } else {
                self.transactionHistoryCompletionBlock?(nil, NSError.make(localizedMessage: "Cannot retrieve digitalized card id"))
            }
        }
    }
}

//MARK: AccessTokenDelegate API

extension TransactionHistoryHelper: AccessTokenDelegate {
    
    public func onSuccess(_ businessService: BusinessService, digitalCardId: String, accessToken: String?) {
        guard let transactionHistoryService: MGTransactionHistoryService = MobileGatewayManager.sharedInstance().getTransactionHistoryService(), let accessToken = accessToken else {
            self.transactionHistoryCompletionBlock?(nil, NSError.make(localizedMessage: "Cannot retrieve MGTransactionHistoryService"))
            return
        }
        
        transactionHistoryService.refreshHistory(accessToken, digitalCardId: digitalCardId, timeStamp: "") { (transactions: [Any]?, digitalCardId: String, timestamp: String?, error: MobileGatewayError?) in
            
            if let error = error {
                self.transactionHistoryCompletionBlock?(nil, NSError.make(localizedMessage: error.description))
            } else {
                self.transactionHistoryCompletionBlock?(transactions as? [MGTransactionRecord] ?? nil, nil)
            }
        }
    }
    
    public func onError(_ businessService: BusinessService, digitalCardId: String, error: ProvisioningServiceError?) {
        self.transactionHistoryCompletionBlock?(nil, NSError.make(localizedMessage: error?.errorMessage ?? "unknown error"))
    }
}
