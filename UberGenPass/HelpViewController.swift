import UIKit

protocol HelpViewControllerDelegate: class {
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
    
    self.backButtonItem.enabled = false
    self.forwardButtonItem.enabled = false
    
    self.webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource(self.documentName, withExtension: "html")!))
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
    self.delegate?.helpViewControllerDidFinish(self)
  }
}

extension HelpViewController: UIWebViewDelegate {
  
  func webViewDidFinishLoad(webView: UIWebView) {
    self.backButtonItem.enabled = self.webView.canGoBack
    self.forwardButtonItem.enabled = self.webView.canGoForward
  }
}