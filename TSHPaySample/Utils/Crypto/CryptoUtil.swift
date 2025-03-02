//
// Copyright © 2004 THALES. All rights reserved.
//

import Foundation
import OpenSSL

class CryptoUtil {
    
    @inline(__always) static func encryptDataWithPKCS7(_ data: Data, pubKey: Data) -> Data? {
        let output = encryptPKCS7(dataToUnsignedCharPointer(data: data), Int32(data.count),
                                  dataToUnsignedCharPointer(data: pubKey), Int32(pubKey.count))
        
        var retValue: Data? = nil
        if output.length > 0, let value = output.value {
            retValue = Data(bytes: value, count: output.length).base64EncodedData()
            value.deallocate()
        }
        
        return retValue
    }
    
    @inline(__always) static private func dataToUnsignedCharPointer(data: Data) -> UnsafePointer<UInt8> {
        return data.withUnsafeBytes { rawPointer in
             rawPointer.bindMemory(to: UInt8.self).baseAddress!
        }
    }
}
