import UIKit

struct Constants {
  // User defaults.
  
  static let AppVersionDefaultsKey = "AppVersion"
  static let BackgroundTimeoutDefaultsKey = "BackgroundTimeout"
  static let PasswordLengthDefaultsKey = "PasswordLength"
  static let PasswordTypeDefaultsKey = "PasswordType"
  static let TouchIDEnabledDefaultsKey = "TouchIDEnabled"
  static let WelcomeShownDefaultsKey = "WelcomeShown"
  
  // Keychain.

  static let PasswordHashKeychainKey = "Hash"
  static let PasswordSecretKeychainKey = "Secret"
  static let RecentSitesKeychainKey = "RecentSites"

  // Table view cells.
  
  static let MatchingSitesTableViewCellIdentifier = "MatchingSitesTableViewCell"
  
  // Localized strings.
  
  static let AuthenticateString = "Authenticate"
  
  // Misc.
  
  static let MaxRecentSites = 50
}