//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Screens available in application.
 */
enum Screen {
    case splash
    case cardList
    case payment
    case enrollment
}

/**
 Class to hold and notify the state about the current screen shown and to share data between screens.
 */
class ViewRouter: ObservableObject {
    @Published var currentPage: Screen = .splash
    var notification: FcmCardOperation?
    var pendingCardActivation: PendingCardActivation?
}
