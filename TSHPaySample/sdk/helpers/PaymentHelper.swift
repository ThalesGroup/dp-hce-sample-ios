//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

public typealias GeneratePaymentQrCodeCompletionBlock = (_ data: Data?, _ error: Error?) -> Void

/**
 Helper class for payment related operations.
 */
public class PaymentHelper {
    weak var pushServiceDelegate: PushServiceDelegate?

    //MARK: public API
    
    /**
     Generates the payment data.
     
     @param completionBlock Callback handler.
     */
    public func generatePaymentQrCode(amount: String, tokenizedCardId: String, completionBlock: @escaping GeneratePaymentQrCodeCompletionBlock) {
        var formatedAmount: String = amount.replacingOccurrences(of: ".", with: "")
        formatedAmount = formatedAmount.replacingOccurrences(of: ",", with: "")
        formatedAmount = formatedAmount.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
        formatedAmount = formatedAmount.leftPadding(toLength: 12, withPad: "0")
        
        self.getAIDFromCard(tokenizedCardId) { result in
            if let result = result, result.count > 0 {
                let primaryAid = result[0]

                var paymentInputData: PaymentInputData?
                let builder = try? PaymentInputDataBuilder.init(paymentType: .QR)
                if (builder != nil) {
                    builder!.setQrCodePaymentParametersWithAmount(formatedAmount,
                                                                 currencyCode: "0978", // EUR
                                                                 countryCode: nil)
                    builder!.setPureQrCodePaymentParametersWithIddData("000000000000000000000000000000", aidData: primaryAid)
                    paymentInputData = try? builder!.build()
                }

                if let paymentService = PaymentServiceManager.sharedInstance().getPaymentBusinessService(), paymentInputData != nil {
                    do {
                        //just to be safe. clear previous state
                        paymentService.deactivate()
                        try paymentService.generateApplicationCryptogram(with: PaymentType.QR, paymentInputData: paymentInputData!, delegate: PaymentServiceDelegateImpl(self, completionBlock, self.pushServiceDelegate, tokenizedCardId))
                    } catch {
                        paymentService.deactivate()
                        completionBlock(nil, error)
                    }
                } else {
                    completionBlock(nil, NSError.make(localizedMessage: "Cannot retrieve PaymentService"))
                }
            } else {
                completionBlock(nil, NSError.make(localizedMessage: "Cannot primary AID"))
            }
        }
    }
    
    /**
     Replenish card keys for continue to the payments.
     
     @param tokenizedCardId Tokenized card ID reprezenting a specific card.
     */
    public func replenishKeys(_ tokenizedCardId: String, _ cardStatus: DigitalizedCardStatus) {
        if (cardStatus.state == DigitalizedCardState.DIGITALIZED_CARD_STATE_ACTIVE && cardStatus.needsReplenishment) {
            do {
                try ProvisioningServiceManager.sharedInstance().getProvisioningBusinessService()?.sendRequest(forReplenishment: tokenizedCardId, delegate: self.pushServiceDelegate!)
            } catch {
                AppLoggerHelper.log(.error, "\(String(describing: self)) localizedDescription: \(error.localizedDescription)", "error: \(error);")
            }
        }
    }

    //MARK: private API

    private func getAIDFromCard(_ tokenId : String, completion: @escaping (_ result:[String]?) -> Void) {
        let dcm = DigitalizedCardManager.sharedInstance()
        let card = dcm.getDigitalizedCard(tokenId)
        card?.getDetails({ (cardDetails, error) in
            completion(cardDetails?.qrAIDs)
        })
    }
}

//MARK: PaymentServiceDelegate API

class PaymentServiceDelegateImpl: PaymentServiceDelegate {
    private var paymentHelper: PaymentHelper
    private var generatePaymentQrCodeCompletionBlock: GeneratePaymentQrCodeCompletionBlock?
    weak var pushServiceDelegate: PushServiceDelegate?
    var tokenizedCardId: String

    init(_ paymentHelper: PaymentHelper, _ completion: @escaping GeneratePaymentQrCodeCompletionBlock, _ pushServiceDelegate: PushServiceDelegate?, _ tokenizedCardId: String) {
        self.paymentHelper = paymentHelper
        self.generatePaymentQrCodeCompletionBlock = completion
        self.pushServiceDelegate = pushServiceDelegate
        self.tokenizedCardId = tokenizedCardId
    }
    
    public func onDataReady(forPayment paymentService: PaymentService, transactionContext: TransactionContext) {
        guard let qrCodeData = paymentService.qrCodeData else {
            self.generatePaymentQrCodeCompletionBlock?(nil, NSError.make(localizedMessage: "Cannot retrieve QrCodeData"))
            return
        }

        // check for status word - 9000(Success)
        if (qrCodeData.statusWord?.count == 2 && qrCodeData.statusWord?[0] == 0x90 && qrCodeData.statusWord?[1] == 0x00) {
            self.generatePaymentQrCodeCompletionBlock?(qrCodeData.chipDataField, nil)
        } else {
            self.generatePaymentQrCodeCompletionBlock?(nil, NSError.make(localizedMessage: "Wrong status word"))
        }

        //Replenishment if needed
        if let digitizedCardStatus = transactionContext.digitizedCardStatus {
            self.paymentHelper.replenishKeys(self.tokenizedCardId, digitizedCardStatus)
        }
    }
    
    public func onError(_ errorCode: PaymentServiceErrorCode, transactionContext: TransactionContext?, message: String) {
        self.generatePaymentQrCodeCompletionBlock?(nil, NSError.make(localizedMessage: message))
    }
    
    public func onPaymentServiceActivate(_ activatedPaymentService: PaymentService, chVerification verifier: CHVerifier, cvmTimeout: uint) {
        do{
          let appCodeStatus : AppCodeStatus = DeviceCVMManager.sharedInstance().appCodeStatus();
          //notSupported : the access control is not an application password
            
            if (appCodeStatus != .notSupported) {
                try verifier.verify(appCode: { (publicKeyRef) -> Unmanaged<CFData>? in
                    let appCode : CFData = SdkHelper.getAppCode()
                    if let encryptedData = SecKeyCreateEncryptedData(publicKeyRef, SecKeyAlgorithm.rsaEncryptionOAEPSHA256, appCode, nil) {
                        return Unmanaged.passRetained(encryptedData)
                    } else {
                        return nil
                    }
                })
            }
          if (appCodeStatus == .notSupported) {
              try verifier.verify(Bundle.main.localizedString(forKey:"payment_authentication", value:nil, table: nil))
          }
          } catch {
              AppLoggerHelper.log(.error, "\(String(describing: self)) localizedDescription: \(error.localizedDescription)", "error: \(error)")
          }
    }
}
