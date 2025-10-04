import 'package:flutter/material.dart';

class APIRequestLogger {
  /// JavaScript kod - barcha API requestlarni log qilish
  static String getRequestLoggerJS() {
    return '''
      (function() {
        console.log('🚀 API Request Logger initialized');
        
        // Request log'larini saqlash uchun array
        window.apiRequestLogs = [];
        
        // Log funksiyasi
        function logRequest(type, method, url, headers, body, timestamp) {
          const log = {
            type: type,
            method: method,
            url: url,
            headers: headers,
            body: body,
            timestamp: timestamp,
            datetime: new Date(timestamp).toISOString()
          };
          
          window.apiRequestLogs.push(log);
          
          // Console'ga chiqarish
          console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          console.log('📡 API Request [' + type + ']');
          console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          console.log('🔹 Method:', method);
          console.log('🔹 URL:', url);
          console.log('🔹 Headers:', headers);

          // FCM Token header'ni alohida ko'rsatish
          if (headers['X-FCM-Token'] || headers['FCM-Token']) {
            console.log('🔐 FCM Token Header:', headers['X-FCM-Token'] || headers['FCM-Token']);
          }

          if (body) {
            console.log('🔹 Body:', body);
          }
          console.log('🔹 Time:', new Date(timestamp).toLocaleTimeString());
          console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Flutter'ga yuborish uchun
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('apiRequestLog', log);
          }
        }

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
          const timestamp = Date.now();
          const body = args[0] || null;
          
          logRequest('XHR', this._method, this._url, this._requestHeaders, body, timestamp);
          
          return originalSend.apply(this, args);
        };

        // Fetch API interceptor
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
          const timestamp = Date.now();
          const method = options.method || 'GET';
          const urlString = typeof url === 'string' ? url : url.url;
          const headers = {};
          
          // Headers'ni object formatiga o'tkazish
          if (options.headers) {
            if (options.headers instanceof Headers) {
              for (let [key, value] of options.headers.entries()) {
                headers[key] = value;
              }
            } else {
              Object.assign(headers, options.headers);
            }
          }
          
          const body = options.body || null;
          
          logRequest('FETCH', method, urlString, headers, body, timestamp);
          
          return originalFetch.call(this, url, options);
        };

        // Axios interceptor (agar mavjud bo'lsa)
        if (window.axios) {
          window.axios.interceptors.request.use(function(config) {
            const timestamp = Date.now();
            const method = (config.method || 'GET').toUpperCase();
            const url = config.url;
            const headers = config.headers || {};
            const body = config.data || null;
            
            logRequest('AXIOS', method, url, headers, body, timestamp);
            
            return config;
          });
        }

        // Log'larni olish uchun global funksiya
        window.getAPIRequestLogs = function() {
          return window.apiRequestLogs;
        };

        // Log'larni tozalash uchun global funksiya
        window.clearAPIRequestLogs = function() {
          window.apiRequestLogs = [];
          console.log('🧹 API Request logs cleared');
        };

        // Endpoint'larni olish uchun global funksiya
        window.getUniqueEndpoints = function() {
          const endpoints = new Set();
          window.apiRequestLogs.forEach(log => {
            if (log.url) {
              try {
                const urlObj = new URL(log.url, window.location.origin);
                endpoints.add(urlObj.pathname);
              } catch (e) {
                endpoints.add(log.url);
              }
            }
          });
          return Array.from(endpoints);
        };

        // Statistika olish uchun global funksiya
        window.getAPIRequestStats = function() {
          const stats = {
            total: window.apiRequestLogs.length,
            methods: {},
            endpoints: {},
            types: {}
          };

          window.apiRequestLogs.forEach(log => {
            // Method statistics
            stats.methods[log.method] = (stats.methods[log.method] || 0) + 1;
            
            // Type statistics
            stats.types[log.type] = (stats.types[log.type] || 0) + 1;
            
            // Endpoint statistics
            if (log.url) {
              try {
                const urlObj = new URL(log.url, window.location.origin);
                const endpoint = urlObj.pathname;
                stats.endpoints[endpoint] = (stats.endpoints[endpoint] || 0) + 1;
              } catch (e) {
                stats.endpoints[log.url] = (stats.endpoints[log.url] || 0) + 1;
              }
            }
          });

          return stats;
        };

        console.log('✅ API Request Logger interceptors initialized');
      })();
    ''';
  }

  /// Faqat ma'lum endpoint'lar uchun log qilish
  static String getSelectiveRequestLoggerJS(List<String> endpoints) {
    final endpointList = endpoints.map((e) => "'$e'").join(', ');
    
    return '''
      (function() {
        console.log('🚀 Selective API Request Logger initialized for endpoints: [$endpointList]');
        
        const targetEndpoints = [$endpointList];
        window.apiRequestLogs = [];
        
        function shouldLog(url) {
          return targetEndpoints.some(endpoint => url.includes(endpoint));
        }
        
        function logRequest(type, method, url, headers, body, timestamp) {
          if (!shouldLog(url)) return;
          
          const log = {
            type: type,
            method: method,
            url: url,
            headers: headers,
            body: body,
            timestamp: timestamp,
            datetime: new Date(timestamp).toISOString()
          };
          
          window.apiRequestLogs.push(log);
          console.log('📡 API Request [' + type + '] to ' + url);
        }

        // XMLHttpRequest interceptor
        const originalSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.send = function(...args) {
          if (shouldLog(this._url || '')) {
            logRequest('XHR', this._method, this._url, this._requestHeaders, args[0], Date.now());
          }
          return originalSend.apply(this, args);
        };

        // Fetch interceptor
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
          const urlString = typeof url === 'string' ? url : url.url;
          if (shouldLog(urlString)) {
            logRequest('FETCH', options.method || 'GET', urlString, options.headers, options.body, Date.now());
          }
          return originalFetch.call(this, url, options);
        };

        window.getAPIRequestLogs = function() { return window.apiRequestLogs; };
        window.clearAPIRequestLogs = function() { window.apiRequestLogs = []; };
        
        console.log('✅ Selective API Request Logger initialized');
      })();
    ''';
  }
}
