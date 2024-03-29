//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Screen for OTP entry.
 */
struct IDVCodeView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var cardEnrollmentViewModel: CardEnrollmentViewModel

    @State private var isSecretOtp = true
    @State private var isDisableConfirmButton = true
    @State private var otp:String = String()

    @Binding var progressTitle: LocalizedStringKey
    @Binding var progressView:Bool
    @Binding var progressOpacity:Double
    @Binding var coverMainView:Bool

    init(progressView: Binding<Bool>, progressOpacity: Binding<Double>,
         progressTitle: Binding<LocalizedStringKey>, coverMainView: Binding<Bool>,
         cardEnrollmentViewModel: CardEnrollmentViewModel) {
        self.cardEnrollmentViewModel = cardEnrollmentViewModel
        self._progressTitle = progressTitle
        self._progressView = progressView
        self._progressOpacity = progressOpacity
        self._coverMainView = coverMainView
    }

    var body: some View {
        ZStack {
            // PopUp background color
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)

            VStack(alignment: .center) {
                Text(LocalizedStringKey("title_idv_code")).fontWeight(.bold)
                VStack(alignment: .center) {
                    HStack {
                        if isSecretOtp {
                            SecretView(otp: $otp, isSecretOtp: $isSecretOtp, isDisableConfirmButton: $isDisableConfirmButton)
                        } else {
                            PlainView(otp: $otp, isSecretOtp: $isSecretOtp, isDisableConfirmButton: $isDisableConfirmButton)
                        }
                    }.padding(30)
                }
                Divider()
                HStack {
                    Spacer()
                    Button(LocalizedStringKey("button_cancel_idv_code")) {
                        cancelAuthenticationCode()
                        self.presentationMode.wrappedValue.dismiss()
                    }

                    Spacer()
                    Divider()

                    Spacer()
                    Button(LocalizedStringKey("button_continue_idv_code")) {
                        submitAuthenticationCode()
                        self.presentationMode.wrappedValue.dismiss()
                    }.disabled(isDisableConfirmButton)
                    Spacer()
                }
                 .frame(height: 45, alignment: .center)
            }.frame(width: UIScreen.main.bounds.width-50, height: 200)
            .background(colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.9))
            .cornerRadius(30)
        }
    }

    func cancelAuthenticationCode() {
        self.progressView = false
        self.coverMainView = false
        self.progressOpacity = 1.0
        self.cardEnrollmentViewModel.cancelActivationCode()
    }

    func submitAuthenticationCode() {
        self.progressTitle = LocalizedStringKey("progress_title_idv_code")
        self.progressView = true
        self.cardEnrollmentViewModel.submitActivationCode(otp.utf8CString)
    }
}

struct IDVCodeView_Previews: PreviewProvider {
    static var previews: some View {
        IDVCodeView(progressView: .constant(false),
                    progressOpacity: .constant(1.0), progressTitle: .constant(""),
                    coverMainView: .constant(false), cardEnrollmentViewModel: CardEnrollmentViewModel())
    }
}

struct SecretView: View {
    
    @Binding private var otp:String
    @Binding private var isSecretOtp:Bool
    @Binding private var isDisableConfirmButton:Bool

    init(otp: Binding<String>, isSecretOtp: Binding<Bool>, isDisableConfirmButton: Binding<Bool>) {
        self._otp = otp
        self._isSecretOtp = isSecretOtp
        self._isDisableConfirmButton = isDisableConfirmButton
    }


    var body: some View {
        SecureField(LocalizedStringKey("hint_idv_code"), text: $otp).frame(width: 200).lineLimit(1).keyboardType(.decimalPad).onChange(of:  otp) { newValue in
            if newValue.isEmpty {
                isDisableConfirmButton = true
            } else {
                isDisableConfirmButton = false
            }
        }
        Button(action: {
            self.isSecretOtp.toggle()
        }){
            Image(systemName: "eye").foregroundColor(.secondary)
        }
    }
}

struct PlainView: View {
    
    @Binding private var otp:String
    @Binding private var isSecretOtp:Bool
    @Binding private var isDisableConfirmButton:Bool

    init(otp: Binding<String>, isSecretOtp: Binding<Bool>, isDisableConfirmButton: Binding<Bool>) {
        self._otp = otp
        self._isSecretOtp = isSecretOtp
        self._isDisableConfirmButton = isDisableConfirmButton
    }

    var body: some View {
        TextField(LocalizedStringKey("hint_idv_code"), text: $otp).frame(width: 200).lineLimit(1).keyboardType(.decimalPad).onChange(of:  otp) { newValue in
            if newValue.isEmpty {
                isDisableConfirmButton = true
            } else {
                isDisableConfirmButton = false
            }
        }
        Button(action: {
            self.isSecretOtp.toggle()
        }){
            Image(systemName: "eye.slash").foregroundColor(.secondary)
        }
    }
}


