import LocalAuthentication
import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
  func settingsViewControllerDidFinish(settingsViewController: SettingsViewController)
  func settingsViewControllerDidCancel(settingsViewController: SettingsViewController)
}

class SettingsViewController: AppViewController {
  var canCancel = true {
    didSet {
      if let cancelButtonItem = self.cancelButtonItem {
        cancelButtonItem.isEnabled = self.canCancel
      }
      if #available(iOS 13, *) {
        self.isModalInPresentation = !self.canCancel
      }
    }
  }
  var masterPassword = ""
  var remembersRecentSites = false
  var touchIDEnabled = false
  var backgroundTimeout = 0
  weak var delegate: SettingsViewControllerDelegate?

  @IBOutlet private weak var cancelButtonItem: UIBarButtonItem!
  @IBOutlet private weak var doneButtonItem: UIBarButtonItem!
  @IBOutlet private weak var passwordTextField: UITextField!
  @IBOutlet private weak var statusImageView: StatusImageView!
  @IBOutlet private weak var changePasswordButton: UIButton!
  @IBOutlet private weak var recentSitesSwitch: UISwitch!
  @IBOutlet private weak var touchIDSwitch: UISwitch!
  @IBOutlet private weak var timeoutSegment: UISegmentedControl!
  
  private var greyImage = UIImage(named: "GreyStatus")
  private var greenImage = UIImage(named: "GreenStatus")
  
  func resetForActivate() {
    if self.canCancel {
      self.canCancel = false
    }
    
    self.passwordTextField.text = nil
    self.passwordTextField.becomeFirstResponder()
    
    self.editingChanged(sender: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var authError: NSError?
    let hasTouchID = LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError)
    
    self.cancelButtonItem.isEnabled = self.canCancel

    self.recentSitesSwitch.isOn = self.remembersRecentSites

    self.touchIDSwitch.isOn = self.touchIDEnabled
    self.touchIDSwitch.isEnabled = hasTouchID
    
    if self.backgroundTimeout == 60 {
      self.timeoutSegment.selectedSegmentIndex = 1
    }
    else if self.backgroundTimeout == 300 {
      self.timeoutSegment.selectedSegmentIndex = 2
    }
    
    self.editingChanged(sender: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // If we have no master password hash, force a segue to Passwords (only happens on startup).
    
    if !PasswordGenerator.sharedGenerator.hasPasswordHash {
      self.performSegue(withIdentifier: Constants.PasswordsSegueIdentifier) { segue in
        let passwordsViewController = segue.destination as! PasswordsViewController
        
        passwordsViewController.canCancel = false
        passwordsViewController.delegate = self
      }
    }
    else {
      // If the Done button is enabled, resign focus.
      // Otherwise, set focus to the password text field.
      
      if self.doneButtonItem.isEnabled {
        self.view.endEditing(false)
      }
      else {
        self.passwordTextField.becomeFirstResponder()
      }
    }
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  
  // MARK: Actions
  
  @IBAction private func editingChanged(sender: UITextField?) {
    if PasswordGenerator.sharedGenerator.textMatchesHash(text: self.passwordTextField.text ?? "") {
      self.statusImageView.image = self.greenImage
      self.doneButtonItem.isEnabled = true

      self.passwordTextField.resignFirstResponder()

      if sender == self.passwordTextField {
        self.statusImageView.animate()
      }
    }
    else {
      self.statusImageView.image = self.greyImage
      self.doneButtonItem.isEnabled = false
    }
  }
  
  @IBAction private func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }

  @IBAction private func changePasswords() {
    self.performSegue(withIdentifier: Constants.PasswordsSegueIdentifier) { segue in
      let passwordsViewController = segue.destination as! PasswordsViewController
      
      passwordsViewController.canCancel = true
      passwordsViewController.delegate = self
    }
  }
  
  @IBAction private func help() {
    self.performSegue(withIdentifier: Constants.HelpSegueIdentifier) { segue in
      let helpViewController = segue.destination as! HelpViewController
      
      helpViewController.documentName = "SettingsHelp"
      helpViewController.delegate = self
    }
  }
  
  @IBAction private func addSafariBookmarklet() {
    UIPasteboard.general.string = "javascript:location.href='ubergenpass:'+location.href"
    UIApplication.shared.open(URL(string: "http://camazotz.com/ubergenpass/bookmarklet")!)
  }
  
  @IBAction private func done() {
    self.masterPassword = self.passwordTextField.text ?? ""
    self.remembersRecentSites = self.recentSitesSwitch.isOn
    self.touchIDEnabled = self.touchIDSwitch.isOn
    self.backgroundTimeout = [0, 60, 300][self.timeoutSegment.selectedSegmentIndex]
    
    self.delegate?.settingsViewControllerDidFinish(settingsViewController: self)
  }

  @IBAction private func cancel() {
    self.delegate?.settingsViewControllerDidCancel(settingsViewController: self)
  }
  
  // MARK: Private
}

extension SettingsViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return false
  }
}

extension SettingsViewController: HelpViewControllerDelegate {
  
  func helpViewControllerDidFinish(helpViewController: HelpViewController) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SettingsViewController: PasswordsViewControllerDelegate {
  
  func passwordsViewControllerDidFinish(passwordsViewController: PasswordsViewController) {
    PasswordGenerator.sharedGenerator.updateMasterPassword(masterPassword: passwordsViewController.masterPassword, secretPassword: passwordsViewController.secretPassword)
    
    self.dismiss(animated: true, completion: {
      self.passwordTextField.text = passwordsViewController.masterPassword
      self.editingChanged(sender: self.passwordTextField)
    })
  }

  func passwordsViewControllerDidCancel(passwordsViewController: PasswordsViewController) {
    self.dismiss(animated: true, completion: nil)
  }
}
