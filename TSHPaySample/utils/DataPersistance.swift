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
