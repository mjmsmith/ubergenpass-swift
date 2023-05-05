import LocalAuthentication
import UIKit

class MainViewController: AppViewController {
  @IBOutlet weak private var logoImageView: UIImageView!
  @IBOutlet weak private var siteTextField: UITextField!
  @IBOutlet weak private var passwordLengthStepper: LabelStepper!
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
  private var inactiveDate: Date?
  private var recentSites: [String]?
  private var matchingSites: [String]?

  deinit {
    NotificationCenter.default.removeObserver(self)
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
    
    if let string = DefaultKeychain[.RecentSites] {
      self.recentSites = (try? JSONSerialization.jsonObject(with: string.data(using: .utf8) ?? Data(),
                                                            options: JSONSerialization.ReadingOptions())) as? [String] ?? []
      self.matchingSites = []
    }

    // Site text field.
    
    self.siteTextField.text = self.site
    
    // Password length stepper.
    
    self.passwordLengthStepper.minimumValue = 4
    self.passwordLengthStepper.maximumValue = 24
    self.passwordLengthStepper.value = Double(UserDefaults.standard.integer(forKey: Constants.PasswordLengthDefaultsKey))
    self.passwordLengthStepper.updateLabel()

    // Password type.
    
    if UserDefaults.standard.string(forKey: Constants.PasswordTypeDefaultsKey) == PasswordType.SHA512.rawValue {
      self.passwordTypeSegment.selectedSegmentIndex = 1
    }
    else {
      self.passwordTypeSegment.selectedSegmentIndex = 0
    }
    
    // Password text field.  We can't set the height in IB if the style is a rounded rect.
    
    self.passwordTextField.borderStyle = .roundedRect
    
    // Password buttons.
    
    self.clipboardButton.layer.cornerRadius = 8
    self.safariButton.layer.cornerRadius = 8

    // Matching sites popup.
    
    self.matchingSitesView.layer.shadowColor = UIColor.black.cgColor
    self.matchingSitesView.layer.shadowOpacity = 0.5
    self.matchingSitesView.layer.shadowOffset = CGSizeMake(0, 2)
    self.matchingSitesView.layer.shadowRadius = 4
    self.matchingSitesView.layer.cornerRadius = 4
    
    if let tableView = self.matchingSitesView.subviews[0] as? UITableView {
      tableView.layer.cornerRadius = 4
    }

    // Controls hidden until we have a site.

    self.domainLabel.isHidden = true
    self.passwordTextField.isHidden = true
    self.passwordTapView.isHidden = true
    self.clipboardButton.isHidden = true
    self.safariButton.isHidden = true
    self.checkmarkImageView.isHidden = true
    self.matchingSitesView.isHidden = true
    
    // If we're ready to generate passwords, update the UI as usual.
    
    if (PasswordGenerator.sharedGenerator.hasMasterPassword) {
      self.editingChanged()
    }
    else {
      self.addBlurView()
    }
    
    // Notifications.
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationDidEnterBackground),
                                           name: UIApplication.didEnterBackgroundNotification,
      object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(applicationWillEnterForeground),
                                           name: UIApplication.willEnterForegroundNotification,
      object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(pasteboardChanged),
                                           name: UIPasteboard.changedNotification,
                                           object: UIPasteboard.general)
  }
  
  override func viewDidAppear(_ animated: Bool) {
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

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  
  // MARK: Notifications
  
  @objc func applicationWillEnterForeground(notification: NSNotification) {
    guard let inactiveDate = self.inactiveDate else { return }
    
    let elapsed = fabs(Date().timeIntervalSince(inactiveDate))
    
    // Has the background timeout elapsed?
    
    if elapsed > Double(UserDefaults.standard.integer(forKey: Constants.BackgroundTimeoutDefaultsKey)) {
      var authError: NSError?
      let authContext = LAContext()
      
      // If we can authorize with Touch ID, try that first.  If that fails or we can't use it now,
      // force transition to the Settings view.

      let hasMasterPassword = PasswordGenerator.sharedGenerator.hasMasterPassword
      let hasTouchID = authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError)
      let touchIDEnabled = UserDefaults.standard.bool(forKey: Constants.TouchIDEnabledDefaultsKey)
      let settingsViewActive = self.presentedViewController is SettingsViewController

      if hasMasterPassword && hasTouchID && touchIDEnabled && !settingsViewActive {
        authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
          localizedReason: NSLocalizedString(Constants.AuthenticateString, comment: ""),
          reply: { (success: Bool, error: Error?) in
            DispatchQueue.main.async {
              if success {
                self.updateClipboardCheckmark()
                self.removeBlurView()
              }
              else {
                self.forceSettings()
              }
            }
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
  
  @objc func applicationDidEnterBackground(notification: NSNotification) {
    self.inactiveDate = Date()
    self.addBlurView()
  }
  
  @objc func pasteboardChanged(notification: NSNotification) {
    // TODO: ??? not called !!
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

    self.logoImageView.isHidden = hasDomain
    
    self.domainLabel.isHidden = !hasDomain
    self.passwordTextField.isHidden = !hasDomain
    self.passwordTapView.isHidden = !hasDomain
    self.clipboardButton.isHidden = !hasDomain
    self.safariButton.isHidden = !hasDomain
    
    self.updateClipboardCheckmark()
    
    if self.recentSites != nil {
      self.matchingSites = self.recentSitesMatchingText(text: (self.siteTextField.text ?? "").lowercased())
      
      if self.matchingSites?.isEmpty ?? true {
        self.matchingSitesView.isHidden = true
      }
      else {
        self.matchingSitesTableView.reloadData()
        self.sizeAndShowMatchingSitesView()
      }
    }
    
    //!! self.site = self.siteTextField.text
  }

  @IBAction private func passwordLengthChanged() {
    self.passwordLengthStepper.updateLabel()

    UserDefaults.standard.set(Int(self.passwordLengthStepper.value), forKey: Constants.PasswordLengthDefaultsKey)
    UserDefaults.standard.synchronize()
    
    if !self.passwordTextField.isHidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
  }
  
  @IBAction private func passwordTypeChanged() {
    let passwordType = [PasswordType.MD5, PasswordType.SHA512][self.passwordTypeSegment.selectedSegmentIndex]
    
    UserDefaults.standard.set(passwordType.rawValue, forKey: Constants.PasswordTypeDefaultsKey)
    UserDefaults.standard.synchronize()
    
    if !self.passwordTextField.isHidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
  }
  
  @IBAction private func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
    if recognizer.view == self.passwordTapView {
      self.passwordTextField.isSecureTextEntry = !self.passwordTextField.isSecureTextEntry
      self.siteTextField.resignFirstResponder()
    }
    else {
      self.view.endEditing(true)
    }
  }
  
  @IBAction private func help() {
    self.performSegue(withIdentifier: Constants.HelpSegueIdentifier) { segue in
      let helpViewController = segue.destination as! HelpViewController
      
      helpViewController.documentName = "MainHelp"
      helpViewController.delegate = self
    }
  }

  @IBAction private func about() {
    self.performSegue(withIdentifier: Constants.AboutSegueIdentifier) { segue in
      let aboutViewController = segue.destination as! AboutViewController
      
      aboutViewController.delegate = self
    }
  }
  
  @IBAction private func settings() {
    self.performSegue(withIdentifier: Constants.SettingsSegueIdentifier) { segue in
      let settingsViewController = segue.destination as! SettingsViewController
      
      settingsViewController.canCancel = PasswordGenerator.sharedGenerator.hasMasterPassword
      self.configureSettingsViewController(settingsViewController)
      settingsViewController.delegate = self
    }
  }
  
  @IBAction private func copyToClipboard() {
    UIPasteboard.general.string = self.passwordTextField.text
    self.updateClipboardCheckmark()
    
    if self.recentSites != nil {
      self.addToRecentSites()
    }
  }

  @IBAction private func launchSafari() {
    if var site = self.siteTextField.text {
      if site.range(of: ":") == nil {
        site = "http://" + site
      }

      if self.recentSites != nil {
        self.addToRecentSites()
      }
      
      if let URL = URL(string: site) {
        UIApplication.shared.open(URL)
      }
    }
  }
  
  // MARK: Private
  
  private func addBlurView() {
    if self.blurView != nil {
      return
    }
  
    self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
    
    self.blurView!.frame = self.view.bounds
    self.blurView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  
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
        self.dismiss(animated: false, completion: nil)
      }
      
      self.performSegue(withIdentifier: Constants.SettingsSegueIdentifier) { segue in
        let settingsViewController = segue.destination as! SettingsViewController
        
        settingsViewController.canCancel = false
        self.configureSettingsViewController(settingsViewController)
        settingsViewController.delegate = self
      }
    }
  }
  
  private func configureSettingsViewController(_ settingsViewController: SettingsViewController) {
    settingsViewController.backgroundTimeout = UserDefaults.standard.integer(forKey: Constants.BackgroundTimeoutDefaultsKey)
    settingsViewController.remembersRecentSites = (self.recentSites != nil)
    settingsViewController.touchIDEnabled = UserDefaults.standard.bool(forKey: Constants.TouchIDEnabledDefaultsKey)
  }
  
  private func addToRecentSites() {
    guard let site = PasswordGenerator.sharedGenerator.domainFromSite(self.siteTextField.text ?? "") else {
      return
    }

    if let recentCount = self.recentSites?.count,
       let index = self.recentSites?.firstIndex(of: site) {
      // Ignore this site if it's already the most recent one, otherwise remove it to be re-added.

      if index == recentCount - 1 {
        return
      }

      self.recentSites?.remove(at: index)
    }

    if self.recentSites?.count ?? 0 >= Constants.MaxRecentSites {
      self.recentSites?.removeFirst()
    }
  
    self.recentSites?.append(site)
    self.saveRecentSites()
  }

  private func recentSitesMatchingText(text: String) -> [String] {
    var prefixSites: [String] = []
    var insideSites: [String] = []
  
    if text == "" {
      return prefixSites
    }
  
    for site in self.recentSites ?? [] {
      let range = site.range(of: text)
  
      if range?.lowerBound == site.startIndex {
        prefixSites.append(site)
      }
      else if range != nil {
        insideSites.append(site)
      }
    }
  
    return prefixSites.sorted() + insideSites.sorted()
  }
  
  private func saveRecentSites() {
    guard let recentSites = self.recentSites,
          let data = try? JSONSerialization.data(withJSONObject: recentSites, options: JSONSerialization.WritingOptions()),
          let string = String(data: data, encoding: .utf8) else {
      return
    }
    
    DefaultKeychain[.RecentSites] = string
  }
  
  private func sizeAndShowMatchingSitesView() {
    self.matchingSitesViewHeightConstraint.constant = CGFloat(min(self.matchingSites?.count ?? 0, 5)) * self.matchingSitesTableView.rowHeight
    self.matchingSitesView.isHidden = false
  }
  
  private func updatePasswordTextField() {
    self.passwordTextField.isSecureTextEntry = true
    self.passwordTextField.text = PasswordGenerator.sharedGenerator.passwordForSite(self.siteTextField.text ?? "",
      length: Int(self.passwordLengthStepper.value),
      type: [PasswordType.MD5, PasswordType.SHA512][self.passwordTypeSegment.selectedSegmentIndex])
  }
  
  private func updateClipboardCheckmark() {
    self.checkmarkImageView.isHidden = self.clipboardButton.isHidden ||
                                     ((self.passwordTextField.text ?? "") != UIPasteboard.general.string)
  }
}

