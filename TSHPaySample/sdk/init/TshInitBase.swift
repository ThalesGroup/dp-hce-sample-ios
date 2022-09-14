//
// Copyright © 2021-2022 THALES. All rights reserved.
//
  
import Foundation
import TSHPaySDK

/**
 Class responsible for the initialization of the SDK.
 */
public class TshInitBase: NSObject {

    private static let initDelayMS: Double = 700
    private static let initRetrayDelayMS: Double = 2500
    private static let initAttempts: Int = 3
    
    private var initAttemptCount = 0
    private var initState:TshInitState = TshInitState.inactive
    private var initError: Error?
    private weak var sdkControllerDelegate: SDKControllerDelegate?
    public let internalNotifications: InternalNotifications
    private var walletSecureEnrollmentDelegate: WalletSecureEnrollmentDelegate?
    
    /**
     Creates a new instance and starts the initialization of the SDK.
     */
    public override init() {
        self.internalNotifications = InternalNotifications()
        super.init()
        self.sdkControllerDelegate = self
        initCpsSdk()
    }
    
    //MARK: public API

    /**
     Retrieves the MobileGateway component configuration state.
     
     @return Configuration state of the MobileGateway component.
     */
    public func getMgSdkState() -> MGSDKConfigurationState {
        var error: NSError?
        let mgSDKConfigurationState = MobileGatewayManager.sharedInstance().getConfigurationStateWithError(&error)
        if (error != nil) {
            AppLoggerHelper.log(.error, "\(TshInitBase.typeName) getMgSdkState", "errorDomain: \(String(describing: error?.domain)) errorCode: \(String(describing: error?.code)) errorUserInfo: \(String(describing: error?.userInfo))")
            return MGSDKConfigurationState.NOT_CONFIGURED
        }
        
        return mgSDKConfigurationState
    }
    
    public func performWseIfNeeded(_ callback: @escaping (_ isSuccess: Bool, _ error: Error?) -> Void) {
        guard let walletSecureEnrollmentBusinessService: WalletSecureEnrollmentBusinessService =
                ProvisioningServiceManager.sharedInstance().getWalletSecureEnrollmentBusinessService() else {
                    callback(false, NSError.make(localizedMessage: "Cannot retrieve WalletSecureEnrollmentBusinessService."))
            return
        }
        
        let walletSecureEnrollmentState: WalletSecureEnrollmentState = walletSecureEnrollmentBusinessService.getState()
        switch walletSecureEnrollmentState {
        case .WSE_COMPLETED, .WSE_NOT_REQUIRED:
            callback(true, nil)
            break
        case .WSE_STARTED:
            // WSE was triggered during this instance. Simple wait for the first one to finish.
            break
        case .WSE_REQUIRED:
            //Start Wallet Secure Enrollment
            self.walletSecureEnrollmentDelegate = WalletSecureEnrollmentDelegateImpl.init(callback)
            walletSecureEnrollmentBusinessService.startWalletSecureEnrollment(with: walletSecureEnrollmentDelegate!)
            break
        @unknown default:
            fatalError()
        }
    }
    
    //MARK: private API
    
    /**
     Initializes the CPS component.
     */
    private func initCpsSdk() {
        initAttemptCount += 1
        SDKController.shared().initialize(with: .userPresence, delegate: self.sdkControllerDelegate!)
    }
    
    /**
     Initializes the MobileGateway component.
     */
    private func initMgSdk() {
        // Avoid multiple init.
        if (getMgSdkState() != MGSDKConfigurationState.NOT_CONFIGURED) {
            updateState(TshInitState.initFailed, NSError.make(localizedMessage: "mg_error_sdk_already_init"))
            return;
        }
        
        // Configure MG configuration
        let mgConfig = ConnectionConfigurationBuilder().setConnectionParameters(SdkConstants.mgConnectionUrl, withTimeout: Int32(SdkConstants.mgConnectionTimeout), withReadTimeout: Int32(SdkConstants.mgConnectionReadTimeout))?
            .setRetryParameters(Int32(SdkConstants.mgConnectionRetryCount), withInterval: Int32(SdkConstants.mgConnectionReadInterval))?.build()
        
        // Configure wallet configuration
        let mgWalletConfiguration = WalletBuilder().setWalletParameters(SdkConstants.walletProviderId, walletApplicationId: SdkConstants.walletApplicationId)?.build()
        
        // Configure Transaction History
        let mgTransactionConfiguration = TransactionHistoryBuilder().setConnectionParameters(SdkConstants.mgTransactionHistoryConnectionUrl)?.build()
        let mgManager = MobileGatewayManager.sharedInstance()
        do {
            try mgManager.configure(with: [mgConfig!, mgWalletConfiguration!, mgTransactionConfiguration!])
            updateState(TshInitState.initSuccessful)
        } catch {
            updateState(TshInitState.initFailed, error)
        }
    }
    
