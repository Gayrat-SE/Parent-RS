class WebViewJSHelper {
  // JavaScript code to handle microphone permissions
  static const String microphonePermissionJS = '''
    (function() {
      // Override getUserMedia to handle permissions
      const originalGetUserMedia = navigator.mediaDevices.getUserMedia;
      
      navigator.mediaDevices.getUserMedia = function(constraints) {
        console.log('getUserMedia called with constraints:', constraints);
        
        // Try to get user media with error handling
        return originalGetUserMedia.call(this, constraints)
          .then(function(stream) {
            console.log('Microphone access granted successfully');
            return stream;
          })
          .catch(function(error) {
            console.error('Microphone access error:', error);
            
            // Try alternative approach
            if (constraints.audio) {
              console.log('Attempting alternative microphone access...');
              return originalGetUserMedia.call(navigator.mediaDevices, {
                audio: {
                  echoCancellation: false,
                  noiseSuppression: false,
                  autoGainControl: false
                }
              });
            }
            
            throw error;
          });
      };
      
      // Also handle the older getUserMedia API
      if (navigator.getUserMedia) {
        const oldGetUserMedia = navigator.getUserMedia;
        navigator.getUserMedia = function(constraints, success, error) {
          console.log('Legacy getUserMedia called');
          return oldGetUserMedia.call(this, constraints, success, error);
        };
      }
      
      // Handle permission queries
      if (navigator.permissions && navigator.permissions.query) {
        const originalQuery = navigator.permissions.query;
        navigator.permissions.query = function(permissionDesc) {
          console.log('Permission query for:', permissionDesc.name);
          
          if (permissionDesc.name === 'microphone') {
            // Return granted status for microphone
            return Promise.resolve({ state: 'granted' });
          }
          
          return originalQuery.call(this, permissionDesc);
        };
      }
      
      console.log('WebView microphone permission handler initialized');
    })();
  ''';
  
  // JavaScript to test microphone access
  static const String testMicrophoneJS = '''
    (function() {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ audio: true })
          .then(function(stream) {
            console.log('Microphone test: SUCCESS - Stream obtained');
            // Stop the stream immediately after test
            stream.getTracks().forEach(track => track.stop());
            return true;
          })
          .catch(function(error) {
            console.error('Microphone test: FAILED -', error.name, error.message);
            return false;
          });
      } else {
        console.error('Microphone test: getUserMedia not supported');
        return false;
      }
    })();
  ''';
}
