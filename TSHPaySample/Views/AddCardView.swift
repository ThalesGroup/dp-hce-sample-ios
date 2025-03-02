//
// Copyright © 2024 THALES. All rights reserved.
//

import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @StateObject var cardFront: CardFrontModel

        
    var body: some View {
        ZStack() {
            // Actual card page
            mainView()
            
            // Handle all overlay windows during enrollment like terms and conditions etc...
            enrollmentModifier(yellowFlowHandler: false)
        }
    }
    
    @ViewBuilder
    private func mainView() -> some View {
        VStack() {
            CardFrontView(cardDetail: cardFront)
            
            formatedEntry(title: "Card number", placeholder: "Enter card pan", entryType: .creditCardNumber, bindable: $cardFront.cardPan).padding(.top)
            formatedEntry(title: "Expiration date", placeholder: "Enter card expiration", entryType: .creditCardExpiration, bindable: $cardFront.cardExp)
            formatedEntry(title: "Security code", placeholder: "Enter card CVV", entryType: .password, bindable: $cardFront.cardCvv)
            
            Spacer()
            
            Button {
                if !cardFront.cardPan.valueIsValid {
                    appDelegate.toastShow(caption: "Validation error", description: "Card number is not valid.", type: .warning)
                } else if (!cardFront.cardExp.valueIsValid) {
                    appDelegate.toastShow(caption: "Validation error", description: "Card expiration date is not valid.", type: .warning)
                } else if (!cardFront.cardCvv.valueIsValid) {
                    appDelegate.toastShow(caption: "Validation error", description: "Card security code is not valid.", type: .warning)
                } else {
                    appDelegate.enrollCard(pan: cardFront.cardPan.value,
                                          exp: cardFront.cardExp.value,
                                          cvv: cardFront.cardCvv.value)
                }
            } label: {
                Text("Enroll card")
            }
            .padding()
            .disabled(appDelegate.currentEnrollmentState != .notStarted)
        }
        .padding()
        .navigationBarBackButtonHidden()
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitle("Add card", displayMode: .inline)
        .toolbar {
            ToolbarItem (placement: .topBarLeading) {
                Button("Cancel") {
                    appDelegate.navigateBack()
                }.disabled(appDelegate.currentEnrollmentState != .notStarted)
            }
        }
    }
            
    @ViewBuilder
    private func formatedEntry(title: String, 
                               placeholder: String,
                               entryType: UITextContentType,
                               bindable: Binding<FormatedString>) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption)
            TextField(placeholder, text: bindable.value)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
                .textContentType(entryType)
                .keyboardType(.numberPad)
                .disabled(appDelegate.currentEnrollmentState != .notStarted)
            Divider().overlay(bindable.valueIsValid.wrappedValue ? Color.green : Color.red)
        }
    }
}

#Preview("Add card") {
    NavigationStack {
        AddCardView(cardFront: CardFrontModel(pan: "1234567891234567", exp: "1225", cvv: "123")).environmentObject({ () -> AppDelegate in
            let envObj = AppDelegate()
            envObj.currentEnrollmentState = .notStarted
            return envObj
        }())
    }
}

#Preview("Enrollment started") {
    NavigationStack {
        AddCardView(cardFront: CardFrontModel(pan: "1234567891234567", exp: "1225", cvv: "123")).environmentObject({ () -> AppDelegate in
            let envObj = AppDelegate()
            envObj.currentEnrollmentState = .started
            return envObj
        }())
    }
}

#Preview("T&C") {
    NavigationStack {
        AddCardView(cardFront: CardFrontModel(pan: "1234567891234567", exp: "1225", cvv: "123")).environmentObject({ () -> AppDelegate in
            let envObj = AppDelegate()
            envObj.currentEnrollmentState = .termsAndConditions(acceptanceData: nil)
            return envObj
        }())
    }
}
