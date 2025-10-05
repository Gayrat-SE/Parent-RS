# 🎤 iOS Microphone Permission - To'liq Sozlash Qo'llanmasi

## ❌ Muammo

iOS'da:
- Microphone permission so'ralmayapti
- Settings → App → **Microphone toggle ko'rinmayapti**
- `NotAllowedError` xatosi

## 🔍 Sabab

iOS'da **microphone toggle Settings'da faqat app birinchi marta permission so'ragandan keyin paydo bo'ladi!**

Agar app hech qachon permission so'ramasa:
- ❌ Toggle yaratilmaydi
- ❌ Foydalanuvchi ruxsat bera olmaydi
- ❌ Microphone ishlamaydi

## ✅ Yechim - 5 Qadam

### 1️⃣ Info.plist Tekshirish

**Fayl:** `ios/Runner/Info.plist`

Quyidagi key mavjudligini tekshiring:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to enable audio recording features within the learning management system, including voice assignments, audio feedback, and interactive educational content.</string>
```

✅ **Bizda bor!**

### 2️⃣ Podfile Konfiguratsiyasi

**Fayl:** `ios/Podfile`

`post_install` blokida quyidagi kod bo'lishi kerak:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
      
      # Permission handler configuration
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

✅ **Qo'shildi!**

### 3️⃣ Pods Qayta O'rnatish

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

✅ **Bajarildi!**

### 4️⃣ Flutter Clean Build

```bash
flutter clean
flutter pub get
```

✅ **Bajarildi!**

### 5️⃣ Xcode orqali Run Qilish (MUHIM!)

**Bu eng muhim qadam!**

```bash
# Terminal'dan
open ios/Runner.xcworkspace

# Yoki
flutter run
```

**Nima bo'ladi:**
1. App ochiladi
2. HomePage yuklanadi
3. **Permission dialog AVTOMATIK ko'rinadi:**
   ```
   ┌─────────────────────────────────────┐
   │  "RS ota-onalar" Would Like to      │
   │  Access the Microphone              │
   │                                     │
   │  This app requires microphone       │
   │  access to enable audio recording   │
   │  features...                        │
   │                                     │
   │  [Don't Allow]  [OK]                │
   └─────────────────────────────────────┘
   ```

4. **"OK" bosing**
5. **Endi Settings → RS ota-onalar → Microphone toggle PAYDO BO'LADI!** ✅

## 🔍 Tekshirish

### Qadam 1: Permission Dialog Ko'rinishini Tekshirish

```bash
flutter run --verbose
```

Loglarni kuzating:
```
🎤 Starting microphone permission request...
📊 Current microphone status: PermissionStatus.denied
🔄 Requesting microphone permission from user...
```

**Agar dialog ko'rinmasa:**
1. Qurilmani qayta ishga tushiring
2. App'ni to'liq o'chiring (uninstall)
3. Qayta build qiling va o'rnating

### Qadam 2: Settings'da Toggle Tekshirish

**Faqat permission so'ralgandan KEYIN:**

1. Settings app'ni oching
2. Pastga aylantiring → "RS ota-onalar" ni toping
3. Ichiga kiring
4. **"Microphone" toggle ko'rinishi kerak!** ✅

**Agar ko'rinmasa:**
- App hali permission so'ramagan
- Info.plist'da `NSMicrophoneUsageDescription` yo'q
- Podfile'da `PERMISSION_MICROPHONE=1` yo'q

## 🐛 Troubleshooting

### Problem 1: Dialog Ko'rinmayapti

**Sabab:** Permission request noto'g'ri vaqtda yoki noto'g'ri context'da

**Yechim:**
```dart
// lib/pages/home_page/home_page_widget.dart
@override
void initState() {
  super.initState();
  _model = createModel(context, () => HomePageModel());
  WidgetsBinding.instance.addObserver(this);
  
  // MUHIM: PostFrameCallback ishlatish
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PermissionRequestHelper.requestMicrophonePermission(context);
  });
}
```

### Problem 2: Toggle Settings'da Yo'q

**Sabab:** App hech qachon permission so'ramagan

**Yechim:**
1. App'ni to'liq o'chiring (uninstall)
2. `flutter clean`
3. `cd ios && pod install`
4. `flutter run`
5. Permission dialog paydo bo'lishini kuting
6. "OK" bosing
7. Endi Settings'ga boring - toggle bo'lishi kerak!

### Problem 3: "Permanently Denied" Xatosi

**Sabab:** Avval "Don't Allow" bosilgan

**Yechim:**
1. App'ni to'liq o'chiring
2. Settings → General → iPhone Storage → RS ota-onalar → Delete App
3. Qurilmani qayta ishga tushiring
4. App'ni qayta o'rnating
5. Permission dialog qayta ko'rinadi

### Problem 4: Simulator'da Ishlamayapti

**Sabab:** Simulator'da microphone yo'q

**Yechim:**
- **Haqiqiy qurilmada test qiling!**
- Simulator faqat UI test uchun, microphone test qilish uchun emas

## 📱 Real Device Test

### iOS Device'da Test Qilish:

1. **Device'ni kompyuterga ulang**

2. **Xcode'da device'ni tanlang:**
   ```bash
   open ios/Runner.xcworkspace
   # Xcode'da: Product → Destination → Your iPhone
   ```

3. **Run qiling:**
   ```bash
   flutter run -d <device-id>
   ```

4. **Permission dialog ko'rinishini kuting**

5. **"OK" bosing**

6. **Settings'da toggle paydo bo'lishini tekshiring:**
   - Settings → RS ota-onalar → Microphone ✅

## 🎯 Expected Behavior

### Birinchi Ochilish:
```
App Launch
  ↓
