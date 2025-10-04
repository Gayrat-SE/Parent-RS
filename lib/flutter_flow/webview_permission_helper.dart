import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WebViewPermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.mycompany.parentrs/webview');
  
  static Future<bool> requestAndConfigurePermissions() async {
    try {
      // First, request permissions using permission_handler
      final microphoneStatus = await Permission.microphone.request();
      
      if (microphoneStatus.isGranted) {
        // Configure WebView permissions at native level
        final result = await _channel.invokeMethod('configureWebView');
        return result == true;
      } else if (microphoneStatus.isPermanentlyDenied) {
        // Open app settings if permanently denied
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error configuring WebView permissions: $e');
      return false;
    }
  }
  
  static Future<bool> checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    return microphoneStatus.isGranted;
  }
}
