//
// Copyright © 2024 THALES. All rights reserved.
//

import UIKit
import Observation
import TSHPaySDK
import Firebase

let serverEnvironment: ServerEnvironment = ServerEnvironment(.qa1)

class AppDelegate: AppModel, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        initSDK(application, firstAttempt: true)
        return true
    }
      
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        
        processIncomingNotification(userInfo)
        completionHandler(.newData)
    }
        
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self;
        return sceneConfig
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func initSDK(_ application: UIApplication, firstAttempt: Bool) {
        defer {
            Task {
                do {

                 #if targetEnvironment(simulator)
                    if !serverEnvironment.simulatorTeamId.isEmpty {
                        await TSHPay.shared.setTeamID(serverEnvironment.simulatorTeamId)
                    }
                #endif
                                        
                    // Init SDK authentication method that use authentication by Touch ID for any enrolled fingerprints, or Face ID.
                    try await TSHPay.shared.configure(withVerificationMethod: .biometricOnly, plistConfiguration: .custom(named:serverEnvironment.getConfigPlistName()))
                    
                    // Try to perfrom wallet secure enrollment. Pre-requirement for any cryptographic operations.
                    invokeWSEIfNeeded()
                    
                    // Init notifications
                    UNUserNotificationCenter.current().delegate = self
                    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                    application.registerForRemoteNotifications()
                    
                    // Init FCM in main thread.
                    await MainActor.run {
                        FirebaseApp.configure()
                        Messaging.messaging().delegate = self
                    }
                } catch {
                    if let err = error as? TSHPay.Error, err == TSHPaySDK.TSHPay.Error.configurationError && firstAttempt {
                        await resetSDK(application)
                    } else {
                        fatalError("Failed to initialise mandatory stuff. \(error)")
                    }
                }
            }
        }

        // Check for NFC capability.
        if #available(iOS 17.4, *) {
            Task {
                let contactlessPaymentSession = ContactlessPaymentSession()
                do {
                    try await contactlessPaymentSession.requestAuthorization()
                } catch ContactlessPaymentSession.Error.nfcPermissionNotAccepted {
                    toastShow(caption: "Request Authorization", description: "Permission not accepted", type: .warning)
                } catch {
                    toastShow(caption: "Request Authorization", description: "Unexpected error: \(error)", type: .warning)
                }
            }
        } else {
            toastShow(caption: "Request Authorization", description: "OS < 17.4 is not supported", type: .warning)
        }
    }
    
    private func resetSDK(_ application: UIApplication) async {
        //Reset SDK if you change withVerificationMethod in configuration API you need to perform reset operation
        do {
            try await TSHPay.shared.reset()
            initSDK(application, firstAttempt: false)
        } catch {
            toastShow(caption: "ResetError", description: "CPS Reset unsuccessful", type: .error)
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        
        AppLogger.log(.debug, "\(String(describing: self)) - \(#function)", "Firebase registration token: \(fcmToken)")
            
        Task {
            do {
                try await NotificationService().updatePushToken(fcmToken)
            } catch {
                
                // User is not enrolled error is expected before initial enrollment. You can simple ignore this message.
                AppLogger.log(.debug, String(describing: self), "..update token error..\(error)")
            }
        }
    }
}
