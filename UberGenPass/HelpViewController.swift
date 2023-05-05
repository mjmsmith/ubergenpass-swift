import UIKit

protocol HelpViewControllerDelegate: AnyObject {
  func helpViewControllerDidFinish(helpViewController: HelpViewController)
}

class HelpViewController: AppViewController {

  var documentName = ""
  weak var delegate: HelpViewControllerDelegate?
  
  @IBOutlet private weak var webView: UIWebView!
  @IBOutlet private weak var backButtonItem: UIBarButtonItem!
  @IBOutlet private weak var forwardButtonItem: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.backButtonItem.isEnabled = false
    self.forwardButtonItem.isEnabled = false
    
    self.webView.loadRequest(URLRequest(url: Bundle.main.url(forResource: self.documentName, withExtension: "html")!))
  }

  // MARK: Actions
  
  @IBAction private func back() {
    self.webView.goBack()
  }
  
  @IBAction private func forward() {
    self.webView.goForward()
  }

  // MARK: Private
  
  @IBAction private func done() {
    self.delegate?.helpViewControllerDidFinish(helpViewController: self)
  }
}

extension HelpViewController: UIWebViewDelegate {
  
  func webViewDidFinishLoad(_ webView: UIWebView) {
    self.backButtonItem.isEnabled = self.webView.canGoBack
    self.forwardButtonItem.isEnabled = self.webView.canGoForward
  }
}
