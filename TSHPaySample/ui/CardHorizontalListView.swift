//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Card list screen.
 */
struct CardHorizontalListView: View {
    
    @EnvironmentObject var viewRouter: ViewRouter
    
    @StateObject var cardListViewModel:CardListViewModel = CardListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                if cardListViewModel.cardList.count != 0 {
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment:.top) {
                                TabView {
                                    ForEach(0..<cardListViewModel.cardList.count, id: \.self) { i in
                                        ZStack {
                                            VStack {
                                                CardFrontView(cardDetail: CardDetail(pan: "************\(self.cardListViewModel.cardList[i].pan)",
                                                    cardExpiryDate: self.cardListViewModel.cardList[i].panExpiry, cvv: "***", backgroundImage: self.cardListViewModel.cardList[i].backgroundImage, cardState:  self.cardListViewModel.cardList[i].state))
                                                HStack {
                                                    Text(LocalizedStringKey("status_information"))
                                                    Text(self.cardListViewModel.getDigitalizedCardState(self.cardListViewModel.cardList[i].state))
                                                    Spacer()
                                                }.padding([.leading], 20)
                                                HStack {
                                                    Text(LocalizedStringKey("default_information"))
                                                    if (self.cardListViewModel.cardList[i].defaultPayment) {
                                                        Text(LocalizedStringKey("default_information_yes"))
                                                    } else {
                                                        Text(LocalizedStringKey("default_information_no"))
                                                    }
                                                    Spacer()
                                                }.padding([.leading], 20)
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Button(LocalizedStringKey("button_activate_action")) {
                                                            self.viewRouter.currentPage = .enrollment
                                                            self.viewRouter.pendingCardActivation = self.cardListViewModel.cardList[i].pendingCardActivation
                                                        }.disabled((self.cardListViewModel.cardList[i].pendingCardActivation) == nil)
                                                        Button(LocalizedStringKey("button_resume_action")) {
                                                            self.cardListViewModel.resumeCard(tokenizedCardId: self.cardListViewModel.cardList[i].id)
                                                        }.disabled(!self.cardListViewModel.cardList[i].resume)
                                                         .padding([.top], 5)
                                                    }.padding([.top], 5)
                                                     .padding([.leading], 20)
                                                    Spacer()
                                                    VStack(alignment: .center) {
                                                        Button(LocalizedStringKey("button_default_action")) {
                                                            self.cardListViewModel.setDefultCard(tokenizedCardId: self.cardListViewModel.cardList[i].id)
                                                        }.disabled(self.cardListViewModel.cardList[i].defaultPayment || self.cardListViewModel.cardList[i].suspend)
                                                        Button(LocalizedStringKey("button_suspend_action")) {
                                                            self.cardListViewModel.suspendCard(tokenizedCardId: self.cardListViewModel.cardList[i].id)
                                                        }.disabled(self.cardListViewModel.cardList[i].suspend)
                                                         .padding([.top], 5)
                                                    }
                                                    .padding([.top], 5)
                                                    Spacer()
                                                    VStack(alignment: .trailing) {
                                                        Button(LocalizedStringKey("button_payment_action")) {
                                                            self.viewRouter.currentPage = .payment
                                                            self.viewRouter.notification = FcmCardOperation(tokenizedCardId: self.cardListViewModel.cardList[i].id, timestempOperation: nil)
                                                        }.disabled(!self.cardListViewModel.cardList[i].defaultPayment || !self.cardListViewModel.cardList[i].qrPaymentTypeSupported)
                                                        Button(LocalizedStringKey("button_delete_action")) {
                                                            self.cardListViewModel.deleteCard(tokenizedCardId: self.cardListViewModel.cardList[i].id)
                                                        }
                                                        .padding([.top], 5)
                                                    }
                                                    .padding([.top], 5)
                                                    .padding([.trailing], 20)
                                                }
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                                    }
                                    .padding(.all, 10)
                                }
                                .frame(width: UIScreen.main.bounds.width, height: 500)
                                .tabViewStyle(PageTabViewStyle())
                            }
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
            }.onChange(of: self.viewRouter.notification) { newValue in
                self.cardListViewModel.getCardList()
            }
        }
    }
}

struct CardHorizontalListView_Previews: PreviewProvider {
    static var previews: some View {
        CardHorizontalListView()
    }
}
