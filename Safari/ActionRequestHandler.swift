import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequestWithExtensionContext(context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
        
        var found = false
        
        // Find the item containing the results from the JavaScript preprocessing.
        outer:
            for item: AnyObject in context.inputItems {
                let extItem = item as! NSExtensionItem
                if let attachments = extItem.attachments {
                    for itemProvider: AnyObject in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePropertyList)) {
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypePropertyList), options: nil, completionHandler: { (item, error) in
                                let dictionary = item as! [String: AnyObject]
                                NSOperationQueue.mainQueue().addOperationWithBlock {
                                    self.itemLoadCompletedWithPreprocessingResults(dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! [NSObject: AnyObject])
                                }
                                found = true
                            })
                            if found {
                                break outer
                            }
                        }
                    }
                }
        }
        
        if !found {
            self.doneWithResults(nil)
        }
    }
    
    func itemLoadCompletedWithPreprocessingResults(javaScriptPreprocessingResults: [NSObject: AnyObject]) {
      let bgColor: AnyObject? = javaScriptPreprocessingResults["currentBackgroundColor"]
      if bgColor == nil ||  bgColor! as! String == "" {
          self.doneWithResults(["newBackgroundColor": "red"])
      } else {
          self.doneWithResults(["newBackgroundColor": "green"])
      }
  }
  
  func doneWithResults(resultsForJavaScriptFinalizeArg: [NSObject: AnyObject]?) {
    if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
      let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
      let resultsProvider = NSItemProvider(item: resultsDictionary, typeIdentifier: String(kUTTypePropertyList))
      let resultsItem = NSExtensionItem()

      resultsItem.attachments = [resultsProvider]
          
      self.extensionContext!.completeRequestReturningItems([resultsItem], completionHandler: nil)
    }
    else {
      self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }
      
    self.extensionContext = nil
  }
}
