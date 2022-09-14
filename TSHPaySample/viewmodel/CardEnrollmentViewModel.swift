//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

/**
 ViewModel to to handle the card enrollment.
 */
class CardEnrollmentViewModel: BaseViewModel {
    
    @Published var enrollmentState: TshEnrollmentState = .inactive
    
    var selectedIdvMethod: String = ""

    private(set) var idvMethodSelector: IDVMethodSelector?
    private(set) var termsAndConditions: TermsAndConditions?
    private(set) var pendingCardActivation: PendingCardActivation?
    private(set) var digitalCardId: String?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateEnrollmentState(_:)), name: .updateEnrollmentState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedTermsAndConditions(_:)), name: .receivedTermsAndConditions, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedIdvMethodSelector(_:)), name: .receivedIdvMethodSelector, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.activationRequired(_:)), name: .activationRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.digitizationFinished(_:)), name: .digitizationFinished, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: public API
    
    /**
     Enrolls the payment card.
     
     @param pan PAN.
     @param expiryData Expiry Date.
     @param cvv CVV.
     */
    public func enrollCard(_ pan: String, expiryDate: String, cvv: String) {
        self.enrollmentState = .inactive
        self.idvMethodSelector = nil
        self.termsAndConditions = nil
        self.pendingCardActivation = nil
        
        self.selectedIdvMethod = ""
        
        SdkHelper.shared().tshEnrollment?.enrollCard(pan, expiryDate: expiryDate, cvv: cvv)
    }
    
    /**
     Retrieves pending card state

     @param pendingCardActivation Pending Card Activation.
     */
    public func getPendingCardActivationState(_ pendingCardActivation: PendingCardActivation) -> PendingCardActivationState? {
        switch (pendingCardActivation.getState()) {
            case PendingCardActivationState.IDV_METHOD_NOT_SELECTED:
                return PendingCardActivationState.IDV_METHOD_NOT_SELECTED
            case PendingCardActivationState.OTP_NEEDED:
                self.pendingCardActivation = pendingCardActivation
                return PendingCardActivationState.OTP_NEEDED
            case PendingCardActivationState.WEB_3DS_NEEDED:
                AppLoggerHelper.log(.info, "\(CardEnrollmentViewModel.typeName) proceedPendingCardActivation", "Not in the scope of sample app")
                return nil
            default:
                AppLoggerHelper.log(.info, "\(CardEnrollmentViewModel.typeName) proceedPendingCardActivation", "Activation state not handled \(String(describing: pendingCardActivation.getState))")
                return nil
        }
    }
    
    /**
     Continue enrolls the payment card (IDVSelection / IDVCode)
     
     @param pendingCardActivation Pending Card Activation.
     */
    public func proceedPendingCardActivationIDVSelection(_ pendingCardActivation: PendingCardActivation) {
        pendingCardActivation.invokeIdvSelection(SdkHelper.shared().tshEnrollment!.getMGDigitizationDelegate())
    }

    
    /**
     Accpets the Terms and Conditions.
     */
    public func acceptTermsAndCondition() {
        SdkHelper.shared().tshEnrollment?.acceptTermsCondition(self.termsAndConditions)
        self.termsAndConditions = nil
    }
    
    /**
     Rejects the Terms and Conditions.
     */
    public func disagreeTermsAndCondition() {
        self.termsAndConditions = nil
    }

    /**
     Selects the Identification and Verification method.
     */
    public func selectIdv() {
        SdkHelper.shared().tshEnrollment?.selectIdv(idvMethodSelector, self.getIdvId())
    }
    
    /**
     Cancels the selections of the Identification and Verification method.
     */
    public func cancelIdvSelection() {
        self.idvMethodSelector = nil
    }
    
    /**
     Submits the activation code.
     
     @param otp Activation code.
     */
    public func submitActivationCode(_ otp: ContiguousArray<CChar>) {
        SdkHelper.shared().tshEnrollment?.submitActivationCode(otp, pendingCardActivation: pendingCardActivation)
    }
    
    /**
     Cancels the submission of the activation code.
     */
    public func cancelActivationCode() {
        self.pendingCardActivation = nil
    }

    /**
     Lists the available Identification and Verificatin methods.
     
     @return List of available Identificatin and Verification methods and the pre selected method.
     */
    public func listIdvMethods() -> (idvMethods: [String], preSelectedIdvMethod: String) {
        var idvArray = [String]()
        var idvPreSelected = String()
        var idvString: String
        if (self.idvMethodSelector != nil && self.idvMethodSelector?.getIdvMethodList() != nil) {
            for idvM:Any in self.idvMethodSelector!.getIdvMethodList()! {
                idvString = (idvM as AnyObject).getType()!
                if (self.selectedIdvMethod.isEmpty) {
                    self.selectedIdvMethod = idvString
                }
                idvArray.append(Bundle.main.localizedString(forKey:"idv_method_prefix", value:nil, table: nil) + idvString)
                if (idvPreSelected.isEmpty) {
                    idvPreSelected = Bundle.main.localizedString(forKey:"idv_method_prefix", value:nil, table: nil) + idvString
                }
            }
        }
        return (idvArray, idvPreSelected)
    }
    
    //MARK: private API

    private func getIdvId() -> String {
        var idvString: String
        if (self.idvMethodSelector != nil && self.idvMethodSelector?.getIdvMethodList() != nil) {
            for idvM:Any in self.idvMethodSelector!.getIdvMethodList()! {
                idvString = (idvM as! IDVMethod).getType()!
                if (selectedIdvMethod.contains(idvString)) {
                    return (idvM as! IDVMethod).getId()!
                }
            }
        }
        return String(-1)
    }
        
    //MARK: notifications
    
    /**
        Receives notifications on TSH SDK state updates.
     
        @param notification Notification.
     */
    @objc func updateEnrollmentState(_ notification: Notification) {
        if let enrollmentState = notification.object as? TshEnrollmentState {
            self.enrollmentState = enrollmentState
            if (self.enrollmentState == .eligibilityCheckError || self.enrollmentState == .digitizationError || self.enrollmentState == .wseCheckError) {
                guard let info = notification.userInfo else {
                    return
                }                
                let title = info["title"] as? String
                let detail = info["detail"] as? String
                let type = info["type"] as? NotificationType
                
                notificationData = NotificationData(title: title!, detail: detail!, type: type!)
                isNotifcationVisible = true
            }
        }
    }
    
    /**
        Receives TermsAndConditions object via notification.
     
        @param notification Notification.
     */
    @objc func receivedTermsAndConditions(_ notification: Notification) {
        if let termsAndConditions = notification.object as? TermsAndConditions {
            self.termsAndConditions = termsAndConditions
        }
    }
    
    /**
        Receives IDVMethodSelector object via notification.
     
        @param notification Notification.
     */
    @objc func receivedIdvMethodSelector(_ notification: Notification) {
        if let idvMethodSelector = notification.object as? IDVMethodSelector {
            self.idvMethodSelector = idvMethodSelector
        }
    }
    
    /**
        Receives IDVMethodSelector object via notification.
     
        @param notification Notification.
     */
    @objc func activationRequired(_ notification: Notification) {
        if let pendingCardActivation = notification.object as? PendingCardActivation {
            self.pendingCardActivation = pendingCardActivation
        }
    }
    
    /**
        Receives IDVMethodSelector object via notification.
     
        @param notification Notification.
     */
    @objc func digitizationFinished(_ notification: Notification) {
        if let digitalCardId = notification.object as? String {
            self.digitalCardId = digitalCardId
        }
    }
    
    private static var typeName: String {
        return String(describing: self)
    }
}
