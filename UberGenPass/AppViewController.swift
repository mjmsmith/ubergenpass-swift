import UIKit

typealias PreparationClosure = (segue: UIStoryboardSegue) -> Void

private class PreparationClosureWrapper {
  
  let closure: PreparationClosure
  
  init(closure: PreparationClosure) {
    self.closure = closure
  }
}

class AppViewController: UIViewController {
  
  func performSegueWithIdentifier(identifier: String, preparation: PreparationClosure) {
    self.performSegueWithIdentifier(identifier, sender: PreparationClosureWrapper(closure: preparation))
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let closureWrapper = sender as? PreparationClosureWrapper {
      closureWrapper.closure(segue: segue)
    }
    else {
      super.prepareForSegue(segue, sender: sender)
    }
  }
}
