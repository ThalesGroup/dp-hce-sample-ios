//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation
import Firebase

/**
 Class responsible for the initialization of Firebase.
 */
public class FcmService {
    
    /**
     Creates a new instance and updates the registration token..
     */
    public init() {
        Messaging.messaging().token { token, error in
            if let error = error {
                AppLoggerHelper.log(.info, "FcmService init", "Fetching FCM registration token failed: \(error)")
            } else if let token = token {
                AppLoggerHelper.log(.info, "FcmService FCM registration token", "Token \(token)")
                SdkHelper.shared().tshPush?.updateToken(token)
            }
        }
    }
    
    //MARK: public API
    
    /**
     Updates the SDK with the newly received push token.
     
     @param token Newly received push token.
     */
    public func onNewToken(_ token: Data) {
        Messaging.messaging().apnsToken = token
        SdkHelper.shared().tshPush?.updateToken(token.map { String(format: "%.2hhx", $0) }.joined())
    }
    
    /**
     Checks if Firebase is available and configures Firebase.
     
     @return True if available, false if not available or error.
     */
    public static func isAvailable() -> Bool {
        do {
            try ObjCSwift.catchException {
                FirebaseApp.configure()
            }
        } catch let error {
            AppLoggerHelper.log(.error, "\(FcmService.typeName) localizedDescription: \(error.localizedDescription)", "error: \(error);")
            return false
        }
        return true
    }
    
    private static var typeName: String {
        return String(describing: self)
    }
}
