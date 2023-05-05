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

  func updateLabel() {
    self.label.text = String(Int(self.value))
    self.setDividerImage(self.imageFromView(self.label), forLeftSegmentState: .normal, rightSegmentState: .normal)
    self.setDividerImage(self.imageFromView(self.label), forLeftSegmentState: .normal, rightSegmentState: .highlighted)
    self.setDividerImage(self.imageFromView(self.label), forLeftSegmentState: .highlighted, rightSegmentState: .normal)
    self.setDividerImage(self.imageFromView(self.label), forLeftSegmentState: .highlighted, rightSegmentState: .highlighted)
  }

  //MARK: Private
  
  private func initLabel() {
    self.label.frame = CGRect(x: 0, y: 0, width: 30, height: self.frame.size.height)
    self.label.backgroundColor = .clear
    
    self.label.textAlignment = .center
    self.label.textColor = self.tintColor
    self.label.adjustsFontSizeToFitWidth = true

    self.updateLabel()
  }
  
  private func imageFromView(_ view: UIView) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
    
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return image
  }
}
