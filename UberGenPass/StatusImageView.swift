import UIKit

class StatusImageView: UIImageView {

  func animate() {
    UIView.animateWithDuration(0.25,
      animations: {
        self.transform = CGAffineTransformScale(self.transform, 1.5, 1.5)
      },
      completion: { (finished: Bool) in
        UIView.animateWithDuration(0.5, animations: { self.transform = CGAffineTransformIdentity })
      }
    )
  }
}
