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
 Payment screen to show the generated QR code.
 */
struct PaymentView: View {
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject var viewRouter: ViewRouter
    @SceneStorage("text") var amountSceneStorage: String = "0"
    @SceneStorage("qrcode") var qrCodeStringSceneStorage: String = ""
    @StateObject var paymentInputViewModel: PaymentViewModel = PaymentViewModel()

    let amountTextFieldLimit = 7

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack() {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("title_amount_payment"))
                        PlaceHolderView(
                            placeholder: Text(LocalizedStringKey("hint_amount_payment"))
                                .foregroundColor(.gray),
                            text: $amountSceneStorage, alignment: .leading)
                            .disableAutocorrection(true)
                            .keyboardType(.decimalPad)
                            .onChange(of: amountSceneStorage, perform: { value in
                                if value.count > amountTextFieldLimit {
                                    amountSceneStorage = String(value.prefix(amountTextFieldLimit))
                                }
                            })

                    }
                    Divider()
                    Image(uiImage: self.paymentInputViewModel.generateQrCodeFromString(string: qrCodeStringSceneStorage)).resizable().aspectRatio(contentMode: .fit).padding(.top, 100)
                }.padding()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .navigationBarTitle(LocalizedStringKey("title_payment"), displayMode: .inline)
                    .navigationBarBackButtonHidden(false)
                    .toolbar {
                        ToolbarItem (placement: .navigationBarLeading) {
                            Button(LocalizedStringKey("button_close_payment")) {
                                self.amountSceneStorage = "0"
                                self.qrCodeStringSceneStorage = ""
                                self.viewRouter.currentPage = .cardList
                            }
                        }
                        ToolbarItem (placement: .navigationBarTrailing) {
                            Button(LocalizedStringKey("button_generate_payment")) {
                                self.paymentInputViewModel.generatePaymentQrCode(amount: self.amountSceneStorage, tokenizedCardId: self.viewRouter.notification!.tokenizedCardId)
                            }.disabled(self.viewRouter.notification?.tokenizedCardId == nil)
                        }
                    }
                
                if self.paymentInputViewModel.isNotifcationVisible && self.paymentInputViewModel.notificationData != nil {
                    EmptyView()
                        .banner(data: $paymentInputViewModel.notificationData, show: self.$paymentInputViewModel.isNotifcationVisible)
                }
            }
        }.onTapGesture(count: 1) {
            self.hideKeyboard()
        }.onChange(of: self.paymentInputViewModel.qrCodeString) { newValue in
            qrCodeStringSceneStorage = newValue
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                self.amountSceneStorage = "0"
                self.qrCodeStringSceneStorage = ""
            }
        }
    }
}

struct PaymentInputView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView()
    }
}
