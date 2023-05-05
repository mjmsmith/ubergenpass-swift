import UIKit

protocol AboutViewControllerDelegate: AnyObject {
  func aboutViewControllerDidFinish(aboutViewController: AboutViewController)
}

class AboutViewController: AppViewController {
  
  weak var delegate: AboutViewControllerDelegate?
  
  @IBOutlet private weak var nameLabel: UILabel!
  @IBOutlet private weak var rateButton: UIButton!
  @IBOutlet private weak var webView: UIWebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
    
    self.nameLabel.text = "UberGenPass \(version)"

    self.rateButton.layer.cornerRadius = 8.0

    self.webView.delegate = self
    self.webView.scrollView.bounces = false
    self.webView.loadRequest(URLRequest(url: Bundle.main.url(forResource: "About", withExtension: "html")!))
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  
  // MARK: Actions
  
  @IBAction private func rate() {
    UIApplication.shared.open(URL(string: "https://apps.apple.com/app/id588224057")!)
  }

  @IBAction private func done() {
    self.delegate?.aboutViewControllerDidFinish(aboutViewController: self)
  }
}

extension AboutViewController: UIWebViewDelegate {

  func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
    if navigationType == .linkClicked,
       let url = request.url {
      UIApplication.shared.open(url)
      return false
    }
    
    return true
  }
}
