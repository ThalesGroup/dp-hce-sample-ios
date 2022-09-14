//
// Copyright © 2021-2022 THALES. All rights reserved.
//  

import Foundation

struct PushNotification: Codable {
    
    var contents: [String: String] = [:]
}

extension PushNotification: Sequence {
    // 1
    typealias Iterator = DictionaryIterator<String, String>
    
    // 2
    func makeIterator() -> Iterator {
      // 3
      return contents.makeIterator()
    }
}
