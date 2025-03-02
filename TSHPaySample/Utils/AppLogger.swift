//
//  Copyright © 2024 THALES. All rights reserved.
//

import Foundation
import os.log

public class AppLogger {

    public static func log(_ osLogType: OSLogType, _ prefix: String, _ item: String?) {
        #if DEBUG
            printLog(osLogType, prefix, item)
        #else
            if (osLogType == OSLogType.error) || (osLogType == OSLogType.fault) {
                AppLogger.printLog(osLogType, prefix, item)
            }
        #endif
    }
    
    private static func printLog(_ osLogType: OSLogType,_ prefix: String, _ item: String?) {
        let log = OSLog.init(subsystem: Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "com.thalesgroup.tshpaysample",
                              category: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TSHPaySample")
        if (item != nil) {
            os_log("%{public}@", log: log, type: osLogType, "\(prefix) \(item!)")
        } else {
            os_log("%{public}@ ", log: log, type: osLogType, prefix)
        }
    }
}
