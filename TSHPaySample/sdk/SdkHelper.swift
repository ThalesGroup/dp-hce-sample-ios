//
// Copyright © 2021-2022 THALES. All rights reserved.
//

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

