//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

/**
 Base ViewModel.
 */
class BaseViewModel: ObservableObject {
    var notificationData: NotificationData?
    @Published var isNotifcationVisible: Bool = false

    /**
     Notifies the UI that an error occured.
     
     @param error Error.
     */
    func notifyError(error: Error) {
        let title = error.localizedDescription
        let detail = error.localizedDescription
        let type = NotificationType.Error
        
        self.notificationData = NotificationData(title: title, detail: detail, type: type)
        self.isNotifcationVisible = true
    }
    
    /**
     Notifies the UI that an error occured.
     
     @param title Title of error.
     @param detail Detail of error.
     */
    func notifyCustomError(title: String, detail: String) {
        let type = NotificationType.Error
        
        self.notificationData = NotificationData(title: title, detail: detail, type: type)
        self.isNotifcationVisible = true
    }
}
