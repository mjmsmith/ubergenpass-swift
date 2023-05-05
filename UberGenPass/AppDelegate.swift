import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    if #available(iOS 13, *) {
        window?.overrideUserInterfaceStyle = .light
    }

    // Register defaults.
    
    let dict = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "UserDefaults", ofType:"plist")!)
    
    UserDefaults.standard.register(defaults: dict as! Dictionary)

    // Update version.
    
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let defaultsVersion = UserDefaults.standard.string(forKey: Constants.AppVersionDefaultsKey) as String?

    if (currentVersion != defaultsVersion) {
      self.versionUpdatedFrom(defaultsVersion: defaultsVersion, to:currentVersion)
    }
    
    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Strip off our scheme prefix to get the real URL.
    
    let urlTypes = Bundle.main.infoDictionary!["CFBundleURLTypes"] as! NSArray
    let urlType = urlTypes[0] as! NSDictionary
    let urlSchemes = urlType["CFBundleURLSchemes"] as! NSArray
    let urlScheme = urlSchemes[0] as! NSString
    
    var url = (url.absoluteString as NSString).substring(from: urlScheme.length+1)
    
    if url.hasPrefix("//") {
      url = (url as NSString).substring(from: 2)
    }
    
    // Ignore about: URLs.
    
    if (!url.hasPrefix("about:")) {
      let mainViewController = self.window!.rootViewController as! MainViewController
      
      mainViewController.site = url
    }
        
    return true
  }
  
  // MARK: Private
  
  private func versionUpdatedFrom(defaultsVersion: String?, to currentVersion: String) {
    // If we have no previous version, remove keychain items in case this is a reinstall.
    
    if defaultsVersion == nil {
      DefaultKeychain[.Hash] = nil
      DefaultKeychain[.Secret] = nil
      DefaultKeychain[.RecentSites] = nil
    }

    UserDefaults.standard.set(currentVersion, forKey: Constants.AppVersionDefaultsKey)
    UserDefaults.standard.synchronize()
  }
}

