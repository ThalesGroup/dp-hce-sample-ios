require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "TSHPaySDK-Release"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "16.0" }
  s.source       = { :git => "https://www.thalesgroup.com.git", :tag => "#{s.version}" }

  s.ios.vendored_framework = 'TSHPaySDK.xcframework'
end
