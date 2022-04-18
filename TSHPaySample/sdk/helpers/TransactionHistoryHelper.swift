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
