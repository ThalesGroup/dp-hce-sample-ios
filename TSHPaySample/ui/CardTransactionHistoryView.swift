//
// Copyright © 2021-2022 THALES. All rights reserved.
//

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
