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
 Card detail screen.
 */
struct CardDetailView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    
    @StateObject var cardDetailViewModel:CardDetailViewModel = CardDetailViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    CardFrontView(cardDetail: self.cardDetailViewModel.cardDetail)
                    
                    if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                        CardTransactionHistoryView(tokenizedCardId: tokenizedCardId)
                    }
                }
                .navigationBarTitle(LocalizedStringKey("title_card_detail"), displayMode: .inline)
                .navigationBarBackButtonHidden(false)
                .toolbar {
                    ToolbarItem (placement: .navigationBarLeading) {
                        Button(LocalizedStringKey("button_close")) {
                            self.viewRouter.currentPage = .cardList
                        }
                    }
                    
                    ToolbarItem (placement: .navigationBarTrailing) {
                        Button(LocalizedStringKey("button_pay")) {
                            self.viewRouter.currentPage = .payment
                        }.disabled(!self.cardDetailViewModel.isQrPaymentTypeSupported)
                    }
                    
                    ToolbarItem (placement: .bottomBar) {
                        if (self.cardDetailViewModel.cardDetail.cardState == .DIGITALIZED_CARD_STATE_ACTIVE) {
                            Button(LocalizedStringKey("button_suspend")) {
                                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                                    self.cardDetailViewModel.suspendCard(tokenizedCardId: tokenizedCardId)
                                }
                            }
                        } else if (self.cardDetailViewModel.cardDetail.cardState == .DIGITALIZED_CARD_STATE_SUSPENDED) {
                            Button(LocalizedStringKey("button_resume")) {
                                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                                    self.cardDetailViewModel.resumeCard(tokenizedCardId: tokenizedCardId)
                                }
                            }
                        }
                    }
                    
                    ToolbarItem (placement: .bottomBar) {
                        if (self.cardDetailViewModel.isDefaultCard) {
                            Button(LocalizedStringKey("button_unset_default")) {
                                if self.viewRouter.tokenizedCardId != nil {
                                    self.cardDetailViewModel.unsetDefultCard()
                                }
                            }
                        } else {
                            Button(LocalizedStringKey("button_set_default")) {
                                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                                    self.cardDetailViewModel.setDefultCard(tokenizedCardId: tokenizedCardId)
                                }
                            }
                        }
                    }
                    
                    ToolbarItem (placement: .bottomBar) {
                        Button(LocalizedStringKey("button_delete")) {
                            if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                                self.cardDetailViewModel.deleteCard(tokenizedCardId: tokenizedCardId)
                            }
                        }
                    }
                }
                
                if self.cardDetailViewModel.isNotifcationVisible && self.cardDetailViewModel.notificationData != nil {
                    EmptyView()
                        .banner(data: $cardDetailViewModel.notificationData, show: self.$cardDetailViewModel.isNotifcationVisible)
                }
            }.onAppear {
                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                    self.cardDetailViewModel.getCardDetail(tokenizedCardId: tokenizedCardId)
                }
            }.onChange(of: self.cardDetailViewModel.deletedTokenizedCardId) { newValue in
                // deleted card
                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                    if ((newValue?.elementsEqual(tokenizedCardId)) != nil) {
                        self.viewRouter.tokenizedCardId = nil
                        self.viewRouter.currentPage = .cardList
                    }
                }
            }.onChange(of: self.cardDetailViewModel.suspendedCard) { newValue in
                // suspend or resume card
                if let tokenizedCardId = self.viewRouter.tokenizedCardId {
                    self.cardDetailViewModel.getCardDetail(tokenizedCardId: tokenizedCardId)
                }
            }
        }
    }
}

struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardDetailView().environmentObject(ViewRouter())
        }
    }
}
