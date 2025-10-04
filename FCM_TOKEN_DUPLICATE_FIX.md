# FCM Token Duplicate Fix

## Muammo
Backend engineer xabar berdi: FCM token 2 marta jo'natilmoqda, vergul bilan ajratilgan holda:

```
fPGniVGNQtaq-4VO9UQDEt:APA91bFuW6mveo7zk4WUnz7FURYYnObkXLpXjAmWJjb7bigVIlv9PqDKCcgDAQgAVzBfhNlGlKUVMx_zmc27t822LVfAZDhcJPSQu2eWvN2Hk5GMb7eeDX8, fPGniVGNQtaq-4VO9UQDEt:APA91bFuW6mveo7zk4WUnz7FURYYnObkXLpXjAmWJjb7bigVIlv9PqDKCcgDAQgAVzBfhNlGlKUVMx_zmc27t822LVfAZDhcJPSQu2eWvN2Hk5GMb7eeDX8
```

## Sabab
JavaScript interceptor'da header 2 marta qo'shilgan edi:

1. **Birinchi marta**: `XMLHttpRequest.prototype.send` da `this.setRequestHeader()` chaqirilganda
2. **Ikkinchi marta**: Override qilgan `setRequestHeader` metodi `originalSetRequestHeader` ni chaqirganda

Bu natijada bir xil header 2 marta qo'shildi va brauzer ularni vergul bilan birlashtirdi.

## Yechim

### XMLHttpRequest uchun:
```javascript
XMLHttpRequest.prototype.send = function(...args) {
  if (this._url && this._url.includes('/auth/login')) {
    // ✅ Agar token allaqachon qo'shilmagan bo'lsa, faqat o'shanda qo'shish
    if (!this._requestHeaders['X-FCM-Token'] && !this._requestHeaders['FCM-Token']) {
      // ✅ To'g'ridan-to'g'ri originalSetRequestHeader ni chaqirish
      originalSetRequestHeader.call(this, 'X-FCM-Token', '$fcmToken');
      originalSetRequestHeader.call(this, 'FCM-Token', '$fcmToken');
      this._requestHeaders['X-FCM-Token'] = '$fcmToken';
      this._requestHeaders['FCM-Token'] = '$fcmToken';
      console.log('🔐 FCM Token added to LOGIN request:', this._url);
    }
  }
  return originalSend.apply(this, args);
};
```

### Fetch API uchun:
```javascript
window.fetch = function(url, options = {}) {
  const urlString = typeof url === 'string' ? url : url.url;
  
  if (urlString && urlString.includes('/auth/login')) {
    options.headers = options.headers || {};
    
    if (options.headers instanceof Headers) {
      // ✅ Tekshirish: token mavjudmi?
      if (!options.headers.has('X-FCM-Token') && !options.headers.has('FCM-Token')) {
        options.headers.append('X-FCM-Token', '$fcmToken');
        options.headers.append('FCM-Token', '$fcmToken');
      }
    } else {
      // ✅ Tekshirish: token mavjudmi?
      if (!options.headers['X-FCM-Token'] && !options.headers['FCM-Token']) {
        options.headers['X-FCM-Token'] = '$fcmToken';
        options.headers['FCM-Token'] = '$fcmToken';
      }
    }
  }
  
  return originalFetch.call(this, url, options);
};
```

### Axios uchun:
```javascript
if (window.axios) {
  window.axios.interceptors.request.use(function(config) {
    if (config.url && config.url.includes('/auth/login')) {
      config.headers = config.headers || {};
      // ✅ Tekshirish: token mavjudmi?
      if (!config.headers['X-FCM-Token'] && !config.headers['FCM-Token']) {
        config.headers['X-FCM-Token'] = '$fcmToken';
        config.headers['FCM-Token'] = '$fcmToken';
      }
    }
    return config;
  });
}
```

## O'zgartirilgan Fayllar

### Parent-RS:
- ✅ `lib/flutter_flow/fcm_token_helper.dart`

### LMS-RS:
- ✅ `lib/flutter_flow/fcm_token_helper.dart`

## Natija
Endi FCM token faqat **1 marta** jo'natiladi:

```
X-FCM-Token: fPGniVGNQtaq-4VO9UQDEt:APA91bFuW6mveo7zk4WUnz7FURYYnObkXLpXjAmWJjb7bigVIlv9PqDKCcgDAQgAVzBfhNlGlKUVMx_zmc27t822LVfAZDhcJPSQu2eWvN2Hk5GMb7eeDX8
FCM-Token: fPGniVGNQtaq-4VO9UQDEt:APA91bFuW6mveo7zk4WUnz7FURYYnObkXLpXjAmWJjb7bigVIlv9PqDKCcgDAQgAVzBfhNlGlKUVMx_zmc27t822LVfAZDhcJPSQu2eWvN2Hk5GMb7eeDX8
```

## Test Qilish
1. Appni ishga tushiring
2. Login qiling
3. API Logger'ni oching (floating action button)
4. Login requestni ko'ring
5. Headers'da FCM token faqat 1 marta bo'lishini tekshiring

## Console Log
Endi console'da faqat 1 marta log ko'rinadi:
```
✅ FCM Token injected into WebView: fPGniVGNQtaq...
🔐 FCM Token added to LOGIN request: https://parent.rahimovschool.uz/auth/login
📱 Token: fPGniVGNQtaq...
```

## Xulosa
Muammo hal qilindi! Token duplicate qo'shilishi oldini olish uchun:
1. Header qo'shishdan oldin tekshirish qo'shildi
2. To'g'ridan-to'g'ri `originalSetRequestHeader` chaqiriladi
3. Barcha API turlari (XHR, Fetch, Axios) uchun fix qilindi
