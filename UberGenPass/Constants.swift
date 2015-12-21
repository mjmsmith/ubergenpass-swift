import UIKit

enum UserDefaultsKey: String {
  case AppVersion
  case BackgroundTimeout
  case PasswordLength
  case PasswordType
  case TouchIDEnabled
  case WelcomeShown
}

enum KeychainKey: String {
  case Hash
  case Secret
  case RecentSites
}

struct Constants {
  // Table view cells.
  
  static let MatchingSitesTableViewCellIdentifier = "MatchingSitesTableViewCell"
  
  // Localized strings.
  
  static let AuthenticateString = "Authenticate"
  
  // Misc.
  
  static let MaxRecentSites = 50
}