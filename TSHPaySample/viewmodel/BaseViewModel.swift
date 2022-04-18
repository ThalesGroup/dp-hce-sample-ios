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
