// Collabora Online Plugin JavaScript

document.addEventListener('DOMContentLoaded', function() {
  // Initialize Collabora Online iframe if present
  var collaboraFrame = document.getElementById('collabora-frame');
  
  if (collaboraFrame) {
    // Set focus on the iframe
    collaboraFrame.focus();
    
    // Log that Collabora Online is loaded
    console.log('Collabora Online frame loaded');
    
    // Optional: Add postMessage handling for communication with Collabora
    window.addEventListener('message', function(event) {
      // Handle messages from Collabora Online
      console.log('Message from Collabora:', event.data);
    });
  }
});
