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

import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

/**
    ViewModel to execute the payment.
 */
class PaymentViewModel: BaseViewModel {
    @Published var qrCodeString: String = ""
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    //MARK: public API
    
    /**
     Executes the payment and generates the QR code.
     
     @param amount Maximum authorized amount.
     */
    public func generatePaymentQrCode(amount: String, tokenizedCardId: String) {
        // Ensure the default card is set before calling this method.
        DigitalizedCardManager.sharedInstance().validateDefaultCard { result, error in
            if result {
                if let digitalizedCard = DigitalizedCardManager.sharedInstance().getDigitalizedCard(tokenizedCardId) {
                    digitalizedCard.isDefaultCard { isDefault, error in
                        digitalizedCard.getStatus { digitalizedCardStatus, error in
                            if digitalizedCardStatus?.state == DigitalizedCardState.DIGITALIZED_CARD_STATE_ACTIVE {
                                SdkHelper.shared().paymentHelper.generatePaymentQrCode(amount: amount, tokenizedCardId: tokenizedCardId) { (data: Data?, error: Error?) in
                                    if let error = error {
                                        self.notifyError(error: error)
                                    } else {
                                        if let data = data {
                                            let base64: String = data.base64EncodedString()
                                            self.qrCodeString = base64
                                        }
                                    }
                                }
                            } else {
                                self.notifyCustomError(title: Bundle.main.localizedString(forKey:"payment_error_title_default_card", value:nil, table: nil), detail: Bundle.main.localizedString(forKey:"payment_error_description_card_wrong_default_card", value:nil, table: nil))
                            }
                        }
                    }
                }
            } else {
                var displayErrorMessage = Bundle.main.localizedString(forKey:"payment_error_description_card_no_default_card", value:nil, table: nil)
                let nserror = error! as NSError
                if let userInfoError = nserror.userInfo["NSLocalizedDescription"] {
                    displayErrorMessage = userInfoError as! String
                }
                self.notifyCustomError(title: Bundle.main.localizedString(forKey:"payment_error_title_default_card", value:nil, table: nil), detail: displayErrorMessage)
            }
        }
    }

    /**
     Generates QR code from string
     
     @param string Input string.
     @return UIImage with generated QR code.
     */
    public func generateQrCodeFromString(string: String) -> UIImage {
        if (!string.isEmpty) {
            let data = Data(string.utf8)
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            if let qrCodeImage = filter.outputImage?.transformed(by: transform) {
                if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                    return UIImage(cgImage: qrCodeCGImage)
                }
            }
        }
        return UIImage()
    }
}