    /**
     Updates the state of the SDK.
     
     @param state Initialization state of the SDK
     */
    private func updateState(_ state: TshInitState) {
        // Wallet secure enrollment is expensive task and so we are calling in only when it's
        // necessary. During SDK init it's required only in case of migration when
        // we already have some tokens enrolled. Otherwise it will be done during initial
        // card enrollment.
        let enrollingBusinessService = ProvisioningServiceManager.sharedInstance().getEnrollingBusinessService()
        if (state == TshInitState.initSuccessful && enrollingBusinessService?.isEnrolled == EnrollmentStatus.ENROLLMENT_COMPLETED) {
            performWseIfNeeded { isSuccess, error in
                if(isSuccess) {
                    self.updateState(state, error)
                } else {
                    self.updateState(.initFailed, error)
                }
            }
        } else {
            updateState(state, nil)
        }
    }
    
    /**
     Updates the state of the SDK.
     
     @param state Initialization state of the SDK
     @param error Error during initialization or nil if no error.
     */
    func updateState(_ state: TshInitState, _ error: Error?) {
        initState = state
        initError = error
        internalNotifications.updateInitState(initState, initError)
    }

    private static var typeName: String {
        return String(describing: self)
    }
}

//MARK: SDKControllerDelegate API

extension TshInitBase: SDKControllerDelegate {
    
    public func onSetupComplete() {
        AppLoggerHelper.log(.info, "\(TshInitBase.typeName) CPS SDK onSetupComplete", nil)
        updateState(TshInitState.initInProgress)
        let when = DispatchTime.now() + TshInitBase.initDelayMS/1000
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.initMgSdk()
        }
    }

    public func onSetupError(_ error: Error)  {
        AppLoggerHelper.log(.error, "\(TshInitBase.typeName) onSetupError", "error: \(error.localizedDescription)")

        // Update data layer and notify UI.
        updateState(TshInitState.initFailed, error)
    
        if (initAttemptCount < TshInitBase.initAttempts) {
            SDKController.shared().resetSDKStorage { error in
                if(error != nil) {
                    AppLoggerHelper.log(.error, "\(TshInitBase.typeName) onSetupError CPS resetSDKStorage", "error: \(error!.localizedDescription)")
                    return
                } else {
                    MobileGatewayManager.sharedInstance().resetSDKStorage { error in
                        if error == nil {
                            let when = DispatchTime.now() + TshInitBase.initRetrayDelayMS/1000
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.initCpsSdk()
                                self.initMgSdk()
                            }
                        } else {
                            // Handle the error
                            AppLoggerHelper.log(.error, "\(TshInitBase.typeName) onSetupError MG resetSDKStorage", "error: \(error!)")
                            return
                        }
                    }
                }
            }
        }
    }
}

//MARK: WalletSecureEnrollmentDelegate API

private class WalletSecureEnrollmentDelegateImpl: NSObject, WalletSecureEnrollmentDelegate {
    var callback: (_ isSuccess: Bool, _ error: Error?) -> Void = {isSuccess,error in }

    init(_ callback: @escaping (_ isSuccess: Bool, _ error: Error?) -> Void) {
        self.callback = callback
    }
    
    public func onProgressUpdate(_ state: WalletSecureEnrollmentState) {
        if (state == .WSE_COMPLETED) {
            self.callback(true, nil)
        }
    }
    
    public func onError(_ error: WalletSecureEnrollmentError) {
        self.callback(false, NSError.make(localizedMessage: error.errorMessage ?? "Unknow error during Wallet Secure Enrollment."))
    }
}
