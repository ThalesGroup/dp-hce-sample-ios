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
