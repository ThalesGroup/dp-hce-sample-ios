//
// Copyright © 2024 THALES. All rights reserved.
//

import Foundation

enum Targets {
    case qa1, preprod
}

struct ServerEnvironment {
    
    // MARK: - Class lifecycle
    
    private let target: Targets
    
    let keyIdentifier: String
    let publicKey: String
    let sampleCardPan: String
    let sampleCardExp: String
    let sampleCardCvv: String
    let simulatorTeamId: String

    init(_ val: Targets) {
        if let path = Bundle.main.path(forResource: ServerEnvironment.getConfigPlistName(val), ofType: "plist"), let config = NSDictionary(contentsOfFile: path)  {
            target = val
            keyIdentifier = ServerEnvironment.readProperty(dictionary: config, key: "SAMPLE_KEY_IDENTIFIER")
            publicKey = ServerEnvironment.readProperty(dictionary: config, key: "SAMPLE_PUBLIC_KEY")
            sampleCardPan = ServerEnvironment.readProperty(dictionary: config, key: "SAMPLE_CARD_PAN")
            sampleCardExp = ServerEnvironment.readProperty(dictionary: config, key: "SAMPLE_CARD_EXP")
            sampleCardCvv = ServerEnvironment.readProperty(dictionary: config, key: "SAMPLE_CARD_CVV")
            simulatorTeamId = ServerEnvironment.readProperty(dictionary: config, key: "SIMULATOR_TEAM_ID")
        } else {
            fatalError("Failed to initialise environment object.")
        }
    }
    
    // MARK: - Public API
    
    public func getConfigurationName() -> String {
        switch target {
        case .qa1:
            return "QA 1"
        case .preprod:
            return "Pre production"
        }
    }
    
    public func getConfigPlistName() -> String {
        return ServerEnvironment.getConfigPlistName(target)
    }
    
    
    // MARK: - Private API
    
    private static func getConfigPlistName(_ val: Targets) -> String {
        switch val {
        case .qa1:
            return "TSHPayQA1"
        case .preprod:
            return "TSHPayPreProd"
        }
    }
    
    private static func readProperty<T>(dictionary: NSDictionary, key: String) -> T {
        if let value: T = dictionary.object(forKey: key) as? T {
            return value
        }
        
        fatalError("Mandatory configuration parameter missing: \(key)")
    }
}
