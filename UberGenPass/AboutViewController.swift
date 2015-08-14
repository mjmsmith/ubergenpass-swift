import UIKit

protocol AboutViewControllerDelegate: class {
  func aboutViewControllerDidFinish(aboutViewController: AboutViewController)
}

class AboutViewController: AppViewController {
  
  weak var delegate: AboutViewControllerDelegate?
  
  @IBOutlet private weak var nameLabel: UILabel!
  @IBOutlet private weak var rateButton: UIButton!
  @IBOutlet private weak var webView: UIWebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")!
    
    self.nameLabel.text = "UberGenPass \(version)"

    self.rateButton.layer.cornerRadius = 8.0
    
    self.webView.scrollView.bounces = false
    self.webView.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource("About", withExtension: "html")!))
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }
  
  // MARK: Actions
  
  @IBAction private func rate() {
    UIApplication.sharedApplication().openURL(NSURL(string: "http://appstore.com/ubergenpass")!)
  }

  @IBAction private func done() {
    self.delegate?.aboutViewControllerDidFinish(self)
  }
}

extension AboutViewController: UIWebViewDelegate {
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    if navigationType == .LinkClicked && request.URL!.absoluteString.hasPrefix("http") {
      UIApplication.sharedApplication().openURL(request.URL!)
      return false
    }
    
    return true
  }
}