import UIKit

enum UserDefaultsKey: String {
  case AppVersion
  case BackgroundTimeout
  case PasswordLength
  case PasswordType
  case TouchIDEnabled
  case SavePasswordEnabled
  case WelcomeShown
}

enum KeychainKey: String {
  case Hash
  case Password
  case Secret
  case RecentSites
}

enum LocalizedString: String {
  case Authenticate
}
