import UIKit

enum UserDefaultsKey: String {
  case AppVersion
  case BackgroundTimeout
  case PasswordLength
  case PasswordType
  case TouchIDEnabled
  case WelcomeShown
}

struct Constants {
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