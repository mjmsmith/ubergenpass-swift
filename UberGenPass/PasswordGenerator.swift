import Foundation

// Raw values match user defaults values.

enum PasswordType: String {
  case MD5 = "MD5"
  case SHA512 = "SHA"
}

class PasswordGenerator {
  static let sharedGenerator = PasswordGenerator()
  
  private var tlds: NSMutableOrderedSet
  private var masterPassword: String
  private var secretPassword: String
  private var passwordHash: Data?
  private var lowerCasePattern: NSRegularExpression
  private var upperCasePattern: NSRegularExpression
  private var digitPattern: NSRegularExpression
  private var domainPattern: NSRegularExpression
  
  private init() {
    try! self.lowerCasePattern = NSRegularExpression(pattern:"[a-z]", options:NSRegularExpression.Options())
    try! self.upperCasePattern = NSRegularExpression(pattern:"[A-Z]", options:NSRegularExpression.Options())
    try! self.digitPattern = NSRegularExpression(pattern:"[\\d]", options:NSRegularExpression.Options())
    try! self.domainPattern = NSRegularExpression(pattern:"[^.]+[.][^.]+", options:NSRegularExpression.Options())

    let path = (Bundle.main.resourcePath! as NSString).appendingPathComponent("TopLevelDomains.json")
    let tldsData = try! Data(contentsOf: URL(fileURLWithPath: path))
    let tldsArray = try! JSONSerialization.jsonObject(with: tldsData, options: JSONSerialization.ReadingOptions())
    
    self.tlds = NSMutableOrderedSet(array: tldsArray as! [String])

    if let hashStr = DefaultKeychain[.Hash] {
      self.passwordHash = Data(base64Encoded: hashStr)
    }

    self.masterPassword = ""
    self.secretPassword = ""
  }

  func passwordForSite(_ site: String, length: Int, type: PasswordType) -> String? {
    guard let domain = self.domainFromSite(site) else { return nil }
    var password: String = "\(self.masterPassword)\(self.secretPassword):\(domain)"
    var count = 0

    while count < 10 || !self.isValidPassword(String(password.prefix(length))) {
      if type == .MD5 {
        password = (password.data(using: .utf8)! as NSData).md5Sum().base64EncodedString()
      }
      else {
        password = (password.data(using: .utf8)! as NSData).sha512Hash().base64EncodedString()
      }

      password = password.replacingOccurrences(of: "=", with: "A")
      password = password.replacingOccurrences(of: "+", with: "9")
      password = password.replacingOccurrences(of: "/", with: "8")
      count += 1
    }

    return String(password.prefix(length))
  }

  func domainFromSite(_ site: String) -> String? {
    if self.domainPattern.numberOfMatches(in: site, options:NSRegularExpression.MatchingOptions(), range:NSMakeRange(0, (site as NSString).length)) == 0 {
      return nil
    }

    var site = site

    if site.range(of: "://") == nil {
      site = "//" + site
    }

    guard let url = NSURL(string: site) else { return nil }
    guard let host = url.host?.lowercased() else { return nil }
    var domain: String? = nil

    if site.hasPrefix("//") {
      domain = host
    }
    else {
      let parts = host.components(separatedBy: ".")

      if parts.count >= 2 {
        domain = parts[parts.count-2..<parts.count].joined(separator: ".")

        if self.tlds.contains(domain!) {
          if parts.count >= 3 {
            domain = parts[parts.count-3..<parts.count].joined(separator: ".")
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
    
    if passwordHash.count == 0 {
      return false
    }

    if passwordHash != (masterPassword.data(using: .utf8)! as NSData).sha256Hash() {
      return false
    }

    self.masterPassword = masterPassword

    if let secretPasswordStr = DefaultKeychain[.Secret] {
      var secretPasswordData = Data(base64Encoded: secretPasswordStr)!
      
      secretPasswordData = try! (secretPasswordData as NSData).decryptedAES256Data(usingKey: masterPassword)
      self.secretPassword = NSString(data: secretPasswordData, encoding:NSUTF8StringEncoding)! as String
    }
    else {
      self.secretPassword = ""
    }

    return true
  }

  func updateMasterPassword(masterPassword: String, secretPassword: String) {
    let passwordHash = (masterPassword.data(using: .utf8)! as NSData).sha256Hash()!
    
    self.masterPassword = masterPassword
    self.secretPassword = secretPassword
    self.passwordHash = passwordHash

    let secret = try! (secretPassword.data(using: .utf8)! as NSData).aes256EncryptedData(usingKey: masterPassword)

    DefaultKeychain[.Hash] = passwordHash.base64EncodedString()
    DefaultKeychain[.Secret] = secret.base64EncodedString()
  }

  func textMatchesHash(text: String) -> Bool {
    if let passwordHash = self.passwordHash {
      return passwordHash == (text.data(using: .utf8)! as NSData).sha256Hash()
    }
    else {
      return false
    }
  }

  // MARK: Private

  private func isValidPassword(_ password: String) -> Bool {
    let range = NSMakeRange(0, (password as NSString).length)

    return self.lowerCasePattern.rangeOfFirstMatch(in: password, options:NSRegularExpression.MatchingOptions(), range:range).location == 0 &&
    self.upperCasePattern.numberOfMatches(in: password, options:NSRegularExpression.MatchingOptions(), range:range) != 0 &&
    self.digitPattern.numberOfMatches(in: password, options:NSRegularExpression.MatchingOptions(), range:range) != 0
  }
}
