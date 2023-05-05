import UIKit

public typealias SegueCallback = (_ segue: UIStoryboardSegue) -> Void

class AppViewController: UIViewController {
  
  public func performSegue(withIdentifier identifier: String, callback: @escaping SegueCallback) {
    self.performSegue(withIdentifier: identifier, sender: callback)
  }

  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let closure = sender as? SegueCallback {
      closure(segue)
    }
    else {
      super.prepare(for: segue, sender: sender)
    }
  }
}
