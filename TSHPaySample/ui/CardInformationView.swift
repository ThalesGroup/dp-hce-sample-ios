//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 View to show the card detail during the enrollment.
 */
struct CardInformationView: View {
    
    @Binding var cardNumber: String
    @State private var isCardNumberEmpty : Bool   = false
    @Binding var cardExpiryDate: String
    @State private var isCardExpirationEmpty : Bool   = false
    @Binding var cardCvv: String
    @State private var isCardCvvEmpty : Bool   = false
    
    let cardNumberTextFieldLimit = 19
    let cardExpirationDateTextFieldLimit = 4
    let cardSecureCodeTextFieldLimit = 4

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(LocalizedStringKey("hint_card_number")).font(.caption)
                PlaceHolderView(
                    placeholder: Text(LocalizedStringKey("placeholder_card_number"))
                        .foregroundColor(.gray),
                    text: cardNumberValidator(), alignment: .leading)
                    .disableAutocorrection(true)
                    .textContentType(.creditCardNumber)
                    .keyboardType(.numberPad)
                    .onChange(of: cardNumber, perform: { value in
                        if value.replacingOccurrences(of: " ", with: "").count > cardNumberTextFieldLimit {
                           cardNumber = String(value.prefix(cardNumberTextFieldLimit))
                        }
                    })
                if self.isCardNumberEmpty {
                    Text(LocalizedStringKey("error_card_number"))
                        .font(.caption)
                        .foregroundColor(Color.red)
                }
                Divider()
            }
            
            Group {
                Text(LocalizedStringKey("hint_expiration")).lineLimit(1).font(.caption)
                HStack {
                    PlaceHolderView(
                        placeholder: Text(LocalizedStringKey("placeholder_expiration"))
                            .foregroundColor(.gray),
                        text: cardExpirationValidator(), alignment: .leading)
                        .keyboardType(.numberPad)
                        .disableAutocorrection(true)
                        .textContentType(.oneTimeCode)
                        .onChange(of: cardExpiryDate, perform: { value in
                            if (Int(value) != nil) {
                                if (value.count == 1) {
                                    if (Int(value)! == 0 || Int(value)! == 1) {
                                        cardExpiryDate = value
                                    } else {
                                        cardExpiryDate = ""
                                    }
                                } else if ((value.count == 2) && Int(value)! > 12)  { 
                                    cardExpiryDate = String(value.prefix(1))
                                } else if (value.count > 4)  {
                                    cardExpiryDate = String(value.prefix(1))
                                }
                            }
                            if value.count > cardExpirationDateTextFieldLimit {
                                cardExpiryDate = String(value.prefix(cardExpirationDateTextFieldLimit))
                            }
                        })
                }
                if self.isCardExpirationEmpty {
                    Text(LocalizedStringKey("error_expiration"))
                        .font(.caption)
                        .foregroundColor(Color.red)
                }
                Divider()
            }

            Group {
                Text(LocalizedStringKey("hint_cvv")).lineLimit(1).font(.caption)
                PlaceHolderView(
                    placeholder: Text(LocalizedStringKey("placeholder_cvv"))
                        .foregroundColor(.gray),
                    text: cardCvvValidator(), alignment: .leading)
                    .keyboardType(.numberPad)
                    .disableAutocorrection(true)
                    .textContentType(.oneTimeCode)
                    .onChange(of: cardCvv, perform: { value in
                        if value.count > cardSecureCodeTextFieldLimit {
                            cardCvv = String(value.prefix(cardSecureCodeTextFieldLimit))
                        }
                    })
                if self.isCardCvvEmpty {
                    Text(LocalizedStringKey("error_cvv"))
                        .font(.caption)
                        .foregroundColor(Color.red)
                }
                Divider()
            }
        }
        .padding(40)
    }
    
    private func cardNumberValidator() -> Binding<String> {
        return Binding<String>(
              get: {
                  return self.cardNumber
          }) {
              if $0.isEmpty {
                  self.isCardNumberEmpty = true
              } else {
                  self.isCardNumberEmpty = false
              }
              self.cardNumber = $0
          }
    }
    
    private func cardExpirationValidator() -> Binding<String> {
        return Binding<String>(
              get: {
                  return self.cardExpiryDate
          }) {
              if $0.isEmpty {
                  self.isCardExpirationEmpty = true
              } else {
                  self.isCardExpirationEmpty = false
              }
              self.cardExpiryDate = $0
          }
    }
    
    private func cardCvvValidator() -> Binding<String> {
        return Binding<String>(
              get: {
                  return self.cardCvv
          }) {
              if $0.isEmpty {
                  self.isCardCvvEmpty = true
              } else {
                  self.isCardCvvEmpty = false
              }
              self.cardCvv = $0
          }
    }

}

struct CardInformationView_Previews: PreviewProvider {
    static var previews: some View {
        CardInformationView(cardNumber: .constant("4123 4501 3100 3312"), cardExpiryDate: .constant("1025"), cardCvv: .constant("123"))
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
