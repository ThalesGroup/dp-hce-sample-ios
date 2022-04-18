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
 Card list screen.
 */
struct CardListView: View {
    
    @EnvironmentObject var viewRouter: ViewRouter
    
    @StateObject var cardListViewModel:CardListViewModel = CardListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if cardListViewModel.cardList.count != 0 {
                    List (cardListViewModel.cardList) { card in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(card.holderName).font(.headline)
                                Spacer()
                                HStack {
                                    Label("\(card.pan)", systemImage: "creditcard")
                                }
                                .font(.caption)
                            }
                            Spacer()
                            if card.defaultPayment {
                                Image(systemName: "checkmark.circle").padding(10)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.viewRouter.tokenizedCardId = card.tokenizedCardId
                            self.viewRouter.currentPage = .cardDetail
                        }
                    }
                    .navigationBarTitle(Text(LocalizedStringKey("title_cardlist")))
                    .navigationBarBackButtonHidden(false)
                    .toolbar {
                        ToolbarItem (placement: .navigationBarTrailing) {
                            Button(LocalizedStringKey("button_add_card")) {
                                self.viewRouter.currentPage = .enrollment
                            }
                        }
                    }
                } else {
                    HStack {
                        Text(LocalizedStringKey("title_cardlist_empty_cards")).multilineTextAlignment(.center)
                        
                    }
                    .navigationBarTitle(Text(LocalizedStringKey("title_cardlist")))
                    .toolbar {
                        ToolbarItem (placement: .navigationBarTrailing) {
                            Button(LocalizedStringKey("button_enroll_card")) {
                                self.viewRouter.currentPage = .enrollment
                            }
                        }
                    }
                }
                
                if self.cardListViewModel.isNotifcationVisible && self.cardListViewModel.notificationData != nil {
                    EmptyView()
                        .banner(data: $cardListViewModel.notificationData, show: self.$cardListViewModel.isNotifcationVisible)
                }
            }.onAppear {
                self.cardListViewModel.getCardList()
            }.onChange(of: self.viewRouter.tokenizedCardId) { newValue in
                self.cardListViewModel.getCardList()
            }
        }
    }
}

struct CardListView_Previews: PreviewProvider {
    static var previews: some View {
        CardListView()
    }
}
