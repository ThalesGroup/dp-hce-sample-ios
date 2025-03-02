//
// Copyright © 2024 THALES. All rights reserved.
//

import SwiftUI

struct CardListView: View {    
    @EnvironmentObject var appDelegate: AppDelegate
    @StateObject var cardListModel: CardListModel
    @StateObject var paymentModel: PaymentModel
    
    @State private var selectedCardIndex: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack() {
            // Actual card page
            mainView()
            
            // Handle all overlay windows during activation of yellow flow.
            enrollmentModifier(yellowFlowHandler: true)
        }
    }

    @ViewBuilder
    private func mainView() -> some View {
        VStack {
            if cardListModel.cardList.isEmpty {
                Text("Your Wallet is empty, please\n add new card").multilineTextAlignment(.center)
            } else {
                TabView(selection: $selectedCardIndex) {
                    ForEach(0..<cardListModel.cardList.count, id: \.self) { index in
                        VStack() {
                            CardFrontView(cardDetail: cardListModel.cardList[index])
                                .padding(.top)
                            Spacer()
                        }
                        .shadow(radius: 2)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: UUID())
                
                // Use custom index display since the system one is hard to control the color based on colorscheme.
                if cardListModel.cardList.count > 1 {
                    HStack {
                        ForEach(0..<cardListModel.cardList.count, id: \.self) { index in
                            Capsule()
                                .fill(indexColor(index))
                                .frame(width: 35, height: 8)
                                .onTapGesture {
                                    selectedCardIndex = index
                                }
                        }
                        .padding(.top)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitle(serverEnvironment.getConfigurationName(), displayMode: .inline)
        .toolbar {
            ToolbarItem (placement: .topBarTrailing) {
                Button("Enroll card") {
                    appDelegate.navigate(to: .addCard)
                }
                .disabled(appDelegate.currentEnrollmentState != .notStarted)
            }
        }
        .padding()
        .onAppear {
            Task {
                await cardListModel.realoadCardList()
            }
        }

        .onChange(of: paymentModel.toastData) {
            // We can ignore hide from payment model.
            if let data = paymentModel.toastData {
                appDelegate.toastData = data
            }
            paymentModel.toastData = nil
        }
        .onChange(of: appDelegate.cardForManualPayment) { oldValue, newValue in
            if let cardForManualPayment = newValue {
                paymentModel.startContactlessPayment(withDigitalCardID: cardForManualPayment)
                appDelegate.cardForManualPayment = nil
            }
        }.onChange(of: appDelegate.reloadCardList) { oldValue, newValue in
            if newValue {
                appDelegate.reloadCardList = false
                Task {
                    await cardListModel.realoadCardList()
                }
            }
        }
    }
        
    private func indexColor(_ index: Int) -> Color {
        let retValue = colorScheme == .dark ? Color.white : Color.black
        return retValue.opacity(selectedCardIndex == index ? 1 : 0.33)
    }
}

#Preview("No card") {
    @Previewable @StateObject var viewModel = CardListModel([])
    @Previewable @StateObject var paymentModel = PaymentModel()
    return NavigationStack {
        CardListView(cardListModel: viewModel, paymentModel: paymentModel)
    }.environmentObject(AppDelegate())
}

#Preview("One card") {
    @Previewable @StateObject var viewModel = CardListModel([CardFrontModel(pan: "1234567891234567", exp: "1225", cvv: "123", needsReplenishment: true, isDefaultCard: true)])
    @Previewable @StateObject var paymentModel = PaymentModel()
    return NavigationStack {
        CardListView(cardListModel: viewModel, paymentModel: paymentModel)
    }.environmentObject(AppDelegate())
}

#Preview("Two cards") {
    @Previewable @StateObject var viewModel = CardListModel(
        [CardFrontModel(pan: "1234567891234567", exp: "1225", cvv: "123", needsReplenishment: true, isDefaultCard: true),
         CardFrontModel(pan: "7654321987654321", exp: "123", cvv: "456", needsReplenishment: true, isDefaultCard: true)])
    @Previewable @StateObject var paymentModel = PaymentModel()
    return NavigationStack {
        CardListView(cardListModel: viewModel, paymentModel: paymentModel)
    }.environmentObject(AppDelegate())
}
