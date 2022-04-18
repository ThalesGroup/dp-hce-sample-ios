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

import SwiftUI

/**
 View to display the transaction history.
 */
struct CardTransactionHistoryView: View {
    @StateObject var cardTransactionHistoryViewModel:CardTransactionHistoryViewModel = CardTransactionHistoryViewModel()
    @State var tokenizedCardId: String
    
    var body: some View {
        List (cardTransactionHistoryViewModel.transactionHistory) { transaction in
            HStack {
                Image(systemName: "cart")
                VStack(alignment: .leading) {                    Text(transaction.title).font(.headline)
                    Text("\(transaction.description)").font(.caption)
                    Text("\(transaction.time)").font(.caption)
                }
                Text("\(transaction.amount)\(transaction.currency)").padding(.trailing, 0)
            }
        }.onAppear {
            self.cardTransactionHistoryViewModel.getTransactionHistory(tokenizedCardId: self.tokenizedCardId)
        }
    }
}

struct CardTransactionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        CardTransactionHistoryView(tokenizedCardId: "1111")
    }
}
