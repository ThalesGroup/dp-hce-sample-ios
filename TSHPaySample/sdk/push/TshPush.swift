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
import SwiftUI

import TSHPaySDK

/**
 Class to handle push notifications.
 */
public class TshPush: NSObject {
    
    let internalNotifications: InternalNotifications

    private let senderIdCps: String = "cps"
    private let senderIdTns: String = "tns"
    private let senderMessageKey: String = "sender"
    private let sharedPreferenceName: String = "pushHelperStorage"
    private let pushTokenLocalKey: String = "pushTokenLocal"
    private let pushTokenRemoteKey: String = "pushTokenRemote"
    private let unprocessedNotificationsKey: String = "unprocessedNotifications"
    
    private(set) var fcmService: FcmService?
    private var initialEnrollment:Bool = false
    private var currentlyUpdatedToken: String?
    private(set) weak var pushServiceDelegate: PushServiceDelegate?
    private var refreshCardList: Bool = false
    
    /**
     Main entry point which need to be called as soon as the app will run.
     */
    public override init() {
        self.internalNotifications = InternalNotifications()
        super.init()
        self.pushServiceDelegate = self
        if FcmService.isAvailable() {
            fcmService = FcmService.init()
        } else {
            fatalError("\(TshPush.typeName) \(Bundle.main.localizedString(forKey: "push_provider_missing", value: nil, table: nil))")
        }
    }
    
    //MARK: public API
    
    /**
     Last token provided by either SDK locally.
     
     - Returns: Return FCM token in proper format expected by SDK or null in case it was not given yet
     */
    public func getPushTokenLocal() -> String {
        getStorage()?.object(forKey: pushTokenLocalKey) as? String ?? ""
    }
    
    /**
     Enrollment of first card will also enroll to the CPS and update push token on server.
     We have to track this state and make sure we update tokens accordingly.
     */
    public func onEnrollmentNeeded() {
        initialEnrollment = true
    }
    
    /**
     End of CPS enrollment. Reefer to the 'enrollmentNeeded' description above.
     
     - Parameter successfully: Whether CPS enrollment end up with error or not.
     */
    public func onEnrollmentFinished(_ successfully: Bool) {
        // Original enrollment was successful, we can mark local token as remote.
        if (successfully && initialEnrollment) {
            setPushTokenRemote(getPushTokenLocal())
        }
        // Unlock this status in case that user will enroll more than one card during the same
        // session. In that case no token will be updated.
        initialEnrollment = false
    }
    
    public func onSdkInitialized() {
        // Make sure, that notification token is up to-date.
        updateToken(getPushTokenLocal())
    }
    
    //MARK: internal API
    
    func updateToken(_ token: String?) {
        // Ignore nullable input.
        if (token == nil) {
            return
        }

        // Update for this token is ongoing. We have to wait for result.
        // Failure does have auto retry mechanism.
        if (token!.caseInsensitiveCompare(currentlyUpdatedToken ?? "") == .orderedSame) {
            return
        }
        
        // Local value can be stored all the time, there is no point of checking for difference.
        setPushTokenLocal(token!)
        
        // Now we want to make sure, that local is different from last successful update of remote one.
        if (token!.caseInsensitiveCompare(getPushTokenRemote()) == .orderedSame) {
            return
        }
        // Mark current update as ongoing so we will not try
        currentlyUpdatedToken = token;
        do {
            let provisioningService = ProvisioningServiceManager.sharedInstance().getProvisioningBusinessService()
            try provisioningService?.updatePushToken(token!, delegate:self.pushServiceDelegate!)
        } catch {
            //It may throw error when the device is not yet enrolled.
            AppLoggerHelper.log(.error, "\(TshPush.typeName) localizedDescription: Notification token update error", "error: \(error);")
        }
    }
    
