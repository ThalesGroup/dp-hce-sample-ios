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
import WebKit

/**
 Terms and Conditions screen.
 */
struct TermsAndConditionsView: View {

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var cardEnrollmentViewModel: CardEnrollmentViewModel

    @Binding var progressTitle: LocalizedStringKey
    @Binding var progressView:Bool
    @Binding var progressOpacity:Double
    @Binding var coverMainView:Bool
    
    init(progressView: Binding<Bool>, progressOpacity: Binding<Double>, progressTitle: Binding<LocalizedStringKey>, coverMainView: Binding<Bool>,
         cardEnrollmentViewModel: CardEnrollmentViewModel) {
        self._progressView = progressView
        self._progressOpacity = progressOpacity
        self._progressTitle = progressTitle
        self._coverMainView = coverMainView
        self.cardEnrollmentViewModel = cardEnrollmentViewModel
    }

    var body: some View {
            ZStack {
                // PopUp background color
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)

                if (progressView) {
                    LoadingView(title: LocalizedStringKey("progress_title_termsandconditions")).zIndex(1)
                }
                VStack {
                    Text(LocalizedStringKey("title_tac")).fontWeight(.bold)
                    WebView(termsAndConditionsText: cardEnrollmentViewModel.termsAndConditions?.getText())
                        .padding(EdgeInsets(top: 20, leading: 25, bottom: 20, trailing: 25))
                    Divider()
                    HStack {
                        Spacer()
                        Button(action: {
                            disagreeTermsAndConditions()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(LocalizedStringKey("button_disagree_tac"))
                        }

                        Spacer()
                        Divider()

                        Spacer()
                        Button(action: {
                            agreeTermsAndConditions()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(LocalizedStringKey("button_agree_tac"))
                        }
                        Spacer()
                    }.padding(0)
                     .frame(height: 45, alignment: .center)
                }.background(colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.9))
            }
    }
    
    func disagreeTermsAndConditions() {
        cardEnrollmentViewModel.disagreeTermsAndCondition()
        self.progressView = false
        self.coverMainView = false
        self.progressOpacity = 1.0
    }

    func agreeTermsAndConditions() {
        cardEnrollmentViewModel.acceptTermsAndCondition()
        progressTitle = LocalizedStringKey("progress_title_termsandconditions")
        self.coverMainView = false
    }
}

struct WebView: UIViewRepresentable {
    
  @Environment(\.colorScheme) var colorScheme: ColorScheme
    
  var termsAndConditionsText: String?
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
      if (termsAndConditionsText != nil) {
          let headerString = "<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>"

          if (colorScheme == .dark) {
              let lightDarkCSS = ":root { color-scheme: light dark; }"
              let base64 = lightDarkCSS.data(using: .utf8)!.base64EncodedString()

              let script = """
                  javascript:(function() {
                      var parent = document.getElementsByTagName('head').item(0);
                      var style = document.createElement('style');
                      style.type = 'text/css';
                      style.innerHTML = window.atob('\(base64)');
                      parent.appendChild(style);
                  })()
              """

              let cssScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
              uiView.configuration.userContentController.addUserScript(cssScript)
          }
          uiView.loadHTMLString(headerString + termsAndConditionsText!, baseURL: nil)
     }
  }
}

struct TermsAndConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndConditionsView(progressView: .constant(false), progressOpacity: .constant(1.0), progressTitle: .constant(""), coverMainView: .constant(false), cardEnrollmentViewModel: CardEnrollmentViewModel())
    }
}
