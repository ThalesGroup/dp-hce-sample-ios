/*
 * Copyright © 2024 THALES. All rights reserved.
 */

import SwiftUI
import TSHPaySDK

/// Notification View.
struct EnrollmentModifier: ViewModifier {
    private static let opacity = 0.95
    
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var otp: String = ""
    
    // Only main screen will handle yellow flow topic. We do not want to block the add card view.
    internal let yellowFlowHandler: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            if appDelegate.currentEnrollmentState != .notStarted {
                ZStack {}.frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .topLeading
                ).background(Color.black).opacity(0.25)
            }
            
            if appDelegate.currentEnrollmentState.isWaitingState() {
                VStack {
                    Text(appDelegate.currentEnrollmentState.waitingText())
                        .foregroundColor(Color.black)
                        .font(.system(size: 20))
                        .padding()
                        .multilineTextAlignment(.center)
                    ProgressView().progressViewStyle(.circular).padding()
                }
                .frame(width: 300)
                .background(Color.white).opacity(EnrollmentModifier.opacity)
                .cornerRadius(20)
                .shadow(radius: 20)
            } else if case .termsAndConditions = appDelegate.currentEnrollmentState {
                VStack {
                    ScrollView(.vertical) {
                        Text(appDelegate.currentEnrollmentState.termsAndConditionsText())
                            .foregroundColor(Color.black)
                            .font(.system(size: 20))
                            .padding()
                            .multilineTextAlignment(.center)
                    }.frame(minHeight: 0, maxHeight: .infinity)
                    HStack {
                        Button {
                            appDelegate.enrollCard()
                        } label: {
                            Text("Accept").font(.headline)
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            withAnimation {
                                appDelegate.currentEnrollmentState = .notStarted
                            }
                        } label: {
                            Text("Reject").font(.headline)
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .frame(width: min(UIScreen.main.bounds.size.width * 0.8, 400))
                .background(Color.white).opacity(EnrollmentModifier.opacity)
                .cornerRadius(20)
                .shadow(radius: 20)
                .scaledToFit()
            } else if case .digitizationApprovedWithIDV(_, let idvMethodSelector, let service) = appDelegate.currentEnrollmentState, yellowFlowHandler  {
                VStack {
                    Text("Please select authentication method")
                        .foregroundColor(Color.black)
                        .font(.system(size: 20))
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    ForEach(idvMethodSelector.getIDVMethodList(), id: \.self.id) { loopMethod in
                        // Sample app scope is currently for Email and SMS only.
                        if loopMethod.type == .otpByEmail || loopMethod.type == .otpBySMS {
                            Button {
                                withAnimation {
                                    appDelegate.currentEnrollmentState = .activation
                                }
                                Task {
                                    await appDelegate.handlePendingActivation(idvMethodSelector: idvMethodSelector, method: loopMethod, service: service)
                                }
                            } label: {
                                Text(methodDescription(loopMethod))
                            }
                            .padding(10)
                        }
                    }
                    .padding(.horizontal)
                    .buttonStyle(.borderless)
                }
                .frame(width: 300)
                .background(Color.white).opacity(EnrollmentModifier.opacity)
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.vertical)
            } else if case .activationRequired(let pendingActivation) = appDelegate.currentEnrollmentState, yellowFlowHandler {
                VStack {
                    Text("Please enter the verification:")
                        .foregroundColor(Color.black)
                        .font(.system(size: 20))
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    TextField("Verification value", text: $otp)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .padding()
                    
                    HStack {
                        Button {
                            withAnimation {
                                appDelegate.currentEnrollmentState = .activation
                            }
                            Task {
                                if let data = otp.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                                    try await pendingActivation.activate(withOTP: data)
                                }
                                otp = ""
                            }
                        } label: {
                            Text("Confirm").font(.headline)
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                        .disabled(otp.isEmpty)
                    }
                    
                }
                .frame(width: 300)
                .background(Color.white).opacity(EnrollmentModifier.opacity)
                .cornerRadius(20)
                .shadow(radius: 20)
            }
        }
    }
    
    private func methodDescription(_ method: TSHPaySDK.CardDigitizationService.IDVMethod) -> String {
        let typeEnum = method.type
        switch typeEnum {
        case .otpBySMS:
            return "Verification with SMS OTP to \n \(method.value)"
        case .otpByEmail:
            return "Verification with OTP sent to Email \n \(method.value)"
        case .customerService:
            return "Verification via customer Sevice. \n Please call: \(method.value)"
        case .webService:
            return "Verification via web service. \n Visit web url: \(method.value)"
        case .other:
            return "\(method.typeDescription) \n \(method.value)"
        case .appToApp:
            // TODO: Implement
            return "App to app verivication."
        @unknown default:
            fatalError()
        }
    }
}

func enrollmentModifier(yellowFlowHandler: Bool) -> some View {
    EmptyView().modifier(EnrollmentModifier(yellowFlowHandler: yellowFlowHandler))
}

#Preview("Activation") {
    enrollmentModifier(yellowFlowHandler: true).environmentObject({ () -> AppDelegate in
        let envObj = AppDelegate()
        envObj.currentEnrollmentState = .activation
        return envObj
    }())
}
