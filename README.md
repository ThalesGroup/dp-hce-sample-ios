# TSH Pay SDK Sample iOS application

Sample application to show the integration of TSH Pay SDK in to an iOS application. This serves not only as a guide but also 
as a ready made solution if code needs to be transferred 1:1 to client applications.

# Getting started

*Note: Thales SDK support team will supply all config files directly via email.*
The following files need to be added to the project:

## TLDR files to add:

```bash
.
TSH Pay Delivery
├── GoogleService-Info.plist
├── TSHPayPreProd.plist
├── TSHPayQA1.plist [optional]
└── TSH SDK Binaries
```

## TSH Pay Backend + Sample Configuration

The `TSHPay<environment>.plist` file which holds the TSH backend configuration needs to be added to the project as well as sample app related config like card PAN etc...
**`TSHPay<environment>.plist`**

```bash
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GATEWAY_URL</key>
    <string></string>
    <key>CPS_URL</key>
    <string></string>
    <key>MG_CONNECTION_URL</key>
    <string></string>
    <key>TRANSACTION_HISTORY_CONNECTION_URL</key>
    <string></string>
    <key>MG_WALLET_PROVIDER_ID</key>
    <string></string>
    <key>MG_WALLET_APPLICATION_ID</key>
    <string></string>
    <key>OAUTH_CONSUMER_KEY</key>
    <string></string>
    <key>REALM</key>
    <string></string>
    <key>CSR_DOMAIN</key>
    <string></string>
    <key>CSR_EMAIL</key>
    <string></string>
    <key>SECURE_LOG_LEVEL</key>
    <integer></integer>
    <key>SAMPLE_KEY_IDENTIFIER</key>
    <string></string>
    <key>SAMPLE_PUBLIC_KEY</key>
    <string></string>
    <key>SAMPLE_CARD_PAN</key>
    <string></string>
    <key>SAMPLE_CARD_EXP</key>
    <string></string>
    <key>SAMPLE_CARD_CVV</key>
    <string></string>
</dict>
</plist>
```

## TSH SDK Binaries

This sample application was tested with **TSH Pay SDK version 7.0**. TSH Pay SDK binaries need to be placed in to the following location.

```bash
Libs/
└── TSHPaySDK
    ├── Debug
    │   ├── package.json  
    │   ├── TSHPaySDK-Debug.podspec  
    │   └── TSHPaySDK.xcframework 
    ├── Release
    │   ├── package.json  
    │   ├── TSHPaySDK-Release.podspec  
    │   └── TSHPaySDK.xcframework
    └── SecureLogAPI
        ├── package.json  
        ├── SecureLogAPI.podspec  
        └── SecureLogAPI.xcframework   
```

The TSH Pay SDK binaries are wrapped in to [Pods](https://cocoapods.org/) to differentiate between the Debug and Release version of the SDK.
**`Podfile`**

```bash
target 'Templates' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  # Local pods with Thales SDK.
  pod 'SecureLogAPI', :path => './Libs/TSHPaySDK/SecureLogAPI'
  pod 'TSHPaySDK-Debug', :path => './Libs/TSHPaySDK/Debug', :configurations => ['Debug']
  pod 'TSHPaySDK-Release', :path => './Libs/TSHPaySDK/Release', :configurations => ['Release']
end
```

# Entitlements

In order to perform any NFC payment some entitlements are needed.

* com.apple.developer.nfc.hce

* com.apple.developer.nfc.hce.default-contactless-app

* com.apple.developer.nfc.hce.iso7816.select-identifier-prefixes
  
  * 325041592E5359532E4444463031 - PPSE 

Notice, that Apple require to have PPSE in the AID filter for all the options. Otherwise the paymail will fail directly on the OS level.

Follow apple documentation for mor details: [HCE-based contactless NFC transactions](https://developer.apple.com/support/hce-transactions-in-apps/)

# CocoaPods

Install CocoaPods:

```bash
>> pod install
```

## Build and run project

After all of the configurations have been updated, the generated xcworkspace can be opened and build using Xcode.

# Project structure

The sample application is divided in to multiple folders.

```bash
.
├── Data
├── Models
├── Utils
│   └── Crypto
└── Views
    ├── ViewElements
    └── VirtualCard
```

* Data - Simple data structure without dedicated logic.

* Models - All SDK and app related logic.

* Utils\Crypto - Example of encrypted card data calculation for yellow flow and generic helpers.

* Views - SwiftUI visual elements. 

* TSHPaySample.xcodeproj - Main application project.

* ## Documentation
  
  [TSH Pay Developer portal](https://thales-dis-dbp.stoplight.io/docs/tsh-hce-ios/d6a8ba3f3c186-welcome-to-thales-tsh-pay-documentation)
  
  ## Contributing
  
  If you are interested in contributing to the D1 SDK Sample iOS application, start by reading the [Contributing guide](/CONTRIBUTING.md).
  
  ## License
  
  [LICENSE](/LICENSE)
