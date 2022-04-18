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
 ViewModel to initialize the application and track the SDK state.
 */
class SdkStateViewModel: ObservableObject {
    
    @Published var isApplicationInitialized: Bool = false
    @Published var fcmCardOperationNotification: FcmCardOperation?
    @Published var fcmTransactionHistoryDigitialCardIdNotification: String = ""
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onSdkStateUpdate(_:)), name: .sdkStateUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateListOfCards(_:)), name: .updateListOfCards, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTransactionHistory(_:)), name: .updateTransactionHistory, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: public API

    /**
     Checks if TSH SDK was initialized succesfull.
     */
    public func checkSdkInitialization() {
        self.isApplicationInitialized = SdkHelper.shared().tshInitBase?.internalNotifications.initSuccessful ?? false
    }
        
    //MARK: notifications
    
    /**
     Receives notifications on TSH SDK state updates.
     
     @param notification Notification.
     */
    @objc func onSdkStateUpdate(_ notification: Notification) {
        if let sdkUpdate = notification.object as? Bool {
            self.isApplicationInitialized = sdkUpdate
        }
    }
    
    /**
     Receives notifications from FCM show list of cards.
 
     @param notification Notification.
     */
    @objc func updateListOfCards(_ notification: Notification) {
        if let tokenizedCardId = notification.object as? String {
            self.fcmCardOperationNotification = FcmCardOperation(tokenizedCardId: tokenizedCardId, timestempOperation: UInt64(Date().timeIntervalSince1970 * 1000))
        }
    }
    
    /**
     Receives notifications from FCM show transaction history.

     @param notification Notification.
     */
    @objc func updateTransactionHistory(_ notification: Notification) {
        if let tokenizedCardId = notification.object as? String {
            self.fcmTransactionHistoryDigitialCardIdNotification = tokenizedCardId
        }
    }

}
