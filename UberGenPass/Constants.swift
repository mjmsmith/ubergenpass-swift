import UIKit
import KeychainAccess

struct Constants {
  // User defaults.
  
  static let AppVersionDefaultsKey = "AppVersion"
  static let BackgroundTimeoutDefaultsKey = "BackgroundTimeout"
  static let PasswordLengthDefaultsKey = "PasswordLength"
  static let PasswordTypeDefaultsKey = "PasswordType"
  static let TouchIDEnabledDefaultsKey = "TouchIDEnabled"
  static let WelcomeShownDefaultsKey = "WelcomeShown"
  
  // Segues.
  
  static let AboutSegueIdentifier = "About"
  static let HelpSegueIdentifier = "Help"
  static let PasswordsSegueIdentifier = "Passwords"
  static let SettingsSegueIdentifier = "Settings"
  
  // Table view cells.
  
  static let MatchingSitesTableViewCellIdentifier = "MatchingSitesTableViewCell"
  
  // Localized strings.
  
  static let AuthenticateString = "Authenticate"
  
  // Misc.
  
  static let MaxRecentSites = 50
}

public enum KeychainKeys: String {
  case Hash
  case Secret
  case RecentSites
}

extension Keychain {
  public subscript(key: KeychainKeys) -> String? {
    get {
      return self[key.rawValue]
    }

    set {
      self[key.rawValue] = newValue
    }
  }
}

public var DefaultKeychain = Keychain()
