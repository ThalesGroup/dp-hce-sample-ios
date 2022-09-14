//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation
import SwiftUI

struct NotificationData {
    var title:String
    var detail:String
    var type: NotificationType
    
    var dictionary: [String: Any] {
        return ["title": title,
                "detail": detail,
                "type": type]
    }
}

enum NotificationType {
    case Info
    case Warning
    case Success
    case Error
    
    var tintColor: Color {
        switch self {
        case .Info:
            return Color(red: 67/255, green: 154/255, blue: 215/255)
        case .Success:
            return Color.green
        case .Warning:
            return Color.yellow
        case .Error:
            return Color.red
        }
    }
}