    func onMessageReceived(_ notificationData: [AnyHashable: Any]) {
        // Transform incoming data to bundle accepted by SDK and find original sender.
        var sender: String = "";
        for (index, element) in notificationData {
            AppLoggerHelper.log(.info, "\(TshPush.typeName) onMessageReceived", "\(index) ---|--- \(element)")
            if let elementString = element as? String, let indexString = index as? String {
                if (senderMessageKey.caseInsensitiveCompare(indexString) == .orderedSame) {
                    sender = elementString
                }
            }
        }

        if !sender.isEmpty {
            // We can only process current message if SDK is fully initialized.
            if (SdkHelper.shared().tshInitBase?.getMgSdkState() == .CONFIGURED) {
                    if (senderIdCps.caseInsensitiveCompare(sender) == .orderedSame) {
                        let provisioningService = ProvisioningServiceManager.sharedInstance().getProvisioningBusinessService()
                        do {
                            try provisioningService?.processIncomingMessage(notificationData, with: self.pushServiceDelegate!)
                        } catch {
                            AppLoggerHelper.log(.error, "\(TshPush.typeName) localizedDescription: processIncomingMessage", "error: \(error);")
                        }
                    } else if (senderIdTns.caseInsensitiveCompare(sender) == .orderedSame) {
                        if let tokenizedCardId = notificationData["digitalCardId"] as? String {
                            internalNotifications.updateTransactionHistory(tokenizedCardId)
                        }
                    }
            } else if (senderIdCps.caseInsensitiveCompare(sender) == .orderedSame || senderIdTns.caseInsensitiveCompare(sender) == .orderedSame) {
                AppLoggerHelper.log(.error, "\(TshPush.typeName) onMessageReceived", Bundle.main.localizedString(forKey:"push_received_sdk_not_initialized", value:nil, table: nil))
            }
        }
    }

    //MARK: private API
    
    private func getStorage() -> UserDefaults? {
        return UserDefaults.init(suiteName: sharedPreferenceName)
    }
    
    private func setPushTokenLocal(_ value: String) {
        getStorage()?.set(value, forKey: pushTokenLocalKey)
    }
    
    private func getPushTokenRemote() -> String {
        getStorage()?.object(forKey: pushTokenRemoteKey) as? String ?? ""
    }
    
    private func setPushTokenRemote(_ value: String) {
        getStorage()?.set(value, forKey: pushTokenRemoteKey)
    }
    
    private static var typeName: String {
        return String(describing: self)
    }
}

//MARK: PushServiceDelegate API
extension TshPush: PushServiceDelegate {

    public func onUnSupportedPushContent(_ businessService: BusinessService, pushMessage: [AnyHashable : Any]?) {
        // This method is not relevant for push update method.
        self.refreshCardList = false
    }
    
    public func onCompleted(_ businessService: BusinessService, tokenizedCardId: String?) {
        // At this point we have confirmation, that server have same token as we do.
        if (self.currentlyUpdatedToken != nil) {
            self.setPushTokenRemote(self.currentlyUpdatedToken!);
        }
        
        if (self.refreshCardList && tokenizedCardId != nil) {
            internalNotifications.updateListOfCards(tokenizedCardId!)
            self.refreshCardList = false
        }
    }
    
    public func onError(_ businessService: BusinessService, error: ProvisioningServiceError) {
        AppLoggerHelper.log(.error, "\(TshPush.typeName) updatePushToken", "SDKErrorCode: \(error.sDKErrorCode) httpStatusCode: \(error.httpStatusCode) cpsErrorCode: \(error.cpsErrorCode)")
        // Try again after few seconds.
        if (self.currentlyUpdatedToken != nil) {
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.updateToken(self.currentlyUpdatedToken!)
            }
        }
        self.refreshCardList = false
    }
    
    public func onServerMessage(_ businessService: BusinessService, serviceMessage: ProvisioningServiceMessage?, forTokenId tokenizedCardId: String?) {
        if serviceMessage != nil && ((REQUEST_REPLENISH_KEYS.compare(serviceMessage!.msgCode!) == .orderedSame)) {
            self.refreshCardList = false
        } else {
            self.refreshCardList = true
        }
    }
}
