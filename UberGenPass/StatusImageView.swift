import UIKit

class StatusImageView: UIImageView {

  func animate() {
    UIView.animate(withDuration: 0.25,
      animations: {
        self.transform = CGAffineTransformScale(self.transform, 1.5, 1.5)
      },
      completion: { (finished: Bool) in
        UIView.animate(withDuration: 0.5, animations: { self.transform = CGAffineTransformIdentity })
      }
    )
  }
}
