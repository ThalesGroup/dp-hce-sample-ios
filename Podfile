projectName = 'TSHPaySample'
platform :ios, '16.0'

target projectName do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Local pods with Thales SDK.
  pod 'SecureLogAPI', :path => './Libs/TSHPaySDK/SecureLogAPI'
  pod 'TSHPaySDK-Debug', :path => './Libs/TSHPaySDK/Debug', :configurations => ['Debug']
  pod 'TSHPaySDK-Release', :path => './Libs/TSHPaySDK/Release', :configurations => ['Release']

  # FCM Push notification support. Required for many SDK operations.
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'

  # Used for manual entry during yellow flow.
  pod 'OpenSSL-Universal'

end

# Update cocoa pods deployment target to the same as the main app.
# Follow some currently recommended settings by Apple.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
#      config.build_settings['ENABLE_MODULE_VERIFIER'] = 'true'
#      config.build_settings['MODULE_VERIFIER_SUPPORTED_LANGUAGES'] = 'objective-c,c'
    end
  end
end

# Allow input / output operation so the pods can actually copy the frameworks.
project = Xcodeproj::Project.open('./' + projectName + '.xcodeproj')
project.targets.each do |target|
  if target.name == projectName 
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'false'
    end
  end
end
project.save
