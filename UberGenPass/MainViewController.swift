import LocalAuthentication
import UIKit

class MainViewController: AppViewController {
  @IBOutlet weak private var logoImageView: UIImageView!
  @IBOutlet weak private var siteTextField: UITextField!
  @IBOutlet weak private var passwordLengthStepper: UIStepper!
  @IBOutlet weak private var passwordTypeSegment: UISegmentedControl!
  @IBOutlet weak private var domainLabel: UILabel!
  @IBOutlet weak private var passwordTextField: UITextField!
  @IBOutlet weak private var passwordTapView: UIView!
  @IBOutlet weak private var clipboardButton: UIButton!
  @IBOutlet weak private var safariButton: UIButton!
  @IBOutlet weak private var checkmarkImageView: UIImageView!
  @IBOutlet weak private var matchingSitesView: UIView!
  @IBOutlet weak private var matchingSitesTableView: UITableView!
  @IBOutlet weak private var matchingSitesViewHeightConstraint: NSLayoutConstraint!

  private var blurView: UIView?
  private var inactiveDate: NSDate?
  private var recentSites: NSMutableOrderedSet?
  private var matchingSites: [String]?

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  var site = "" {
    didSet {
      if self.siteTextField != nil {
        self.siteTextField.text = self.site
        self.editingChanged()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Recent sites.
    
    if let str = Keychain.stringForKey(Constants.RecentSitesKeychainKey) {
      let data = str.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
      
      do {
        let recentSites = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())

        self.recentSites = NSMutableOrderedSet(array: recentSites as! [String])
      }
      catch _ as NSError {
        self.recentSites = NSMutableOrderedSet()
      }

      self.matchingSites = []
    }

    // Site text field.
    
    self.siteTextField.text = self.site
    
    // Password length stepper.
    
    self.passwordLengthStepper.minimumValue = 4
    self.passwordLengthStepper.maximumValue = 24
    self.passwordLengthStepper.value = Double(NSUserDefaults.standardUserDefaults().integerForKey(Constants.PasswordLengthDefaultsKey))
    
    // Password type.
    
    if NSUserDefaults.standardUserDefaults().stringForKey(Constants.PasswordTypeDefaultsKey) == PasswordType.SHA512.rawValue {
      self.passwordTypeSegment.selectedSegmentIndex = 1
    }
    else {
      self.passwordTypeSegment.selectedSegmentIndex = 0
    }
    
    // Password text field.  We can't set the height in IB if the style is a rounded rect.
    
    self.passwordTextField.borderStyle = .RoundedRect
    
    // Password buttons.
    
    self.clipboardButton.layer.cornerRadius = 8
    self.safariButton.layer.cornerRadius = 8

    // Matching sites popup.
    
    self.matchingSitesView.layer.shadowColor = UIColor.blackColor().CGColor
    self.matchingSitesView.layer.shadowOpacity = 0.5
    self.matchingSitesView.layer.shadowOffset = CGSizeMake(0, 2)
    self.matchingSitesView.layer.shadowRadius = 4
    self.matchingSitesView.layer.cornerRadius = 4
    
    if let tableView = self.matchingSitesView.subviews[0] as? UITableView {
      tableView.layer.cornerRadius = 4
    }

    // Controls hidden until we have a site.

    self.domainLabel.hidden = true
    self.passwordTextField.hidden = true
    self.passwordTapView.hidden = true
    self.clipboardButton.hidden = true
    self.safariButton.hidden = true
    self.checkmarkImageView.hidden = true
    self.matchingSitesView.hidden = true
    
    // If we're ready to generate passwords, update the UI as usual.
    
    if (PasswordGenerator.sharedGenerator.hasMasterPassword) {
      self.editingChanged()
    }
    else {
      self.addBlurView()
    }
    
    // Notifications.
    
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("applicationDidEnterBackground:"),
      name: UIApplicationDidEnterBackgroundNotification,
      object: nil)

    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("applicationWillEnterForeground:"),
      name: UIApplicationWillEnterForegroundNotification,
      object: nil)

    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("pasteboardChanged:"),
      name: UIPasteboardChangedNotification,
      object: UIPasteboard.generalPasteboard())
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // If we have no master password, force a segue to Settings (only happens on startup).
    // Otherwise, set focus if we have no site text.

    if !PasswordGenerator.sharedGenerator.hasMasterPassword {
      self.settings()
    }
    else {
      self.removeBlurView()
      
      if self.siteTextField.text ?? "" == "" {
        self.siteTextField.becomeFirstResponder()
      }
    }
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }
  
  // MARK: Notifications
  
  func applicationWillEnterForeground(notification: NSNotification) {
    guard let inactiveDate = self.inactiveDate else { return }
    
    let elapsed = fabs(NSDate().timeIntervalSinceDate(inactiveDate))
    
    // Has the background timeout elapsed?
    
    if elapsed > Double(NSUserDefaults.standardUserDefaults().integerForKey(Constants.BackgroundTimeoutDefaultsKey)) {
      var authError: NSError?
      let authContext = LAContext()
      
      // If we can authorize with Touch ID, try that first.  If that fails or we can't use it now,
      // force transition to the Settings view.

      let hasMasterPassword = PasswordGenerator.sharedGenerator.hasMasterPassword
      let hasTouchID = authContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError)
      let touchIDEnabled = NSUserDefaults.standardUserDefaults().boolForKey(Constants.TouchIDEnabledDefaultsKey)
      
      if hasMasterPassword && hasTouchID && touchIDEnabled {
        authContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
          localizedReason: NSLocalizedString(Constants.AuthenticateString, comment: ""),
          reply: { (success: Bool, error: NSError?) in
            dispatch_async(dispatch_get_main_queue(), {
              if success {
                self.updateClipboardCheckmark()
                self.removeBlurView()
              }
              else {
                self.forceSettings()
              }
            })
        })
      }
      else {
        self.forceSettings()
      }
    }
    else {
      self.updateClipboardCheckmark()
      self.removeBlurView()
    }
    
    self.inactiveDate = nil
  }
  
  func applicationDidEnterBackground(notification: NSNotification) {
    self.inactiveDate = NSDate()
    self.addBlurView()
  }
  
  func pasteboardChanged(notification: NSNotification) {
    self.updateClipboardCheckmark()
  }
  
  // MARK: Actions

  @IBAction private func editingChanged() {
    var hasDomain = false
    
    if let domain = PasswordGenerator.sharedGenerator.domainFromSite(self.siteTextField.text ?? "") {
      self.domainLabel.text = domain
      self.updatePasswordTextField()
      hasDomain = true
    }

    self.logoImageView.hidden = hasDomain
    
    self.domainLabel.hidden = !hasDomain
    self.passwordTextField.hidden = !hasDomain
    self.passwordTapView.hidden = !hasDomain
    self.clipboardButton.hidden = !hasDomain
    self.safariButton.hidden = !hasDomain
    
    self.updateClipboardCheckmark()
    
    if let _ = self.recentSites {
      self.matchingSites = self.recentSitesMatchingText((self.siteTextField.text ?? "").lowercaseString)
      
      if self.matchingSites!.count == 0 {
        self.matchingSitesView.hidden = true
      }
      else {
        self.matchingSitesTableView.reloadData()
        self.sizeAndShowMatchingSitesView()
      }
    }
    
    //!! self.site = self.siteTextField.text
  }

  @IBAction private func passwordLengthChanged() {
    NSUserDefaults.standardUserDefaults().setInteger(Int(self.passwordLengthStepper.value), forKey: Constants.PasswordLengthDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    
    if !self.passwordTextField.hidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
  }
  
  @IBAction private func passwordTypeChanged() {
    let passwordType = [PasswordType.MD5, PasswordType.SHA512][self.passwordTypeSegment.selectedSegmentIndex]
    
    NSUserDefaults.standardUserDefaults().setObject(passwordType.rawValue, forKey: Constants.PasswordTypeDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    
    if !self.passwordTextField.hidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
  }
  
  @IBAction private func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
    if recognizer.view == self.passwordTapView {
      self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry
      self.siteTextField.resignFirstResponder()
    }
    else {
      self.view.endEditing(true)
    }
  }
  
  @IBAction private func help() {
    self.performSegueWithIdentifier(Constants.HelpSegueIdentifier) { (segue) in
      let helpViewController = segue.destinationViewController as! HelpViewController
      
      helpViewController.documentName = "MainHelp"
      helpViewController.delegate = self
    }
  }

  @IBAction private func about() {
    self.performSegueWithIdentifier(Constants.AboutSegueIdentifier) { (segue) in
      let aboutViewController = segue.destinationViewController as! AboutViewController
      
      aboutViewController.delegate = self
    }
  }
  
  @IBAction private func settings() {
    self.performSegueWithIdentifier(Constants.SettingsSegueIdentifier, preparation: { (segue: UIStoryboardSegue) in
      let settingsViewController = segue.destinationViewController as! SettingsViewController
      
      settingsViewController.canCancel = PasswordGenerator.sharedGenerator.hasMasterPassword
      self.configureSettingsViewController(settingsViewController)
      settingsViewController.delegate = self
    })
  }
  
  @IBAction private func copyToClipboard() {
    UIPasteboard.generalPasteboard().string = self.passwordTextField.text
    self.updateClipboardCheckmark()
    
    if self.recentSites != nil {
      self.addToRecentSites()
    }
  }

  @IBAction private func launchSafari() {
    if var site = self.siteTextField.text {
      if site.rangeOfString(":") == nil {
        site = "http://" + site
      }

      if self.recentSites != nil {
        self.addToRecentSites()
      }
      
      if let URL = NSURL(string: site) {
        UIApplication.sharedApplication().openURL(URL)
      }
    }
  }
  
  // MARK: Private
  
  private func addBlurView() {
    if self.blurView != nil {
      return
    }
  
    self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
    
    self.blurView!.frame = self.view.bounds
    self.blurView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
  
    self.view.addSubview(self.blurView!)
  }
  
  private func removeBlurView() {
    if let blurView = self.blurView {
      blurView.removeFromSuperview()
      self.blurView = nil
    }
  }
  
  private func forceSettings() {
    if let presentedViewController = self.presentedViewController as? SettingsViewController {
      presentedViewController.resetForActivate()
    }
    else {
      if let _ = self.presentedViewController {
        self.dismissViewControllerAnimated(false, completion: nil)
      }
      
      self.performSegueWithIdentifier(Constants.SettingsSegueIdentifier, preparation: { (segue) in
        let settingsViewController = segue.destinationViewController as! SettingsViewController
        
        settingsViewController.canCancel = false
        self.configureSettingsViewController(settingsViewController)
        settingsViewController.delegate = self
      })
    }
  }
  
  private func configureSettingsViewController(settingsViewController: SettingsViewController) {
    settingsViewController.backgroundTimeout = NSUserDefaults.standardUserDefaults().integerForKey(Constants.BackgroundTimeoutDefaultsKey)
    settingsViewController.remembersRecentSites = (self.recentSites != nil)
    settingsViewController.touchIDEnabled = NSUserDefaults.standardUserDefaults().boolForKey(Constants.TouchIDEnabledDefaultsKey)
  }
  
  private func addToRecentSites() {
    if let site = PasswordGenerator.sharedGenerator.domainFromSite(self.siteTextField.text ?? "") {
      // Ignore this site if it's already the most recent one.
  
      if site == self.recentSites!.lastObject as? String {
        return
      }
  
      // Append the site to the end of the ordered set.
  
      self.recentSites!.removeObject(site)
  
      if self.recentSites!.count >= Constants.MaxRecentSites {
        self.recentSites!.removeObjectAtIndex(0)
      }
  
      self.recentSites!.addObject(site)
      self.saveRecentSites()
    }
  }

  private func recentSitesMatchingText(text: String) -> [String] {
    var prefixSites: [String] = []
    var insideSites: [String] = []
  
    if text == "" {
      return prefixSites
    }
  
    for site in self.recentSites! {
      let range = site.rangeOfString(text)
  
      if range.location == 0 {
        prefixSites.append(site as! String)
      }
      else if range.location != NSNotFound {
        insideSites.append(site as! String)
      }
    }
  
    return prefixSites.sort() + insideSites.sort()
  }
  
  private func saveRecentSites() {
    let data = try! NSJSONSerialization.dataWithJSONObject(self.recentSites!.array, options: NSJSONWritingOptions())
    
    Keychain.setString((NSString(data: data, encoding: NSUTF8StringEncoding)! as String), forKey: Constants.RecentSitesKeychainKey)
  }
  
  private func sizeAndShowMatchingSitesView() {
    self.matchingSitesViewHeightConstraint.constant = CGFloat(min(self.matchingSites!.count, 5)) * self.matchingSitesTableView.rowHeight
    self.matchingSitesView.hidden = false
  }
  
  private func updatePasswordTextField() {
    self.passwordTextField.secureTextEntry = true
    self.passwordTextField.text = PasswordGenerator.sharedGenerator.passwordForSite(self.siteTextField.text ?? "",
      length: Int(self.passwordLengthStepper.value),
      type: [PasswordType.MD5, PasswordType.SHA512][self.passwordTypeSegment.selectedSegmentIndex])
  }
  
  private func updateClipboardCheckmark() {
    self.checkmarkImageView.hidden = self.clipboardButton.hidden ||
                                     ((self.passwordTextField.text ?? "") != UIPasteboard.generalPasteboard().string)
  }
}

