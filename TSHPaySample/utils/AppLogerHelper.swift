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
import os.log

public class AppLoggerHelper {

    public static func log(_ osLogType: OSLogType, _ prefix: String, _ item: String?) {
        #if DEBUG
            printLog(osLogType, prefix, item)
        #else
            if (osLogType == OSLogType.error) || (osLogType == OSLogType.fault) {
                AppLoggerHelper.printLog(osLogType, prefix, item)
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
