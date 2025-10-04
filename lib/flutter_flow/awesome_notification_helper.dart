import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class AwesomeNotificationHelper {
  static const String channelKey = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';
  static const String channelDescription = 'Notification channel for important messages';

  /// Initialize AwesomeNotifications
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Default app icon
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: channelName,
          channelDescription: channelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );

    // Request notification permissions
    await requestPermissions();

    // Set up notification listeners
    setupListeners();
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  /// Setup notification action listeners
  static void setupListeners() {
    // Listen when user taps on notification
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Called when notification is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('📬 Notification created: ${receivedNotification.id}');
  }

  /// Called when notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('📱 Notification displayed: ${receivedNotification.title}');
  }

  /// Called when notification is dismissed
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('🗑️ Notification dismissed: ${receivedAction.id}');
  }

  /// Called when user taps on notification
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('👆 Notification tapped: ${receivedAction.buttonKeyPressed}');
    
    // Handle notification tap action here
    // You can navigate to specific screen based on payload
    if (receivedAction.payload != null) {
      final payload = receivedAction.payload!;
      debugPrint('Payload: $payload');
      
      // Example: Navigate based on payload
      // if (payload['screen'] == 'home') {
      //   navigatorKey.currentState?.pushNamed('/home');
      // }
    }
  }

  /// Show notification from Firebase message
  static Future<void> showNotificationFromFirebase(RemoteMessage message) async {
    debugPrint('🔔 Showing foreground notification');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Extract notification data
    final title = message.notification?.title ?? 'New Message';
    final body = message.notification?.body ?? '';
    final imageUrl = message.notification?.android?.imageUrl ?? 
                     message.notification?.apple?.imageUrl;
    
    // Create notification payload from message data
    final Map<String, String?> payload = {};
    message.data.forEach((key, value) {
      payload[key] = value.toString();
    });

    // Show notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: channelKey,
        title: title,
        body: body,
        bigPicture: imageUrl,
        notificationLayout: imageUrl != null 
            ? NotificationLayout.BigPicture 
            : NotificationLayout.Default,
        payload: payload,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: false,
        autoDismissible: true,
        backgroundColor: Colors.white,
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'OPEN',
          label: 'Open',
          autoDismissible: true,
        ),
      ],
    );

    debugPrint('✅ Foreground notification shown successfully');
  }

  /// Show simple notification
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: channelKey,
        title: title,
        body: body,
        payload: payload,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        autoDismissible: true,
      ),
    );
  }

  /// Cancel notification by ID
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Check if notifications are allowed
  static Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }
}

