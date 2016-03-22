var Action = function() {};

Action.prototype = {
  run: function(arguments) {
    arguments.completionFunction({ "URL": document.URL });
  }
};
    
var ExtensionPreprocessingJS = new Action;
