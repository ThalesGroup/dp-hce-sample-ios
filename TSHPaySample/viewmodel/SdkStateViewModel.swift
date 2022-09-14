//
// Copyright © 2021-2022 THALES. All rights reserved.
//

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
