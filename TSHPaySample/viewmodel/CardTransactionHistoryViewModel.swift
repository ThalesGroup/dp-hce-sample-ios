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
