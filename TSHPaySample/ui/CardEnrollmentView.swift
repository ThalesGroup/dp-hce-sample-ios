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
 Payment card enrollment screen.
 */
struct CardEnrollmentView: View {
    
    @EnvironmentObject var viewRouter: ViewRouter

    @StateObject var cardEnrollmentViewModel: CardEnrollmentViewModel = CardEnrollmentViewModel()

    @State private var cardNumber: String = ""
    @State private var cardExpiryDate: String = ""
    @State private var cardCvv: String = ""
    
    @State private var progressTitle: LocalizedStringKey = ""
    @State private var progressView:Bool = false
    @State private var progressOpacity:Double = 1.0
    @State private var coverMainView:Bool = false
    
    private var pendingCardActivation: PendingCardActivation?
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView(.vertical) {
                    VStack {
                        CardFrontView(cardDetail: CardDetail(pan: cardNumber, cardExpiryDate: cardExpiryDate, cvv: cardCvv, backgroundImage: nil, cardState: .DIGITALIZED_CARD_STATE_SUSPENDED))
                        CardInformationView(cardNumber: $cardNumber, cardExpiryDate: $cardExpiryDate, cardCvv: $cardCvv)
                    }
                    .padding(.top)
                    .zIndex(0)
                    .opacity(self.progressOpacity)
                    .allowsHitTesting(!self.progressView)
                }
                switch cardEnrollmentViewModel.enrollmentState {
                case .eligibilityCheckError, .digitizationError, .wseCheckError:
                    if (cardEnrollmentViewModel.notificationData != nil) {
                        EmptyView()
                            .banner(data: $cardEnrollmentViewModel.notificationData, show: $cardEnrollmentViewModel.isNotifcationVisible)
                            .onAppear(perform: {
                                self.coverMainView = false
                                stopLoading()
                            })
                    }
                case .eligibilityCheckStart, .digitizationStart, .enrollingStart, .wseCheckStart, .wseCheckFinished:
                    LoadingView(title: self.progressTitle).zIndex(1).onAppear {
                        self.startLoading()
                    }
                case .pendingCardActivationIDVSelection:
                    LoadingView(title: self.progressTitle).zIndex(1).onAppear {
                        self.proceedPendingCardActivation()
                        self.startLoading()
                    }
                case .eligibilityCheckFinished:
                    if self.cardEnrollmentViewModel.termsAndConditions != nil {
                        TermsAndConditionsView(progressView: $progressView, progressOpacity: $progressOpacity, progressTitle: $progressTitle, coverMainView: $coverMainView, cardEnrollmentViewModel: self.cardEnrollmentViewModel)
                            .onAppear(perform: {
                                self.coverMainView = true
                                stopLoading()
                            })
                            
                    }
                case .selectIdMethod:
                    if self.cardEnrollmentViewModel.idvMethodSelector != nil {
                        IDVSelectionView(progressView: $progressView, progressOpacity: $progressOpacity, progressTitle: $progressTitle, coverMainView: $coverMainView, cardEnrollmentViewModel: self.cardEnrollmentViewModel)
                            .onAppear(perform: {
                                self.coverMainView = true
                                stopLoading()
                            })
                    }
                case .activationCodeRequired:
                    if self.cardEnrollmentViewModel.pendingCardActivation != nil {
                        IDVCodeView(progressView: $progressView, progressOpacity: $progressOpacity, progressTitle: $progressTitle, coverMainView: $coverMainView, cardEnrollmentViewModel: self.cardEnrollmentViewModel)
                            .onAppear(perform: {
                                self.coverMainView = true
                                stopLoading()
                            })
                    }
                case .digitizationFinished:
                    if self.cardEnrollmentViewModel.digitalCardId != nil {
                        EmptyView().banner(data: $cardEnrollmentViewModel.notificationData,
                                           show: $cardEnrollmentViewModel.isNotifcationVisible)
                            .onAppear(perform: {
                                stopLoading()
                                moveToCardList()
                        })
                    }
                case .inactive, .digitizationActivationCodeAcquired, .enrollingCodeRequired, .enrollingError, .enrollingFinished, .waitingForServer, .cardInstalled, .kyesReplanished:
                    EmptyView()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle(LocalizedStringKey("title_enroll_card"), displayMode: .inline)
            .toolbar {
                ToolbarItem (placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("button_enroll_cancel_flow")) {
                        moveToCardList()
                    }.disabled(progressView || coverMainView)
                }
                ToolbarItem (placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button_enroll_card")) {
                        enrollCard()
                    }.disabled(emptyRequirementsValues())
                }
            }
        }
        .onAppear {
            if ((self.viewRouter.pendingCardActivation) != nil), let pendingCardActivationState = cardEnrollmentViewModel.getPendingCardActivationState(self.viewRouter.pendingCardActivation!) {
                self.progressTitle = LocalizedStringKey("progress_title_continue_enrolling_card")
                if (pendingCardActivationState == PendingCardActivationState.IDV_METHOD_NOT_SELECTED) {
                    cardEnrollmentViewModel.enrollmentState = .pendingCardActivationIDVSelection
                } else {
                    
                    cardEnrollmentViewModel.enrollmentState = .activationCodeRequired
                }
            } else {
                self.cardNumber = SdkConstants.testCardYellowFlowPan
                self.cardCvv = SdkConstants.testCardYellowFlowCvv
                self.cardExpiryDate = SdkConstants.testCardYellowFlowExp
            }
        }
    }
    
    func moveToCardList() {
        self.viewRouter.currentPage = .cardList
    }
    
    func stopLoading() {
        self.progressView = false
        self.progressOpacity = 1
    }
    
    func startLoading() {
        self.progressView = true
        self.progressOpacity = self.progressOpacity / 10
    }
    
    func proceedPendingCardActivation() {
        self.cardEnrollmentViewModel.proceedPendingCardActivationIDVSelection(self.viewRouter.pendingCardActivation!)
    }

    func enrollCard() {
        self.progressTitle = LocalizedStringKey("progress_title_enrolling_card")
        self.cardEnrollmentViewModel.enrollCard(cardNumber, expiryDate: cardExpiryDate, cvv: cardCvv)
    }
    
    func emptyRequirementsValues() -> Bool {
        if (cardNumber.isEmpty || cardExpiryDate.isEmpty || cardCvv.isEmpty || progressView || coverMainView) {
            return true
        }
        return false
    }

}

struct CardEnrollment_Previews: PreviewProvider {
    static var previews: some View {
        CardEnrollmentView()
    }
}
