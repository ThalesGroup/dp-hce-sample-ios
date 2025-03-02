//
//  Copyright © 2024 Thales. All rights reserved.
//
import Foundation
import CoreNFC

@available(iOS 17.4, *)
class PresentmentIntentAssertion {
    
    static var presentmentIntent: NFCPresentmentIntentAssertion?
    
    // Hold a presentment intent assertion reference to prevent the
    // default contactless app from launching. In a real app, monitor
    // presentmentIntent.isValid to ensure the assertion remains active.
    static func acquire() async throws {
        presentmentIntent = try await NFCPresentmentIntentAssertion.acquire()
    }
    
    static func isValid() -> Bool {
        guard let presentmentIntent else {
            return false
        }
        return presentmentIntent.isValid
    }
}
