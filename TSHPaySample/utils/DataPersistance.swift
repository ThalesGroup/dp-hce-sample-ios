//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

public class DataPersistance {
    
    public static func getPanExpiration(panSuffix: String) -> String {
        if let panExpiry = UserDefaults.standard.string(forKey: panSuffix) {
            if (!panExpiry.isEmpty) {
                return panExpiry
            }
        }
        return Bundle.main.localizedString(forKey:"empty_pan_expiration", value:nil, table: nil)
    }
    
    public static func savePanExpiration(_ panExpiration: String, panSuffix: String) {
        UserDefaults.standard.set(panExpiration, forKey: panSuffix)
    }
    
    public static func getBackgroundImage(tokenizedCardId: String) -> Data? {
        if let backgroundImage = UserDefaults.standard.data(forKey: tokenizedCardId) {
            if (!backgroundImage.isEmpty) {
                return backgroundImage
            }
        }
        return nil
    }
    
    public static func saveBackgroundImage(_ backgroundImage: Data, tokenizedCardId: String) {
        UserDefaults.standard.set(backgroundImage, forKey: tokenizedCardId)
    }
}
