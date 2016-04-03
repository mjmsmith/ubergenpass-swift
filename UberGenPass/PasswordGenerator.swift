import Foundation

// Raw values match user defaults values.

enum PasswordType: String {
  case MD5 = "MD5"
  case SHA512 = "SHA"
}

class PasswordGenerator {
  static let sharedGenerator = PasswordGenerator()
  
  private var tlds: NSMutableOrderedSet
  private var masterPassword = ""
  private var secretPassword = ""
  private var passwordHash: NSData?
  private var lowerCasePattern: NSRegularExpression
  private var upperCasePattern: NSRegularExpression
  private var digitPattern: NSRegularExpression
  private var domainPattern: NSRegularExpression
  
  private init() {
    try! self.lowerCasePattern = NSRegularExpression(pattern: "[a-z]", options: NSRegularExpressionOptions())
    try! self.upperCasePattern = NSRegularExpression(pattern: "[A-Z]", options: NSRegularExpressionOptions())
    try! self.digitPattern = NSRegularExpression(pattern: "[\\d]", options: NSRegularExpressionOptions())
    try! self.domainPattern = NSRegularExpression(pattern: "[^.]+[.][^.]+", options: NSRegularExpressionOptions())

    let path = (NSBundle.mainBundle().resourcePath! as NSString).stringByAppendingPathComponent("TopLevelDomains.json")
    let tldsData = NSData(contentsOfFile: path)!
    let tldsArray = try! NSJSONSerialization.JSONObjectWithData(tldsData, options: NSJSONReadingOptions())
    
    self.tlds = NSMutableOrderedSet(array: tldsArray as! [String])

    if let hashStr = Keychain.stringForKey(KeychainKey.Hash.rawValue) {
      self.passwordHash = NSData(base64EncodedString: hashStr, options: NSDataBase64DecodingOptions())
      
      if let passwordStr = Keychain.stringForKey(KeychainKey.Password.rawValue) {
        self.setMasterPasswordForCurrentHash(passwordStr)
      }
    }
  }

  func passwordForSite(site: String, length: Int, type: PasswordType) -> String? {
    guard let domain = self.domainFromSite(site) else { return nil }
    var password: NSString = "\(self.masterPassword)\(self.secretPassword):\(domain)"
    var count = 0

    while count < 10 || !self.isValidPassword(password.substringToIndex(length)) {
      if type == .MD5 {
        password = password.dataUsingEncoding(NSUTF8StringEncoding)!.MD5Sum().base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
      }
      else {
        password = password.dataUsingEncoding(NSUTF8StringEncoding)!.SHA512Hash().base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
      }

      password = password.stringByReplacingOccurrencesOfString("=", withString: "A")
      password = password.stringByReplacingOccurrencesOfString("+", withString: "9")
      password = password.stringByReplacingOccurrencesOfString("/", withString: "8")
      count += 1
    }

    return password.substringToIndex(length)
  }

  func domainFromSite(site: String) -> String? {
    if self.domainPattern.numberOfMatchesInString(site,
                                                  options: NSMatchingOptions(),
                                                  range: NSRange(location: 0, length: site.characters.count)) == 0 {
      return nil
    }

    let url = site.containsString("://") ? site : "//\(site)"
    
    guard let URL = NSURL(string: url) else { return nil }
    guard let host = URL.host?.lowercaseString else { return nil }
    var domain: String? = nil

    if url.hasPrefix("//") {
      domain = host
    }
    else {
      let parts = host.componentsSeparatedByString(".")

      if parts.count >= 2 {
        domain = parts[parts.count-2..<parts.count].joinWithSeparator(".")

        if self.tlds.containsObject(domain!) {
          if parts.count >= 3 {
            domain = parts[parts.count-3..<parts.count].joinWithSeparator(".")
          }
        }
      }
    }

    return domain
  }

  var hasPasswordHash: Bool {
    return self.passwordHash != nil
  }
  
  var hasMasterPassword: Bool {
    return self.masterPassword != ""
  }

  func setMasterPasswordForCurrentHash(masterPassword: String) -> Bool {
    guard let passwordHash = self.passwordHash else { return false }
    
    if passwordHash.length == 0 {
      return false
    }

    if !passwordHash.isEqualToData(masterPassword.dataUsingEncoding(NSUTF8StringEncoding)!.SHA256Hash()) {
      return false
    }

    self.masterPassword = masterPassword

    if let secretPasswordStr = Keychain.stringForKey(KeychainKey.Secret.rawValue) {
      var secretPasswordData = NSData(base64EncodedString: secretPasswordStr, options: NSDataBase64DecodingOptions())!
      
      secretPasswordData = try! secretPasswordData.decryptedAES256DataUsingKey(masterPassword)
      self.secretPassword = NSString(data: secretPasswordData, encoding: NSUTF8StringEncoding)! as String
    }
    else {
      self.secretPassword = ""
    }

    return true
  }

  func updateMasterPassword(masterPassword: String, secretPassword: String) {
    let passwordHash = masterPassword.dataUsingEncoding(NSUTF8StringEncoding)!.SHA256Hash()
    
    self.masterPassword = masterPassword
    self.secretPassword = secretPassword
    self.passwordHash = passwordHash
    
    self.updateKeychain()
  }

  func updateKeychain() {
    let secret = try! self.secretPassword.dataUsingEncoding(NSUTF8StringEncoding)!.AES256EncryptedDataUsingKey(self.masterPassword)
    
    Keychain.setString(self.passwordHash!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions()), forKey: KeychainKey.Hash.rawValue)
    Keychain.setString(secret.base64EncodedStringWithOptions(NSDataBase64EncodingOptions()), forKey: KeychainKey.Secret.rawValue)
    
    if NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKey.SavePasswordEnabled.rawValue) {
      Keychain.setString(self.masterPassword, forKey: KeychainKey.Password.rawValue)
    }
    else {
      Keychain.removeStringForKey(KeychainKey.Password.rawValue)
    }
  }
  
  func textMatchesHash(text: String) -> Bool {
    if let passwordHash = self.passwordHash {
      return passwordHash.isEqualToData(text.dataUsingEncoding(NSUTF8StringEncoding)!.SHA256Hash())
    }
    else {
      return false
    }
  }

  // MARK: Private

  private func isValidPassword(password: String) -> Bool {
    let range = NSRange(location: 0, length: password.characters.count)

    return self.lowerCasePattern.rangeOfFirstMatchInString(password, options: NSMatchingOptions(), range: range).location == 0 &&
           self.upperCasePattern.numberOfMatchesInString(password, options: NSMatchingOptions(), range: range) != 0 &&
           self.digitPattern.numberOfMatchesInString(password, options: NSMatchingOptions(), range: range) != 0
  }
}