extension MainViewController: UITableViewDataSource {
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.matchingSites?.count ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = self.matchingSitesTableView.dequeueReusableCellWithIdentifier(Constants.MatchingSitesTableViewCellIdentifier)!
    
    cell.textLabel!.text = self.matchingSites![indexPath.row]
    
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)

    self.siteTextField.text = self.matchingSites![indexPath.row]
    self.siteTextField.resignFirstResponder()
    
    self.editingChanged()
    
    self.matchingSitesView.hidden = true
  }
}

extension MainViewController: UITextFieldDelegate {
  
  func textFieldDidBeginEditing(textField: UITextField) {
    if let _ = self.recentSites {
      if self.matchingSites!.count > 0 {
        self.sizeAndShowMatchingSitesView()
      }
    }
  }
  
  func textFieldDidEndEditing(textField: UITextField) {
    if let _ = self.recentSites {
      self.matchingSitesView.hidden = true
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension MainViewController: AboutViewControllerDelegate {
  
  func aboutViewControllerDidFinish(aboutViewController: AboutViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}

extension MainViewController: HelpViewControllerDelegate {
  
  func helpViewControllerDidFinish(helpViewController: HelpViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}

extension MainViewController: SettingsViewControllerDelegate {
  
  func settingsViewControllerDidFinish(settingsViewController: SettingsViewController) {
    PasswordGenerator.sharedGenerator.setMasterPasswordForCurrentHash(settingsViewController.masterPassword)
    
    if settingsViewController.remembersRecentSites {
      if self.recentSites == nil {
        self.recentSites = NSMutableOrderedSet()
        self.matchingSites = []
        
        self.saveRecentSites()
      }
    }
    else {
      if self.recentSites != nil {
        self.recentSites = nil;
        self.matchingSites = nil;
        self.matchingSitesView.hidden = true
        
        Keychain.removeStringForKey(Constants.RecentSitesKeychainKey)
      }
    }
    
    NSUserDefaults.standardUserDefaults().setBool(settingsViewController.touchIDEnabled, forKey:Constants.TouchIDEnabledDefaultsKey)
    NSUserDefaults.standardUserDefaults().setInteger(settingsViewController.backgroundTimeout, forKey:Constants.BackgroundTimeoutDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    
    if !self.passwordTextField.hidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
    
    self.removeBlurView()
    self.dismissViewControllerAnimated(true, completion:nil)
  }

  func settingsViewControllerDidCancel(settingsViewController: SettingsViewController) {
    if !self.passwordTextField.hidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
    
    self.dismissViewControllerAnimated(true, completion:nil)
  }
}