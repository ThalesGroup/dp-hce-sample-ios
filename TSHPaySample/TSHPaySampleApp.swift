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

import SwiftUI
import UserNotifications

import Firebase
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var sdkHelper: SdkHelper?
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
      return self.orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        sdkHelper = SdkHelper.shared()
        
        #if DEBUG
            FirebaseConfiguration.shared.setLoggerLevel(.max)
        #else
            FirebaseConfiguration.shared.setLoggerLevel(.min)
        #endif
        
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        Task {
            let granted = await requestAuthorizationForNotifications()
            if granted {
                application.registerForRemoteNotifications()
            } else {
                AppLoggerHelper.log(.info, "UIApplicationDelegate requestAuthorizationForNotifications", Bundle.main.localizedString(forKey:"register_fcm", value:nil, table: nil))
            }
        }

        return true
    }
    
    // Because swizzling is disabled then this function must be implemented so that the APNs token can be paired to the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppLoggerHelper.log(.info, "UIApplicationDelegate didRegisterForRemoteNotificationsWithDeviceToken", "APNs token retrieved: \(deviceToken)")
        sdkHelper?.tshPush?.fcmService?.onNewToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLoggerHelper.log(.error, "UIApplicationDelegate didFailToRegisterForRemoteNotificationsWithError", "error: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Print full message.
        AppLoggerHelper.log(.info, "UIApplicationDelegate didReceiveRemoteNotification", "UserInfo \(userInfo)")
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    private func requestAuthorizationForNotifications() async -> Bool {
        let notificationCenter = UNUserNotificationCenter.current()
        let authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let authorizationGranted = try await notificationCenter.requestAuthorization(options: authorizationOptions)
            return authorizationGranted
        } catch {
            AppLoggerHelper.log(.error, "\(AppDelegate.typeName) localizedDescription: \(error.localizedDescription)", "error: \(error);")
        }
        return false
    }
    
    private static var typeName: String {
        return String(describing: self)
    }
}

// We are not letting Firebase automatically handle notification code through swizzling so we need conform to UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
     
  //Will be called whenever you receive a notification while the app is in the foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler
                              completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      process(notification)
      completionHandler([[.banner, .sound]])
  }

  //Will be called when a user taps a notification.
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,withCompletionHandler
                              completionHandler: @escaping () -> Void) {
      process(response.notification)
      completionHandler()
  }
    
    private func process(_ notification: UNNotification) {
        if notification.request.content.userInfo["sender"] != nil {
            SdkHelper.shared().tshPush?.onMessageReceived(notification.request.content.userInfo);
        }
    }
}

//Messaging is Firebase’s class that manages everything related to push notifications.
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    let tokenDict = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(name: Notification.Name("TSHPaySample"), object: nil,userInfo: tokenDict)
  }
}

@main
struct TSHPaySampleApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var viewRouter = ViewRouter()
    @StateObject var sdkStateViewModel = SdkStateViewModel()
    
    //MARK: it looks that SWIFTUI doesn't like 0.0 to set blur effect after that start ignoring safeare. This is reason if condition in below code maybe it is bug in SWIFTUI.
    @State var bluerRadius: CGFloat = CGFloat(0.0)

    var body: some Scene {
        WindowGroup {
            if(bluerRadius == CGFloat(0.0)) {
                RootView().environmentObject(sdkStateViewModel).environmentObject(viewRouter)
            } else {
                ZStack {
                    RootView().environmentObject(sdkStateViewModel).environmentObject(viewRouter)
                }.blur(radius: bluerRadius)
            }
        }.onChange(of: scenePhase) { phase in
            switch phase {
                case .inactive:
                    bluerRadius = CGFloat(20.0)
                    break
                case .active:
                    bluerRadius = CGFloat(0.0)
                    break
                case .background:
                    break
                @unknown default: break
            }
        }.onChange(of: sdkStateViewModel.fcmCardOperationNotification) { notification in
            self.viewRouter.notification = notification
            if (self.viewRouter.currentPage != .enrollment) {
                self.viewRouter.currentPage = .cardList
            }
        }
        .onChange(of: sdkStateViewModel.fcmTransactionHistoryDigitialCardIdNotification) { notification in
            self.viewRouter.currentPage = .cardList
        }
    }
}
