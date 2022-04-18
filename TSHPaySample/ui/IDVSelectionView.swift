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
 Screen to select the Identification and Verification method.
 */
struct IDVSelectionView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var cardEnrollmentViewModel: CardEnrollmentViewModel

    @Binding var progressTitle: LocalizedStringKey
    @Binding var progressView:Bool
    @Binding var progressOpacity:Double
    @Binding var coverMainView:Bool

    private var idvMethodList: [String]?
    private var preSelectedIdvMethod: String?
    
    init(progressView: Binding<Bool>, progressOpacity: Binding<Double>, progressTitle: Binding<LocalizedStringKey>, coverMainView: Binding<Bool>, cardEnrollmentViewModel: CardEnrollmentViewModel) {
        self.cardEnrollmentViewModel = cardEnrollmentViewModel
        self._progressTitle = progressTitle
        self._progressView = progressView
        self._progressOpacity = progressOpacity
        self._coverMainView = coverMainView
        let result = self.cardEnrollmentViewModel.listIdvMethods()
        self.idvMethodList = result.idvMethods
        self.preSelectedIdvMethod = result.preSelectedIdvMethod
    }

    var body: some View {
        ZStack {
            // PopUp background color
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)

            VStack(alignment: .center) {
                Text(LocalizedStringKey("title_idv_selction")).fontWeight(.bold)

                HStack {
                    RadioButtonGroupView(items: idvMethodList!,
                                         selectedId: preSelectedIdvMethod!) { selected in
                        self.cardEnrollmentViewModel.selectedIdvMethod = selected
                    }.isEmptyIdvMethodList(idvMethodList!)
                     .padding(.leading, 10)
                }
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        cancelIdv()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(LocalizedStringKey("button_cancel_idv_selction"))
                    }

                    Spacer()
                    Divider()

                    Spacer()
                    Button(action: {
                        selectIdv()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(LocalizedStringKey("button_continue_idv_selction"))
                    }
                    Spacer()
                }
                 .frame(height: 45, alignment: .center)
            }.background(colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.9))
            .cornerRadius(30)
            .frame(width: UIScreen.main.bounds.width-50, height: 300)
        }
    }
    
    func cancelIdv() {
        self.progressView = false
        self.coverMainView = false
        self.progressOpacity = 1.0
        self.cardEnrollmentViewModel.cancelIdvSelection()
    }

    func selectIdv() {
        self.progressTitle = LocalizedStringKey("progress_title_idv_selction")
        self.coverMainView = false
        self.cardEnrollmentViewModel.selectIdv()
    }
}

extension View {

    func isEmptyIdvMethodList(_ listIdvMethod: [String]) -> some View {
        modifier(IDVSelectionModifier(listIdvMethod: listIdvMethod))
    }
}

struct IDVSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        IDVSelectionView(progressView: .constant(false),
                         progressOpacity: .constant(1.0), progressTitle: .constant(""),
                         coverMainView: .constant(false), cardEnrollmentViewModel: CardEnrollmentViewModel())
    }
}
