import LocalAuthentication
import UIKit

protocol SettingsViewControllerDelegate: class {
  func settingsViewControllerDidFinish(settingsViewController: SettingsViewController);
  func settingsViewControllerDidCancel(settingsViewController: SettingsViewController);
}

class SettingsViewController: AppViewController {
  var canCancel = true
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
      self.cancelButtonItem.enabled = false
    }
    
    self.passwordTextField.text = nil
    self.passwordTextField.becomeFirstResponder()
    
    self.editingChanged(nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var authError: NSError?
    let hasTouchID = LAContext().canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &authError)
    
    self.cancelButtonItem.enabled = self.canCancel
    
    self.recentSitesSwitch.on = self.remembersRecentSites

    self.touchIDSwitch.on = self.touchIDEnabled
    self.touchIDSwitch.enabled = hasTouchID
    
    if self.backgroundTimeout == 60 {
      self.timeoutSegment.selectedSegmentIndex = 1
    }
    else if self.backgroundTimeout == 300 {
      self.timeoutSegment.selectedSegmentIndex = 2
    }
    
    self.editingChanged(nil)
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // If we have no master password hash, force a segue to Passwords (only happens on startup).
    
    if !PasswordGenerator.sharedGenerator.hasPasswordHash {
      self.performSegueWithIdentifier(Constants.PasswordsSegueIdentifier, preparation: { (segue) in
        let passwordsViewController = segue.destinationViewController as! PasswordsViewController
        
        passwordsViewController.canCancel = false
        passwordsViewController.delegate = self
      })
    }
    else {
      // If the Done button is enabled, resign focus.
      // Otherwise, set focus to the password text field.
      
      if self.doneButtonItem.enabled {
        self.view.endEditing(false)
      }
      else {
        self.passwordTextField.becomeFirstResponder()
      }
    }
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }
  
  // MARK: Actions
  
  @IBAction private func editingChanged(sender: UITextField?) {
    if PasswordGenerator.sharedGenerator.textMatchesHash(self.passwordTextField.text ?? "") {
      self.statusImageView.image = self.greenImage
      self.doneButtonItem.enabled = true

      self.passwordTextField.resignFirstResponder()

      if sender == self.passwordTextField {
        self.statusImageView.animate()
      }
    }
    else {
      self.statusImageView.image = self.greyImage
      self.doneButtonItem.enabled = false
    }
  }
  
  @IBAction private func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }

  @IBAction private func changePasswords() {
    self.performSegueWithIdentifier(Constants.PasswordsSegueIdentifier) { (segue) in
      let passwordsViewController = segue.destinationViewController as! PasswordsViewController
      
      passwordsViewController.canCancel = true
      passwordsViewController.delegate = self
    }
  }
  
  @IBAction private func help() {
    self.performSegueWithIdentifier(Constants.HelpSegueIdentifier) { (segue) in
      let helpViewController = segue.destinationViewController as! HelpViewController
      
      helpViewController.documentName = "SettingsHelp"
      helpViewController.delegate = self
    }
  }
  
  @IBAction private func addSafariBookmarklet() {
    UIPasteboard.generalPasteboard().string = "javascript:location.href='ubergenpass:'+location.href"
    UIApplication.sharedApplication().openURL(NSURL(string: "http://camazotz.com/ubergenpass/bookmarklet")!)
  }
  
  @IBAction private func done() {
    self.masterPassword = self.passwordTextField.text!
    self.remembersRecentSites = self.recentSitesSwitch.on
    self.touchIDEnabled = self.touchIDSwitch.on
    self.backgroundTimeout = [0, 60, 300][self.timeoutSegment.selectedSegmentIndex]
    
    self.delegate?.settingsViewControllerDidFinish(self)
  }

  @IBAction private func cancel() {
    self.delegate?.settingsViewControllerDidCancel(self)
  }
  
  // MARK: Private
}

extension SettingsViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    return false
  }
}

extension SettingsViewController: HelpViewControllerDelegate {
  
  func helpViewControllerDidFinish(helpViewController: HelpViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}

extension SettingsViewController: PasswordsViewControllerDelegate {
  
  func passwordsViewControllerDidFinish(passwordsViewController: PasswordsViewController) {
    PasswordGenerator.sharedGenerator.updateMasterPassword(passwordsViewController.masterPassword, secretPassword: passwordsViewController.secretPassword)
    
    self.dismissViewControllerAnimated(true, completion: {
      self.passwordTextField.text = passwordsViewController.masterPassword
      self.editingChanged(self.passwordTextField)
    })
  }

  func passwordsViewControllerDidCancel(passwordsViewController: PasswordsViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}
