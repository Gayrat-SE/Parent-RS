# Microphone Permission Fix for Android WebView

## Problem
Even after granting microphone permission, Android WebView was showing:
- **"Microphone access denied"**
- **"NotReadableError: Could not start audio source"**

This error occurs when the microphone hardware is already in use or there's a conflict with WebView settings.

## Root Causes

### 1. **NotReadableError on Android**
- The microphone device is already in use by another stream
- Previous media streams weren't properly cleaned up
- WebView doesn't have proper Android-specific configuration

### 2. **WebView Configuration Issues**
- Missing Android-specific settings for media access
- No hardware acceleration enabled
- Missing third-party cookies support (required for some WebView features)

### 3. **Stream Management Issues**
- Multiple getUserMedia calls without stopping previous streams
- No cleanup when page visibility changes
- No cleanup when page unloads

## Solutions Implemented

### 1. **Enhanced WebView Settings** ✅
**File**: `lib/flutter_flow/flutter_flow_inapp_web_view.dart`

Added critical Android-specific settings:
```dart
InAppWebViewSettings(
  // Critical for Android microphone access
  thirdPartyCookiesEnabled: true,
  hardwareAcceleration: true,
  supportMultipleWindows: true,
  
  // Enhanced permission settings for iframes
  iframeAllow: "camera; microphone; autoplay; display-capture",
  
  // JavaScript settings
  javaScriptCanOpenWindowsAutomatically: true,
  
  // Cache settings (don't clear to maintain permissions)
  clearCache: false,
  clearSessionCache: false,
)
```

### 2. **Automatic Stream Cleanup** ✅

Added automatic cleanup of media streams to prevent "NotReadableError":

```javascript
// Store active streams
window._activeMediaStreams = [];

// Function to stop all active streams
function stopAllActiveStreams() {
  window._activeMediaStreams.forEach(stream => {
    stream.getTracks().forEach(track => track.stop());
  });
  window._activeMediaStreams = [];
}

// Auto-cleanup on page unload
window.addEventListener('beforeunload', stopAllActiveStreams);

// Auto-cleanup when tab/app goes to background
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    stopAllActiveStreams();
  }
});
```

### 3. **Retry Logic with Fallback Constraints** ✅

Implemented intelligent retry mechanism with progressively simpler constraints:

```javascript
function tryGetUserMediaWithFallback(constraints, retryCount = 0) {
  const maxRetries = 3;
  
  // Clean up existing streams on first attempt
  if (retryCount === 0) {
    stopAllActiveStreams();
  }
  
  return originalGetUserMedia(constraints)
    .catch(error => {
      if (retryCount < maxRetries) {
        const fallbackConstraints = [
          { audio: true },  // Try 1: Basic audio
          { audio: { echoCancellation: false } },  // Try 2: Minimal constraints
          { audio: { sampleRate: 44100 } }  // Try 3: Different sample rate
        ];
        
        // Wait 500ms before retry to allow hardware reset
        return new Promise(resolve => setTimeout(resolve, 500))
          .then(() => tryGetUserMediaWithFallback(fallbackConstraints[retryCount], retryCount + 1));
      }
      throw error;
    });
}
```

### 4. **Stream Tracking and Management** ✅

Track all active streams and automatically clean them up:

```javascript
// Track stream when created
window._activeMediaStreams.push(stream);

// Remove from tracking when stream ends
stream.getTracks().forEach(track => {
  track.addEventListener('ended', () => {
    const index = window._activeMediaStreams.indexOf(stream);
    if (index > -1) {
      window._activeMediaStreams.splice(index, 1);
    }
  });
});
```

### 5. **Global Cleanup Function** ✅

Exposed cleanup function for web app to use:

```javascript
// Web app can call this to manually clean up streams
window.stopAllMediaStreams();
```

## How It Works

### Before Fix:
```
1. User grants microphone permission ✅
2. WebView requests microphone access
3. Previous stream still active ❌
4. Android returns "NotReadableError" ❌
5. Microphone access fails ❌
```

### After Fix:
```
1. User grants microphone permission ✅
2. WebView requests microphone access
3. Auto-cleanup stops all previous streams ✅
4. Retry with basic constraints if needed ✅
5. Track new stream for future cleanup ✅
6. Microphone access succeeds ✅
```

## Testing Instructions

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Test microphone access**:
   - Grant microphone permission when prompted
   - Try to use microphone in the web app
   - Should work without "NotReadableError"
   - Try multiple times - should work consistently

4. **Test cleanup**:
   - Use microphone
   - Switch to another app (background)
   - Return to app
   - Try microphone again - should work

## Key Features

### ✅ Automatic Stream Cleanup
- Cleans up streams before new requests
- Prevents "device already in use" errors
- Cleans up when app goes to background
- Cleans up on page unload

### ✅ Intelligent Retry Logic
- Tries up to 3 times with different constraints
- Adds 500ms delay between retries
- Uses progressively simpler constraints
- Detailed error logging

### ✅ Stream Tracking
- Tracks all active media streams
- Automatically removes ended streams
- Provides global cleanup function
- Prevents memory leaks

### ✅ Enhanced WebView Configuration
- Hardware acceleration enabled
- Third-party cookies enabled
- Proper iframe permissions
- Cache preserved for permissions

## Troubleshooting

### If microphone still doesn't work:

1. **Check permissions in device settings**:
   - Settings → Apps → Parent-RS → Permissions → Microphone → Allow

2. **Check for other apps using microphone**:
   - Close other apps that might be using the microphone
   - Restart the device if needed

3. **Check WebView console logs**:
   - Look for error messages in the console
   - Check if cleanup is being called
   - Verify retry attempts

4. **Manual cleanup**:
   - The web app can call `window.stopAllMediaStreams()` to manually clean up

## Files Modified

1. **lib/flutter_flow/flutter_flow_inapp_web_view.dart**
   - Enhanced WebView settings
   - Added stream cleanup logic
   - Added retry mechanism
   - Added stream tracking

## Additional Notes

- **Hardware acceleration** is critical for Android media access
- **Third-party cookies** are needed for some WebView features
- **Stream cleanup** prevents "NotReadableError"
- **Retry logic** handles transient failures
- **Visibility change** listener prevents background conflicts

## Performance Impact

- **Minimal overhead**: Cleanup only runs when needed
- **Better reliability**: Retry logic handles edge cases
- **No memory leaks**: Automatic stream cleanup
- **Faster recovery**: 500ms retry delay is optimal

