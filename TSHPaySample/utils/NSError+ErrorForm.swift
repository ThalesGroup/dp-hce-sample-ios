//
// Copyright © 2021-2022 THALES. All rights reserved.
//  

import Foundation

public extension NSError {

    class var defaultErrorDomain: String { return Bundle.main.bundleIdentifier ?? "TSHPaySample" }
    class var defaultErrorCode: Int { return 999 }
    
    class func make(localizedMessage: String) -> NSError {
        return NSError(
            domain: defaultErrorDomain,
            code: defaultErrorCode,
            userInfo: [NSLocalizedDescriptionKey: localizedMessage, NSLocalizedFailureReasonErrorKey: localizedMessage]
        )
    }
}
