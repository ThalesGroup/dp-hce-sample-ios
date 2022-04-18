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

/**
 Main TSH SDK helper.
 */
public class SdkHelper {
    
    private static var sharedSdkHelper: SdkHelper = {
        return SdkHelper()
    }()
    
    private(set) var tshPush: TshPush?
    private(set) var tshInitBase: TshInitBase?
    private(set) var tshEnrollment: TshEnrollment?
    
    let cardListHelper: CardListHelper = CardListHelper()
    let transactionHistoryHelper: TransactionHistoryHelper = TransactionHistoryHelper()
    let paymentHelper: PaymentHelper = PaymentHelper()
    let cardArtHelper: CardArtHelper = CardArtHelper()

    private var inited: Bool = false

    private init() {
        // Do not allow multiple initializations.
        if inited == true {
            AppLoggerHelper.log(.info, "\(SdkHelper.typeName) init", Bundle.main.localizedString(forKey:"sdk_helper_already_init", value:nil, table: nil))
            return
        }

        // Initialize FCM / HMS push notifications.
        self.tshPush = TshPush.init()

        // Initialize TSH SDK.
        self.tshInitBase = TshInitBase.init()
        
        // Initialize TSH Enrollment helper.
        self.tshEnrollment = TshEnrollment.init()
        
        self.inited = true
        
        self.paymentHelper.pushServiceDelegate = tshPush?.pushServiceDelegate
    }
    
    //MARK: public API

    /**
        Retrieves the shared instance of SdkHelper.
     */
    public class func shared() -> SdkHelper {
        return sharedSdkHelper
    }
    
    public static func getAppCode() -> CFData {
        return getUUID().data(using: .utf8)! as CFData
    }
    
    //MARK: private API

    private static var typeName: String {
        return String(describing: self)
    }
    
    private static func getUUID() -> String {
        SAMKeychain.setAccessibilityType(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        if let token = SAMKeychain.password(forService: SdkConstants.walletService, account: SdkConstants.walletAccount) {
            return token
        } else {
            return generateNewUUID()
        }
    }

    private static func generateNewUUID() -> String {
        let uuid = NSUUID().uuidString
        SAMKeychain.setPassword(uuid, forService: SdkConstants.walletService, account: SdkConstants.walletAccount)
        return uuid
     }
}

