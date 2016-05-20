import UIKit

extension UITextField {
  
  var isEmpty: Bool {
    return (self.text ?? "") == ""
  }
}
