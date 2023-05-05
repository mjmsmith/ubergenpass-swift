ios_version = '12.0'

source 'https://cdn.cocoapods.org/'
platform :ios, ios_version
use_frameworks!

target 'UberGenPass' do
  pod 'KeychainAccess', '~> 4.0'
end

# See https://stackoverflow.com/a/62526546/81434

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if Gem::Version.new(ios_version) > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = ios_version
      end
    end
  end
end