extension MainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.matchingSites?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = self.matchingSitesTableView.dequeueReusableCell(withIdentifier: Constants.MatchingSitesTableViewCellIdentifier)!
    
    cell.textLabel?.text = self.matchingSites?[indexPath.row]
    
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    self.siteTextField.text = self.matchingSites?[indexPath.row] ?? ""
    self.siteTextField.resignFirstResponder()
    
    self.editingChanged()
    
    self.matchingSitesView.isHidden = true
  }
}

extension MainViewController: UITextFieldDelegate {
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if self.matchingSites?.count ?? 0 > 0 {
      self.sizeAndShowMatchingSitesView()
    }
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.matchingSitesView.isHidden = true
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension MainViewController: AboutViewControllerDelegate {
  
  func aboutViewControllerDidFinish(aboutViewController: AboutViewController) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension MainViewController: HelpViewControllerDelegate {
  
  func helpViewControllerDidFinish(helpViewController: HelpViewController) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension MainViewController: SettingsViewControllerDelegate {
  
  func settingsViewControllerDidFinish(settingsViewController: SettingsViewController) {
    let _ = PasswordGenerator.sharedGenerator.setMasterPasswordForCurrentHash(masterPassword: settingsViewController.masterPassword)
    
    if settingsViewController.remembersRecentSites {
      if self.recentSites == nil {
        self.recentSites = []
        self.matchingSites = []
        
        self.saveRecentSites()
      }
    }
    else {
      if self.recentSites != nil {
        self.recentSites = nil
        self.matchingSites = nil
        self.matchingSitesView.isHidden = true
        
        DefaultKeychain[.RecentSites] = nil
      }
    }
    
    UserDefaults.standard.set(settingsViewController.touchIDEnabled, forKey:Constants.TouchIDEnabledDefaultsKey)
    UserDefaults.standard.set(settingsViewController.backgroundTimeout, forKey:Constants.BackgroundTimeoutDefaultsKey)
    UserDefaults.standard.synchronize()
    
    if !self.passwordTextField.isHidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
    
    self.removeBlurView()
    self.dismiss(animated: true, completion:nil)
  }

  func settingsViewControllerDidCancel(settingsViewController: SettingsViewController) {
    if !self.passwordTextField.isHidden {
      self.updatePasswordTextField()
      self.updateClipboardCheckmark()
    }
    
    self.dismiss(animated: true, completion:nil)
  }
}
