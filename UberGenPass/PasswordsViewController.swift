import UIKit

protocol PasswordsViewControllerDelegate: class {
  func passwordsViewControllerDidFinish(passwordsViewController: PasswordsViewController)
  func passwordsViewControllerDidCancel(passwordsViewController: PasswordsViewController)
}

class PasswordsViewController: AppViewController {
  weak var delegate: PasswordsViewControllerDelegate?
  var canCancel = false
  var masterPassword = ""
  var secretPassword = ""
  
  @IBOutlet private weak var cancelButtonItem: UIBarButtonItem!
  @IBOutlet private weak var doneButtonItem: UIBarButtonItem!
  @IBOutlet private weak var upperMasterTextField: UITextField!
  @IBOutlet private weak var lowerMasterTextField: UITextField!
  @IBOutlet private weak var masterStatusImageView: StatusImageView!
  @IBOutlet private weak var upperSecretTextField: UITextField!
  @IBOutlet private weak var lowerSecretTextField: UITextField!
  @IBOutlet private weak var secretStatusImageView: StatusImageView!
  @IBOutlet private weak var welcomeImageView: UIImageView!
  
  private var greyImage = UIImage(named: "GreyStatus")
  private var greenImage = UIImage(named: "GreenStatus")
  private var yellowImage = UIImage(named: "YellowStatus")
  private var redImage = UIImage(named: "RedStatus")

  func resetForActivate() {
    self.upperMasterTextField.text = nil
    self.lowerMasterTextField.text = nil
    
    self.upperSecretTextField.text = nil
    self.lowerSecretTextField.text = nil
    
    self.upperMasterTextField.becomeFirstResponder()
    self.editingChanged(nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.cancelButtonItem.enabled = self.canCancel
    
    if NSUserDefaults.standardUserDefaults().boolForKey(Constants.WelcomeShownDefaultsKey) {
      self.welcomeImageView.removeFromSuperview()
      self.upperMasterTextField.becomeFirstResponder()
    }
    else {
      NSUserDefaults.standardUserDefaults().setBool(true, forKey: Constants.WelcomeShownDefaultsKey)
    }
    
    self.editingChanged(nil)
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }

  // MARK: Actions

  @IBAction private func editingChanged(sender: UITextField?) {
    let upperMasterText = self.upperMasterTextField.text ?? ""
    let lowerMasterText = self.lowerMasterTextField.text ?? ""
    var masterStatusImage = self.greyImage
    let upperSecretText = self.upperSecretTextField.text ?? ""
    let lowerSecretText = self.lowerSecretTextField.text ?? ""
    var secretStatusImage = self.greyImage
    var isMasterDone = false
    var isSecretDone = false
    
    // Master status.
    
    if upperMasterText != "" && lowerMasterText != "" {
      if upperMasterText == lowerMasterText {
        masterStatusImage = self.greenImage
        isMasterDone = true
      }
      else if upperMasterText.hasPrefix(lowerMasterText) || lowerMasterText.hasPrefix(upperMasterText) {
        masterStatusImage = self.yellowImage
      }
      else {
        masterStatusImage = self.redImage
      }
    }
    
    self.masterStatusImageView.image = masterStatusImage
    
    // Secret status.

    if upperSecretText != "" || lowerSecretText != "" {
      if upperSecretText == lowerSecretText {
        secretStatusImage = self.greenImage
        isSecretDone = true
      }
      else if upperSecretText.hasPrefix(lowerSecretText) || lowerSecretText.hasPrefix(upperSecretText) {
        secretStatusImage = self.yellowImage
      }
      else {
        secretStatusImage = self.redImage
      }
      
      self.secretStatusImageView.image = secretStatusImage
      self.secretStatusImageView.hidden = false
    }
    else {
      self.secretStatusImageView.hidden = true
      isSecretDone = true
    }
    
    // Done button.
    
    self.doneButtonItem.enabled = isMasterDone && isSecretDone
    
    // Animate status images if done.
    
    if isMasterDone && (sender == self.upperMasterTextField || sender == self.lowerMasterTextField) {
      self.view.endEditing(true)
      self.masterStatusImageView.animate()
    }

    if isSecretDone && (sender == self.upperSecretTextField || sender == self.lowerSecretTextField) {
      self.view.endEditing(true)
      self.secretStatusImageView.animate()
    }
  }
  
  @IBAction private func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }
  
  @IBAction private func help() {
    self.performSegueWithIdentifier(Constants.HelpSegueIdentifier) { (segue) in
      let helpViewController = segue.destinationViewController as! HelpViewController
      
      helpViewController.documentName = "PasswordsHelp"
      helpViewController.delegate = self
    }
  }
  
  @IBAction private func done() {
    self.masterPassword = self.upperMasterTextField.text!
    self.secretPassword = self.upperSecretTextField.text ?? ""

    self.delegate?.passwordsViewControllerDidFinish(self)
  }
  
  @IBAction private func cancel() {
    self.delegate?.passwordsViewControllerDidCancel(self)
  }
}

extension PasswordsViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    switch textField {
      case self.upperMasterTextField:
        self.lowerMasterTextField.becomeFirstResponder()
      case self.lowerMasterTextField:
        self.upperSecretTextField.becomeFirstResponder()
      case self.upperSecretTextField:
        self.lowerSecretTextField.becomeFirstResponder()
      case self.lowerSecretTextField:
        self.upperMasterTextField.becomeFirstResponder()
      default:
        break;
    }
    
    return false
  }
}

extension PasswordsViewController: HelpViewControllerDelegate {
  
  func helpViewControllerDidFinish(helpViewController: HelpViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}

