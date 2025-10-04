import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FCMTokenHelper {
  static String? _cachedToken;

  /// FCM tokenni olish
  static Future<String?> getFCMToken() async {
    try {
      // Agar token cache'da bo'lsa, uni qaytarish
      if (_cachedToken != null) {
        return _cachedToken;
      }

      // Firebase Messaging'dan tokenni olish
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        _cachedToken = token;
        debugPrint('FCM Token obtained: $token');
      } else {
        debugPrint('FCM Token is null');
      }

      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Token yangilanganda listener qo'shish
  static void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _cachedToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
    });
  }

  /// JavaScript kod - FCM tokenni webview ichida saqlash va request interceptor qo'shish
  /// Faqat login endpoint'ga token qo'shadi
  static String getTokenInjectionJS(String fcmToken) {
    return '''
      (function() {
        // FCM tokenni localStorage'ga saqlash
        window.fcmToken = '$fcmToken';
        localStorage.setItem('fcm_token', '$fcmToken');
        console.log('✅ FCM Token injected into WebView:', '$fcmToken');

        // XMLHttpRequest interceptor
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        const originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;

        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
          this._url = url;
          this._method = method;
          this._requestHeaders = this._requestHeaders || {};
          return originalOpen.call(this, method, url, ...rest);
        };

        XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
          this._requestHeaders = this._requestHeaders || {};
          this._requestHeaders[header] = value;
          return originalSetRequestHeader.call(this, header, value);
        };

        XMLHttpRequest.prototype.send = function(...args) {
          // Login endpoint'ga FCM token qo'shish
          if (this._url && this._url.includes('/auth/login')) {
            // Agar token allaqachon qo'shilmagan bo'lsa, faqat o'shanda qo'shish
            if (!this._requestHeaders['X-FCM-Token'] && !this._requestHeaders['FCM-Token']) {
              originalSetRequestHeader.call(this, 'X-FCM-Token', '$fcmToken');
              originalSetRequestHeader.call(this, 'FCM-Token', '$fcmToken');
              this._requestHeaders['X-FCM-Token'] = '$fcmToken';
              this._requestHeaders['FCM-Token'] = '$fcmToken';
              console.log('🔐 FCM Token added to LOGIN request:', this._url);
              console.log('📱 Token:', '$fcmToken');
            }
          }
          return originalSend.apply(this, args);
        };

        // Fetch API interceptor
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
          const urlString = typeof url === 'string' ? url : url.url;

          // Login endpoint'ga FCM token qo'shish
          if (urlString && urlString.includes('/auth/login')) {
            options.headers = options.headers || {};

            if (options.headers instanceof Headers) {
              // Agar token allaqachon mavjud bo'lmasa, qo'shish
              if (!options.headers.has('X-FCM-Token') && !options.headers.has('FCM-Token')) {
                options.headers.append('X-FCM-Token', '$fcmToken');
                options.headers.append('FCM-Token', '$fcmToken');
                console.log('🔐 FCM Token added to LOGIN fetch request:', urlString);
                console.log('📱 Token:', '$fcmToken');
              }
            } else {
              // Agar token allaqachon mavjud bo'lmasa, qo'shish
              if (!options.headers['X-FCM-Token'] && !options.headers['FCM-Token']) {
                options.headers['X-FCM-Token'] = '$fcmToken';
                options.headers['FCM-Token'] = '$fcmToken';
                console.log('🔐 FCM Token added to LOGIN fetch request:', urlString);
                console.log('📱 Token:', '$fcmToken');
              }
            }
          }

          return originalFetch.call(this, url, options);
        };

        // Axios interceptor (agar Axios ishlatilsa)
        if (window.axios) {
          window.axios.interceptors.request.use(function(config) {
            if (config.url && config.url.includes('/auth/login')) {
              config.headers = config.headers || {};
              // Agar token allaqachon mavjud bo'lmasa, qo'shish
              if (!config.headers['X-FCM-Token'] && !config.headers['FCM-Token']) {
                config.headers['X-FCM-Token'] = '$fcmToken';
                config.headers['FCM-Token'] = '$fcmToken';
                console.log('🔐 FCM Token added to LOGIN axios request:', config.url);
                console.log('📱 Token:', '$fcmToken');
              }
            }
            return config;
          });
        }

        console.log('✅ FCM Token interceptors initialized for LOGIN endpoint');
      })();
    ''';
  }

  /// Barcha requestlarga FCM token qo'shish uchun universal interceptor
  static String getUniversalTokenInjectionJS(String fcmToken) {
    return '''
      (function() {
        // FCM tokenni global o'zgaruvchiga saqlash
        window.fcmToken = '$fcmToken';
        localStorage.setItem('fcm_token', '$fcmToken');
        sessionStorage.setItem('fcm_token', '$fcmToken');
        console.log('FCM Token stored globally:', '$fcmToken');
        
        // XMLHttpRequest interceptor - BARCHA requestlar uchun
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        
        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
          this._url = url;
          this._method = method;
          return originalOpen.call(this, method, url, ...rest);
        };
        
        XMLHttpRequest.prototype.send = function(...args) {
          // Barcha HTTP requestlarga FCM token qo'shish
          this.setRequestHeader('X-FCM-Token', '$fcmToken');
          this.setRequestHeader('FCM-Token', '$fcmToken');
          console.log('FCM Token added to XHR request:', this._method, this._url);
          return originalSend.apply(this, args);
        };
        
        // Fetch API interceptor - BARCHA requestlar uchun
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
          options.headers = options.headers || {};
          
          if (options.headers instanceof Headers) {
            options.headers.append('X-FCM-Token', '$fcmToken');
            options.headers.append('FCM-Token', '$fcmToken');
          } else {
            options.headers['X-FCM-Token'] = '$fcmToken';
            options.headers['FCM-Token'] = '$fcmToken';
          }
          
          const urlString = typeof url === 'string' ? url : url.url;
          console.log('FCM Token added to fetch request:', urlString);
          
          return originalFetch.call(this, url, options);
        };
        
        // Axios interceptor (agar mavjud bo'lsa)
        if (window.axios) {
          window.axios.interceptors.request.use(function(config) {
            config.headers = config.headers || {};
            config.headers['X-FCM-Token'] = '$fcmToken';
            config.headers['FCM-Token'] = '$fcmToken';
            console.log('FCM Token added to axios request:', config.url);
            return config;
          });
        }
        
        console.log('Universal FCM Token interceptors initialized');
      })();
    ''';
  }
}
