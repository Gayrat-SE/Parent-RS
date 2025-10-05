import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestHelper {
  static bool _hasRequestedPermissions = false;

  /// Request microphone permission with UI context
  /// This should be called when the first screen loads
  static Future<void> requestMicrophonePermission(BuildContext context) async {
    // Only request once per app session
    if (_hasRequestedPermissions) {
      debugPrint('🔄 Permissions already requested this session');
      return;
    }

    _hasRequestedPermissions = true;

    debugPrint('🎤 Starting microphone permission request...');

    // Check current status
    final status = await Permission.microphone.status;
    debugPrint('📊 Current microphone status: $status');

    if (status.isGranted) {
      debugPrint('✅ Microphone permission already granted');
      return;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('🚫 Microphone permission permanently denied');
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return;
    }

    // Request permission
    debugPrint('🔄 Requesting microphone permission from user...');
    final result = await Permission.microphone.request();
    debugPrint('📊 Permission request result: $result');

    // Check if context is still valid before showing UI
    if (!context.mounted) {
      debugPrint('⚠️ Context no longer mounted, skipping UI feedback');
      return;
    }

    if (result.isGranted) {
      debugPrint('✅ Microphone permission granted!');
      _showPermissionGrantedSnackbar(context);
    } else if (result.isPermanentlyDenied) {
      debugPrint('🚫 Microphone permission permanently denied');
      _showPermissionDeniedDialog(context);
    } else if (result.isDenied) {
      debugPrint('❌ Microphone permission denied');
      _showPermissionDeniedSnackbar(context);
    }
  }

  static void _showPermissionGrantedSnackbar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('✅ Mikrofon ruxsati berildi'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static void _showPermissionDeniedSnackbar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('⚠️ Mikrofon ruxsati berilmadi'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Qayta urinish',
          textColor: Colors.white,
          onPressed: () {
            _hasRequestedPermissions = false;
            requestMicrophonePermission(context);
          },
        ),
      ),
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic_off, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mikrofon ruxsati kerak',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mikrofon funksiyasidan foydalanish uchun sozlamalarda ruxsat berishingiz kerak.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Qadamlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('1. "Sozlamalarga o\'tish" tugmasini bosing'),
              Text('2. "Mikrofon" ni toping'),
              Text('3. Ruxsat bering (ON/Yashil)'),
              Text('4. Ilovaga qaytib keling'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Keyinroq'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                debugPrint('🔧 Opening app settings...');
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Sozlamalarga o\'tish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophoneGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Reset the request flag (useful for testing)
  static void resetRequestFlag() {
    _hasRequestedPermissions = false;
  }
}
