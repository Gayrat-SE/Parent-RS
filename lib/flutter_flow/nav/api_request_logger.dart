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
        const originalXHROpen = XMLHttpRequest.prototype.open;
        const originalXHRSend = XMLHttpRequest.prototype.send;
        const originalXHRSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
        
        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
          this._method = method;
          this._url = url;
          this._requestHeaders = {};
          return originalXHROpen.call(this, method, url, ...rest);
        };
        
        XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
          this._requestHeaders = this._requestHeaders || {};
          this._requestHeaders[header] = value;
          return originalXHRSetRequestHeader.call(this, header, value);
        };
        
        XMLHttpRequest.prototype.send = function(body) {
          const timestamp = Date.now();
          const method = this._method || 'GET';
          const url = this._url || '';
          const headers = this._requestHeaders || {};
          
          let bodyData = null;
          if (body) {
            try {
              bodyData = typeof body === 'string' ? JSON.parse(body) : body;
            } catch (e) {
              bodyData = body.toString();
            }
          }
          
          logRequest('XMLHttpRequest', method, url, headers, bodyData, timestamp);
          
          return originalXHRSend.call(this, body);
        };
        
        // Fetch API interceptor
        const originalFetch = window.fetch;
        
        window.fetch = function(url, options = {}) {
          const timestamp = Date.now();
          const method = options.method || 'GET';
          const urlString = typeof url === 'string' ? url : url.url;
          const headers = {};
          
          // Headers'ni object'ga o'tkazish
          if (options.headers) {
            if (options.headers instanceof Headers) {
              options.headers.forEach((value, key) => {
                headers[key] = value;
              });
            } else {
              Object.assign(headers, options.headers);
            }
          }
          
          let bodyData = null;
          if (options.body) {
            try {
              bodyData = typeof options.body === 'string' ? JSON.parse(options.body) : options.body;
            } catch (e) {
              bodyData = options.body.toString();
            }
          }
          
          logRequest('Fetch', method, urlString, headers, bodyData, timestamp);
          
          return originalFetch.call(this, url, options);
        };
        
        // Axios interceptor (agar mavjud bo'lsa)
        if (window.axios) {
          window.axios.interceptors.request.use(function(config) {
            const timestamp = Date.now();
            const method = (config.method || 'GET').toUpperCase();
            const url = config.url || '';
            const headers = config.headers || {};
            const body = config.data || null;
            
            logRequest('Axios', method, url, headers, body, timestamp);
            
            return config;
          });
        }
        
        // jQuery AJAX interceptor (agar mavjud bo'lsa)
        if (window.jQuery && window.jQuery.ajax) {
          const originalAjax = window.jQuery.ajax;
          
          window.jQuery.ajax = function(url, options) {
            // jQuery.ajax(url, options) yoki jQuery.ajax(options) formatini qo'llab-quvvatlash
            if (typeof url === 'object') {
              options = url;
              url = options.url;
            }
            
            const timestamp = Date.now();
            const method = (options.type || options.method || 'GET').toUpperCase();
            const headers = options.headers || {};
            const body = options.data || null;
            
            logRequest('jQuery.ajax', method, url, headers, body, timestamp);
            
            return originalAjax.call(this, url, options);
          };
        }
        
        // Log'larni olish uchun helper funksiya
        window.getAPIRequestLogs = function() {
          return window.apiRequestLogs;
        };
        
        // Log'larni tozalash
        window.clearAPIRequestLogs = function() {
          window.apiRequestLogs = [];
          console.log('✅ API Request logs cleared');
        };
        
        // Endpoint'larni ajratib olish
        window.getUniqueEndpoints = function() {
          const endpoints = new Set();
          window.apiRequestLogs.forEach(log => {
            try {
              const url = new URL(log.url);
              endpoints.add(url.origin + url.pathname);
            } catch (e) {
              endpoints.add(log.url);
            }
          });
          return Array.from(endpoints);
        };
        
        // Method bo'yicha statistika
        window.getRequestStatsByMethod = function() {
          const stats = {};
          window.apiRequestLogs.forEach(log => {
            const method = log.method;
            stats[method] = (stats[method] || 0) + 1;
          });
          return stats;
        };
        
        // Endpoint bo'yicha statistika
        window.getRequestStatsByEndpoint = function() {
          const stats = {};
          window.apiRequestLogs.forEach(log => {
            try {
              const url = new URL(log.url);
              const endpoint = url.origin + url.pathname;
              stats[endpoint] = (stats[endpoint] || 0) + 1;
            } catch (e) {
              stats[log.url] = (stats[log.url] || 0) + 1;
            }
          });
          return stats;
        };
        
        // Log'larni JSON formatda export qilish
        window.exportAPIRequestLogs = function() {
          return JSON.stringify(window.apiRequestLogs, null, 2);
        };
        
        console.log('✅ API Request Logger ready');
        console.log('📊 Available functions:');
        console.log('  - window.getAPIRequestLogs()');
        console.log('  - window.clearAPIRequestLogs()');
        console.log('  - window.getUniqueEndpoints()');
        console.log('  - window.getRequestStatsByMethod()');
        console.log('  - window.getRequestStatsByEndpoint()');
        console.log('  - window.exportAPIRequestLogs()');
      })();
    ''';
  }

  /// Endpoint'larni Flutter'da parse qilish
  static List<String> parseEndpoints(String logsJson) {
    try {
      final endpoints = <String>{};
      // JSON parse qilish va endpoint'larni ajratib olish
      // Bu yerda kerak bo'lsa qo'shimcha logic qo'shish mumkin
      return endpoints.toList();
    } catch (e) {
      debugPrint('Error parsing endpoints: $e');
      return [];
    }
  }

  /// Log'larni formatlash
  static String formatLog(Map<String, dynamic> log) {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📡 API Request [${log['type']}]');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🔹 Method: ${log['method']}');
    buffer.writeln('🔹 URL: ${log['url']}');
    buffer.writeln('🔹 Time: ${log['datetime']}');

    if (log['headers'] != null) {
      buffer.writeln('🔹 Headers:');
      final headers = log['headers'] as Map<String, dynamic>;
      headers.forEach((key, value) {
        buffer.writeln('   $key: $value');
      });
    }

    if (log['body'] != null) {
      buffer.writeln('🔹 Body: ${log['body']}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }
}
