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

extension Notification.Name {
    static let sdkStateUpdate = Notification.Name("sdkStateUpdate")
    static let updateEnrollmentState = Notification.Name("updateEnrollmentState")
    static let updateListOfCards = Notification.Name("updateListOfCards")
    static let updateTransactionHistory = Notification.Name("transactionHistory")
    static let receivedTermsAndConditions = Notification.Name("receivedTermsAndConditions")
    static let receivedIdvMethodSelector = Notification.Name("receivedIdvMethodSelector")
    static let activationRequired = Notification.Name("activationRequired")
    static let digitizationFinished = Notification.Name("digitizationFinished")
}

/**
 Class to maintain the SDK enrollment and initialization state and to notify the progress.
 */
public class InternalNotifications {
    
    private let actionCardEnrollmentUpdate: String = "com.thalesgroup.tshpaysample.enrollmentupdate"
    private let actionInitStateUpdate: String = "com.thalesgroup.tshpaysample.initstateupdate"
        
    public private(set)var initSuccessful: Bool

    var cardInformation: String
    var enrollmentState: TshEnrollmentState?
    var tokenizedCardId: String?
    
    /**
     Creates a new instance.
     */
    public init() {
        self.cardInformation = "Hello World!"
        self.initSuccessful = false
        self.enrollmentState = .inactive
    }

    //MARK: public API

    /**
     Updates the SDK initialization state and notifies about the progress.
     */
    public func updateInitState(_ state: TshInitState, _ error: Error?) {
        AppLoggerHelper.log(.info, "\(InternalNotifications.typeName) updateInitState: \(state)", nil)
        if (state == TshInitState.initSuccessful) {
            CardListHelper.init().getAllCards { digitalizedCard, error in
                if (digitalizedCard != nil) {
                    self.cardInformation = Bundle.main.localizedString(forKey:"card_count", value:nil, table: nil) + String(digitalizedCard!.count)
                }
            }
            initSuccessful = true
        } else {
            initSuccessful = false
        }
        
        NotificationCenter.default.post(name: .sdkStateUpdate, object: initSuccessful)
    }
    
    /**
     Updates the SDK enrollment state and notifies about the progress.
     */
    public func updateEnrollmentState(_ enrollmentState: TshEnrollmentState, _ errorMessage: String?) {
        AppLoggerHelper.log(.info, "\(InternalNotifications.typeName) updateEnrollmentState: \(enrollmentState)", nil)
        self.enrollmentState = enrollmentState
        if (errorMessage != nil) {
            let notificationData = NotificationData(title: "Enrollment status", detail: errorMessage!, type: .Error)
            NotificationCenter.default.post(name: .updateEnrollmentState, object: self.enrollmentState, userInfo: notificationData.dictionary)
        } else {
            NotificationCenter.default.post(name: .updateEnrollmentState, object: self.enrollmentState)
        }
    }
    
    /**
     FCM notification a new card added to list check list of the cards
     */
    public func updateListOfCards(_ tokenizedCardId: String) {
        self.tokenizedCardId = tokenizedCardId
        AppLoggerHelper.log(.info, "\(InternalNotifications.typeName) updateListOfCards", nil)
        NotificationCenter.default.post(name: .updateListOfCards, object: self.tokenizedCardId)
    }
    
    /**
     FCM notification a new transaction
     */
    public func updateTransactionHistory(_ tokenizedCardId: String) {
        self.tokenizedCardId = tokenizedCardId
        AppLoggerHelper.log(.info, "\(InternalNotifications.typeName) updateTransactionHistory", nil)
        NotificationCenter.default.post(name: .updateTransactionHistory, object: self.tokenizedCardId)
    }

        
    //MARK: private API
    
    private static var typeName: String {
        return String(describing: self)
    }
}
