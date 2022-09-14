//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

/**
 ViewModel to retrive the transaction history and notify the UI.
 */
class CardTransactionHistoryViewModel: BaseViewModel {
    @Published var transactionHistory:[Transaction] = []
    
    //MARK: public API
    /**
     Retrieves the transaction history.
     
     @param tokenizedCardId Card ID.
     */
    public func getTransactionHistory(tokenizedCardId: String) {
        SdkHelper.shared().transactionHistoryHelper.getTransactionHistory(tokenizedCardId: tokenizedCardId) { (transactions: [MGTransactionRecord]?, error: Error?) in
            if let error = error {
                self.notifyError(error: error)
            } else if let transactions = transactions {
                var localTransactionHistory: [Transaction] = []
                var id: Int = 0
                for transaction in transactions {
                    var date: Date = Date()
                    if let dateString = transaction.getTransactionDate() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                        dateFormatter.dateFormat = "YYYY-MM-DDThh:mm:ssTZD"
                        date = dateFormatter.date(from:dateString)!
                    }

                    localTransactionHistory.append(Transaction(id: id,
                                                               title: transaction.getMerchantName() ?? "undef",
                                                               time: date,
                                                               amount: String(transaction.getAmount()),
                                                               currency: transaction.getCurrencyCode() ?? "undef",
                                                               description: transaction.getMerchantName() ?? "undef"))

                    id += 1
                }

                self.transactionHistory = localTransactionHistory
            }
        }
    }
}
