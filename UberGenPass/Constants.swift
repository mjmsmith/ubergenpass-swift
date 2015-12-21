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

enum LocalizedString: String {
  case Authenticate
}

struct Constants {
  
  // Misc.
  
  static let MaxRecentSites = 50
}