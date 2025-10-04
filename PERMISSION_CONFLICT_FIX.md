# Permission Conflict Fix

## 🐛 Muammo
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: 
[firebase_messaging/unknown] A request for permissions is already running, 
please wait for it to finish before doing another request.
```

## 🔍 Sabab
Bir vaqtning o'zida **2 ta permission request** ketgan edi:

1. `FirebaseMessaging.instance.requestPermission()` - 22-qatorda
2. `AwesomeNotifications().requestPermissionToSendNotifications()` - 27-qatorda

Bu ikkalasi parallel ravishda ishga tushib, conflict yaratgan.

## ✅ Yechim

### Noto'g'ri Kod (Eski):
```dart
await FirebaseMessaging.instance.requestPermission();
await FirebaseMessaging.instance.getAPNSToken();

await Permission.microphone.request();

// ❌ Alohida permission request
await AwesomeNotifications().requestPermissionToSendNotifications();

// Setup foreground message handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  AwesomeNotificationHelper.showNotificationFromFirebase(message);
});
```

### To'g'ri Kod (Yangi):
```dart
// Firebase Messaging permission
await FirebaseMessaging.instance.requestPermission();
await FirebaseMessaging.instance.getAPNSToken();

// Microphone permission
await Permission.microphone.request();

// ✅ Initialize AwesomeNotifications (bu ichida permission request bor)
await AwesomeNotificationHelper.initialize();

// Setup foreground message handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  debugPrint('📱 Foreground notification received!');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // Show notification using AwesomeNotifications
  AwesomeNotificationHelper.showNotificationFromFirebase(message);
});
```

## 📝 Tushuntirish

### AwesomeNotificationHelper.initialize() ichida:
```dart
static Future<void> initialize() async {
  await AwesomeNotifications().initialize(
    null,
    [NotificationChannel(...)],
    debug: true,
  );

  // ✅ Bu yerda allaqachon permission request bor
  await requestPermissions();

  setupListeners();
}

static Future<bool> requestPermissions() async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  return isAllowed;
}
```

Shuning uchun alohida `AwesomeNotifications().requestPermissionToSendNotifications()` chaqirish kerak emas!

## 🔧 O'zgarishlar

### LMS-RS/lib/main.dart:
```diff
- import 'package:awesome_notifications/awesome_notifications.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  ...
  
- await AwesomeNotifications().requestPermissionToSendNotifications();
+ // Initialize AwesomeNotifications (bu ichida permission request bor)
+ await AwesomeNotificationHelper.initialize();
```

### Parent-RS/lib/main.dart:
```diff
+ // Firebase Messaging permission
  await FirebaseMessaging.instance.requestPermission();

+ // Microphone permission
  await Permission.microphone.request();

+ // Initialize AwesomeNotifications (bu ichida permission request bor)
  await AwesomeNotificationHelper.initialize();
```

## ✅ Natija

### Eski (Xato):
```
1. FirebaseMessaging.requestPermission() → Running...
2. AwesomeNotifications.requestPermission() → Running...
❌ CONFLICT! Both trying to request at same time
```

### Yangi (To'g'ri):
```
1. FirebaseMessaging.requestPermission() → ✅ Complete
2. Permission.microphone.request() → ✅ Complete
3. AwesomeNotificationHelper.initialize() → ✅ Complete
   └─ AwesomeNotifications.requestPermission() → ✅ Complete
4. FirebaseMessaging.onMessage.listen() → ✅ Setup
```

## 🧪 Test

```bash
flutter analyze  # ✅ 0 errors
```

### Console Output (To'g'ri):
```
✅ AwesomeNotifications initialized
✅ Notification permissions granted
✅ Foreground message handler setup
✅ FCM token refresh listener setup
```

### Console Output (Eski - Xato):
```
❌ [ERROR] A request for permissions is already running
```

## 📁 O'zgartirilgan Fayllar

- ✅ `LMS-RS/lib/main.dart`
- ✅ `Parent-RS/lib/main.dart`

## 💡 Xulosa

**Muammo:** Parallel permission request'lar conflict yaratgan  
**Yechim:** `AwesomeNotificationHelper.initialize()` ishlatish (bu ichida permission request bor)  
**Natija:** Conflict yo'q, barcha permission'lar ketma-ket so'raladi ✅

## 🎯 Best Practice

### ❌ Noto'g'ri:
```dart
await FirebaseMessaging.instance.requestPermission();
await AwesomeNotifications().requestPermissionToSendNotifications(); // Conflict!
```

### ✅ To'g'ri:
```dart
await FirebaseMessaging.instance.requestPermission();
await AwesomeNotificationHelper.initialize(); // Bu ichida permission request bor
```

Endi app muammosiz ishga tushadi va barcha permission'lar to'g'ri so'raladi! 🎉
