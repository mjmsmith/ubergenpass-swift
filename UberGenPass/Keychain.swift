import Foundation
import Security

class Keychain {

  static func setString(inputString: String, forKey account: String) {
    var query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    let status = SecItemCopyMatching(query, nil)
  
    if status == errSecSuccess {
      let attrs = [kSecValueData as String: inputString.dataUsingEncoding(NSUTF8StringEncoding)!]
      let status = SecItemUpdate(query, attrs)
      
      if status != errSecSuccess {
        print("SecItemUpdate failed: \(status)")
      }
    }
    else if status == errSecItemNotFound {
      query[kSecValueData as String] = inputString.dataUsingEncoding(NSUTF8StringEncoding)!
      
      let status = SecItemAdd(query, nil)

      if status != errSecSuccess {
        print("SecItemAdd failed: \(status)")
      }
    }
    else {
      print("SecItemCopyMatching failed: \(status)")
    }
  }

  static func stringForKey(account: String) -> String? {
    let query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecReturnData as String: kCFBooleanTrue
    ]
    var result: AnyObject?
    let status = withUnsafeMutablePointer(&result) {
      SecItemCopyMatching(query, UnsafeMutablePointer($0))
    }

    if status != noErr {
      return nil
    }
    
    return NSString(data: result as! NSData, encoding: NSUTF8StringEncoding) as? String
  }
  
  static func removeStringForKey(account: String) {
    let query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account
    ]
    let status = SecItemDelete(query)
    
    if status != errSecSuccess {
      print("SecItemDelete failed: \(status)")
    }
  }
}
