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

  // Segues.
  
  static let AboutSegueIdentifier = "About"
  static let HelpSegueIdentifier = "Help"
  static let PasswordsSegueIdentifier = "Passwords"
  static let SettingsSegueIdentifier = "Settings"
  
  // Table view cells.
  
  static let MatchingSitesTableViewCellIdentifier = "MatchingSitesTableViewCell"
  
  // Strings.
  
  static let AuthenticateString = "Authenticate"
  
  // Misc.
  
  static let MaxRecentSites = 50
}