HomePage Load
  ↓
PostFrameCallback
  ↓
Permission Request
  ↓
📱 DIALOG APPEARS ← MUHIM!
  ↓
User taps "OK"
  ↓
✅ Permission Granted
  ↓
🎤 Microphone Works
  ↓
⚙️ Toggle appears in Settings
```

### Keyingi Ochilishlar:
```
App Launch
  ↓
HomePage Load
  ↓
Check Permission Status
  ↓
✅ Already Granted
  ↓
🎤 Microphone Works Immediately
```

## 📋 Checklist

Quyidagilarni tekshiring:

- [ ] `NSMicrophoneUsageDescription` Info.plist'da bor
- [ ] `PERMISSION_MICROPHONE=1` Podfile'da bor
- [ ] `pod install` bajarilgan
- [ ] `flutter clean` bajarilgan
- [ ] App to'liq o'chirilgan (uninstall)
- [ ] Haqiqiy device'da test qilinmoqda (simulator emas)
- [ ] Permission dialog ko'rinadi
- [ ] "OK" bosilgan
- [ ] Settings'da toggle paydo bo'lgan
- [ ] Microphone ishlayapti

## 🔧 Qo'shimcha Konfiguratsiya

### Agar Hali Ham Ishlamasa:

1. **Xcode'da Capabilities Tekshirish:**
   ```
   Xcode → Runner → Signing & Capabilities
   ```
   
   Quyidagilar bo'lishi kerak:
   - ✅ Background Modes (Remote notifications)
   - ✅ Push Notifications

2. **Build Settings Tekshirish:**
   ```
   Xcode → Runner → Build Settings
   ```
   
   Qidirish: "Preprocessor"
   
   `GCC_PREPROCESSOR_DEFINITIONS` da bo'lishi kerak:
   ```
   PERMISSION_MICROPHONE=1
   ```

3. **Provisioning Profile:**
   - Development profile to'g'ri tanlanganligini tekshiring
   - Agar kerak bo'lsa, yangi profile yarating

## 📞 Yordam

Agar hamma narsani to'g'ri qilgan bo'lsangiz lekin hali ham ishlamasa:

1. **Loglarni yuboring:**
   ```bash
   flutter run --verbose > logs.txt 2>&1
   ```

2. **Xcode console'ni tekshiring:**
   - Xcode → View → Debug Area → Show Debug Area
   - Permission bilan bog'liq xatolarni qidiring

3. **iOS versiyasini tekshiring:**
   - iOS 15.0+ kerak (Podfile'da `platform :ios, '15.0.0'`)

## ✅ Xulosa

**Eng muhim qoidalar:**

1. ✅ Info.plist'da `NSMicrophoneUsageDescription` bo'lishi SHART
2. ✅ Podfile'da `PERMISSION_MICROPHONE=1` bo'lishi SHART
3. ✅ Permission request UI context'da bo'lishi SHART (PostFrameCallback)
4. ✅ **Permission dialog ko'rinishi SHART** - faqat shundan keyin Settings'da toggle paydo bo'ladi!
5. ✅ Haqiqiy device'da test qilish SHART (simulator emas)

**Agar permission dialog ko'rinsa va "OK" bosilsa - hammasi ishlaydi!** 🎉

