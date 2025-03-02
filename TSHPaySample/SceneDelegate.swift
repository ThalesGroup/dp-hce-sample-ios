//
// Copyright © 2024 THALES. All rights reserved.
//

import UIKit
import CoreNFC

class SceneDelegate: PaymentModel, UIWindowSceneDelegate {
    
}

// MARK: - NFCWindowSceneDelegate
extension SceneDelegate: NFCWindowSceneDelegate {
  
    /*
     Informs your app that the system has received an NFC-related event. - https://developer.apple.com/documentation/corenfc/nfcwindowscenedelegate/4319273-windowscene
     */
    func windowScene(_ windowScene: UIWindowScene, didReceiveNFCWindowSceneEvent event: NFCWindowSceneEvent) {
        switch event {
        case .presentation:
            //The user performed a gesture to present an NFC display.
            startContactlessPayment()
            break
        case .readerDetected:
            //The eligible device detected the RF field of an NFC reader.
            handleFieldDetect()
            break
        @unknown default: break
        }
    }
}
