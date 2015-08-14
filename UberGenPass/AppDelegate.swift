import Crashlytics
import Fabric
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Crashlytics.
    
    Fabric.with([Crashlytics()])

    // Register defaults.
    
    let dict = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("UserDefaults", ofType:"plist")!)
    
    NSUserDefaults.standardUserDefaults().registerDefaults(dict as! Dictionary)

    // Update version.
    
    let currentVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    let defaultsVersion = NSUserDefaults.standardUserDefaults().stringForKey(Constants.AppVersionDefaultsKey) as String?

    if (currentVersion != defaultsVersion) {
      self.versionUpdatedFrom(defaultsVersion, to:currentVersion)
    }
    
    return true
  }

  func application(app: UIApplication, openURL URL: NSURL, options: [String : AnyObject]) -> Bool {
    // Strip off our scheme prefix to get the real URL.
    
    let urlTypes = NSBundle.mainBundle().infoDictionary!["CFBundleURLTypes"] as! NSArray
    let urlType = urlTypes[0] as! NSDictionary
    let urlSchemes = urlType["CFBundleURLSchemes"] as! NSArray
    let urlScheme = urlSchemes[0] as! NSString
    
    var url = (URL.absoluteString as NSString).substringFromIndex(urlScheme.length+1)
    
    if url.hasPrefix("//") {
      url = (url as NSString).substringFromIndex(2)
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
      Keychain.removeStringForKey(Constants.PasswordHashKeychainKey)
      Keychain.removeStringForKey(Constants.PasswordSecretKeychainKey)
      Keychain.removeStringForKey(Constants.RecentSitesKeychainKey)
    }
    
    NSUserDefaults.standardUserDefaults().setObject(currentVersion, forKey: Constants.AppVersionDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }
}

