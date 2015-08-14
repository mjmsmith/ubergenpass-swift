import UIKit

class LabelStepper: UIStepper {
  var label: UILabel

  override init(frame: CGRect) {
    self.label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    super.init(frame: frame)
    self.initLabel()
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    super.init(coder: aDecoder)
    self.initLabel()
  }

  override func dividerImageForLeftSegmentState(state: UIControlState, rightSegmentState: UIControlState) -> UIImage? {
    self.label.text = String(Int(self.value))
    
    return self.imageFromView(self.label)
  }

  private func initLabel() {
    self.label.frame = CGRect(x: 0, y: 0, width: 30, height: self.frame.size.height)
    
    self.label.textAlignment = .Center
    self.label.textColor = self.tintColor
    self.label.adjustsFontSizeToFitWidth = true
    
    self.setDividerImage(self.imageFromView(self.label), forLeftSegmentState: .Normal, rightSegmentState: .Normal)
  }
  
  private func imageFromView(view: UIView) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
    
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return image
  }
}
