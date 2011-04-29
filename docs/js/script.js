/**
*
* Main app file, this one is responsible of the load of any used modules so as to their initilisation
* against dom elements.
*
* Keep in mind that you can get a quick access to the internal stored object with container.data('modulename')
*
*/
(function($) {

    require(
    
    // Load in modules  
    ['app/modules/wiki', 'app/modules/messaging', 'app/modules/history', 'app/modules/highlight', 'app/modules/disqus', 'app/modules/ga'],
    
    function(wiki, messaging, history, highlight, ga) {
        
        $(function() {
          var container = $('#container');
          
          container
              // Needed prior main module initialization
              // This misconception leads to unexpected behaviour on Opera 11 
              // (haschange binding needed prior hash rewrite)
              .history()
          
              // Our main module
              .wikiConvertor({
                  wikiPath: container.data('wiki') || '',
                  main: '.wikiconvertor-content'
              });
        });
    });
    
})(this.jQuery);
