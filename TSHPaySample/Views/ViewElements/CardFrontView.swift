//
// Copyright © 2024 THALES. All rights reserved.
//

import SwiftUI
import TSHPaySDK
/**
 View to dispaly the card image and details.
 */
struct CardFrontView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    
    @StateObject var cardDetail: CardFrontModel
    @State private var showAlertDefaultCard = false
    @State private var showActionState = false
    @State private var showActionNeedsReplenishment = false
    
    var body: some View {
        // Stack will be for card background and card details on top of that.
        ZStack {
            foregranoudView
        }.background(backgroundView).frame(width: 337, height: 212)
        if (cardDetail.type == CardFrontModel.CardType.data) {
            settingView
        }
    }
    
    @ViewBuilder
    private var foregranoudView: some View {
        Group{
            VStack {
                Spacer()
                Text(cardDetail.cardPan.valueFormated)
                    .foregroundColor(Color.white)
                    .font(.system(size: 28))
                    .lineLimit(1)
                    .padding()
                Spacer()
            }
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("VALID THRU")
                            .font(.caption)
                            .foregroundColor(Color.white)
                        Text(cardDetail.cardExp.valueFormated)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .lineLimit(1)
                    }.padding()
                    
                    VStack(alignment: .leading) {
                        Text("SECURITY CODE")
                            .font(.caption)
                            .foregroundColor(Color.white)
                        Text(cardDetail.cardCvv.valueFormated)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .lineLimit(1)
                    }.padding()

                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var settingView: some View {
        VStack{
            HStack {
                VStack(alignment: .leading) {
                    Text("Status\n of card")
                        .font(.caption)
                        .foregroundColor(Color.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Button {
                        if cardDetail.cardState == .inactive {
                            appDelegate.resumePendingActivation(cardDetail.digitalCardID)
                        } else {
                            showActionState.toggle()
                        }
                    } label: {
                        Text(cardDetail.cardState.description)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderedProminent)
                    .contentShape(Rectangle())
                    .actionSheet(isPresented: $showActionState) {
                        ActionSheet(title: Text("Change card state"), message: Text("Choose one of this"), buttons: [
                            .default(Text("Suspended")) { cardDetail.changeCardState(cardManagmentAction: .suspend) },
                            .default(Text("Resume")) { cardDetail.changeCardState(cardManagmentAction: .resume) },
                            .default(Text("Delete")) { cardDetail.changeCardState(cardManagmentAction: .delete) },
                            .cancel()
                        ])
                    }
                    .disabled(appDelegate.currentEnrollmentState != .notStarted)
                }.padding()
                VStack(alignment: .center) {
                    Text("Needs\n replenishment")
                        .font(.caption)
                        .foregroundColor(Color.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Button {
                        showActionNeedsReplenishment.toggle()
                    } label: {
                        Text(cardDetail.needsReplenishment.description)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderedProminent)
                    .contentShape(Rectangle())
                    .alert(isPresented: $showActionNeedsReplenishment) {
                        Alert(title: Text("Replenishment"),
                              message: Text("Do you want replenish card?"),
                              primaryButton: Alert.Button.default(Text("Yes"), action: {
                            cardDetail.triggerReplenishment()
                        }),
                              secondaryButton: Alert.Button.default(Text("No"), action: {
                            
                        })
                        )
                    }
                    .disabled(appDelegate.currentEnrollmentState != .notStarted)
                }
                VStack(alignment: .trailing) {
                    Text("Default\n card")
                        .font(.caption)
                        .foregroundColor(Color.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Button {
                        showAlertDefaultCard.toggle()
                    } label: {
                        Text(cardDetail.isDefaultCard.description)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderedProminent)
                    .contentShape(Rectangle())
                    .alert(isPresented: $showAlertDefaultCard) {
                        if cardDetail.isDefaultCard {
                            Alert(title: Text("Default card operation"),
                                  message: Text("Do you want remove the current default payment card?"),
                                  primaryButton: Alert.Button.default(Text("Yes"), action: {
                                cardDetail.unsetDefaultCard()
                            }),
                                  secondaryButton: Alert.Button.default(Text("No"), action: {
                                
                            })
                            )
                        } else {
                            Alert(title: Text("Default card operation"),
                                  message: Text("Do you want set the current payment card as default?"),
                                  primaryButton: Alert.Button.default(Text("Yes"), action: {
                                cardDetail.setDefultCard()
                            }),
                                  secondaryButton: Alert.Button.default(Text("No"), action: {
                            })
                            )
                        }
                    }
                    .disabled(appDelegate.currentEnrollmentState != .notStarted)
                }.padding()
            }
            VStack(alignment: .center) {
                Button {
                    appDelegate.cardForManualPayment = cardDetail.digitalCardID
                } label: {
                    Text("Manual Payment").font(.headline)
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(appDelegate.currentEnrollmentState != .notStarted)
            }
        }
        .onChange(of: cardDetail.toastData) {
            // We can ignore hide from payment model.
            if let data = cardDetail.toastData {
                appDelegate.toastData = data
            }
            cardDetail.toastData = nil
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if let backImage = cardDetail.cardBackground {
            Image(uiImage: backImage).resizable().aspectRatio(contentMode: .fill)
        } else {
            VStack(alignment: .trailing) {
                HStack {
                    Spacer()
                    Image("Thales_logo")
                }.padding()
                Spacer()
            }.background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.3306755424, green: 0.7205328345, blue: 0.9244166613, alpha: 1)), Color.blue]), startPoint: .topLeading, endPoint: .bottomLeading))
                .cornerRadius(20)
        }
    }
}

#Preview("Manual entry") {
    CardFrontView(cardDetail: CardFrontModel(pan: "1234567894561234", exp: "122", cvv: "123", needsReplenishment: true, isDefaultCard: true) )
}
