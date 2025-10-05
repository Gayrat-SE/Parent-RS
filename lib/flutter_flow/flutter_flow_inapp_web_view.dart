import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fcm_token_helper.dart';
import 'api_request_logger.dart';

class FlutterFlowInAppWebView extends StatefulWidget {
  const FlutterFlowInAppWebView({
    super.key,
    required this.content,
    this.onCreated,
    this.verticalScroll = true,
    this.horizontalScroll = true,
  });

  final String content;
  final Function(InAppWebViewController)? onCreated;
  final bool verticalScroll;
  final bool horizontalScroll;

  @override
  State<FlutterFlowInAppWebView> createState() =>
      _FlutterFlowInAppWebViewState();
}

class _FlutterFlowInAppWebViewState extends State<FlutterFlowInAppWebView> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.content)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsAirPlayForMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
        iframeAllow: "camera; microphone; autoplay",
        iframeAllowFullscreen: true,
        // Enhanced permission settings
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        // Android specific settings
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useHybridComposition: true,
        // iOS specific settings
        allowsLinkPreview: true,
        allowsBackForwardNavigationGestures: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.onCreated?.call(controller);
      },
      onPermissionRequest: (controller, request) async {
        debugPrint('🔐 WebView permission request for: ${request.resources}');

        // Handle permission requests for camera and microphone
        List<PermissionResourceType> grantedResources = [];

        for (var resource in request.resources) {
          if (resource == PermissionResourceType.MICROPHONE) {
            debugPrint('🎤 Microphone permission requested');

            // Check current status first
            final currentStatus = await Permission.microphone.status;
            debugPrint(
                '📊 Current microphone permission status: $currentStatus');

            if (currentStatus.isGranted) {
              debugPrint('✅ Microphone already granted');
              grantedResources.add(PermissionResourceType.MICROPHONE);
            } else if (currentStatus.isDenied) {
              // Request microphone permission
              debugPrint('🔄 Requesting microphone permission...');
              final micStatus = await Permission.microphone.request();
              debugPrint('📊 Microphone permission result: $micStatus');

              if (micStatus.isGranted) {
                debugPrint('✅ Microphone permission granted');
                grantedResources.add(PermissionResourceType.MICROPHONE);
              } else if (micStatus.isPermanentlyDenied) {
                debugPrint('🚫 Microphone permission permanently denied');
                // Use mounted check before showing dialog
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showPermissionDialog(context, 'microphone');
                    }
                  });
                }
              } else {
                debugPrint('❌ Microphone permission denied');
              }
            } else if (currentStatus.isPermanentlyDenied) {
              debugPrint(
                  '🚫 Microphone permission permanently denied - need to open settings');
              // Use mounted check before showing dialog
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showPermissionDialog(context, 'microphone');
                  }
                });
              }
            }
          } else if (resource == PermissionResourceType.CAMERA) {
            debugPrint('📷 Camera permission requested');

            final currentStatus = await Permission.camera.status;
            debugPrint('📊 Current camera permission status: $currentStatus');

            if (currentStatus.isGranted) {
              debugPrint('✅ Camera already granted');
              grantedResources.add(PermissionResourceType.CAMERA);
            } else if (currentStatus.isDenied) {
              debugPrint('🔄 Requesting camera permission...');
              final cameraStatus = await Permission.camera.request();
              debugPrint('📊 Camera permission result: $cameraStatus');

              if (cameraStatus.isGranted) {
                debugPrint('✅ Camera permission granted');
                grantedResources.add(PermissionResourceType.CAMERA);
              } else {
                debugPrint('❌ Camera permission denied');
              }
            }
          } else {
            // Grant other permissions by default
            debugPrint('✅ Granting permission for: $resource');
            grantedResources.add(resource);
          }
        }

        final action = grantedResources.isNotEmpty
            ? PermissionResponseAction.GRANT
            : PermissionResponseAction.DENY;

        debugPrint(
            '📋 Permission response: ${grantedResources.length}/${request.resources.length} granted - Action: $action');

        return PermissionResponse(
          resources: grantedResources,
          action: action,
        );
      },
      onConsoleMessage: (controller, consoleMessage) {
        // Log console messages for debugging
        debugPrint("WebView Console: ${consoleMessage.message}");
      },
      onLoadStart: (controller, url) {
        debugPrint("WebView started loading: $url");
      },
      onLoadStop: (controller, url) async {
        debugPrint("WebView finished loading: $url");

        // FCM tokenni olish va inject qilish
        final fcmToken = await FCMTokenHelper.getFCMToken();

        if (fcmToken != null) {
          // FCM tokenni webview ichiga inject qilish (faqat login endpoint uchun)
          await controller.evaluateJavascript(
            source: FCMTokenHelper.getTokenInjectionJS(fcmToken),
          );
          debugPrint("✅ FCM Token injected into WebView for LOGIN endpoint");
          debugPrint("📱 Token: $fcmToken");
        } else {
          debugPrint("⚠️ FCM Token is null, skipping injection");
        }

        // API Request Logger'ni inject qilish
        await controller.evaluateJavascript(
          source: APIRequestLogger.getRequestLoggerJS(),
        );
        debugPrint("✅ API Request Logger injected into WebView");

        // Inject JavaScript to handle getUserMedia and MediaRecorder with enhanced support
        await controller.evaluateJavascript(source: '''
          (function() {
            console.log('🎤 Initializing enhanced media permission handler...');

            // Store original getUserMedia
            const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);

            // Override getUserMedia with enhanced error handling and retry logic
            navigator.mediaDevices.getUserMedia = function(constraints) {
              console.log('📞 getUserMedia called with constraints:', JSON.stringify(constraints));

              return originalGetUserMedia(constraints)
                .then(function(stream) {
                  console.log('✅ Media access granted successfully');
                  console.log('📊 Stream tracks:', stream.getTracks().map(t => t.kind + ': ' + t.label).join(', '));
                  return stream;
                })
                .catch(function(error) {
                  console.error('❌ Media access error:', error.name, '-', error.message);

                  // Provide detailed error information
                  if (error.name === 'NotAllowedError') {
                    console.error('🚫 Permission denied by user or system policy');
                    console.error('💡 Suggestion: Check app permissions in device settings');
                  } else if (error.name === 'NotFoundError') {
                    console.error('🔍 No media device found');
                  } else if (error.name === 'NotReadableError') {
                    console.error('📵 Device is already in use or hardware error');
                  } else if (error.name === 'OverconstrainedError') {
                    console.error('⚙️ Constraints cannot be satisfied');
                  } else if (error.name === 'SecurityError') {
                    console.error('🔒 Security error - check HTTPS and permissions');
                  }

                  // Try with simplified constraints if audio was requested
                  if (constraints.audio && error.name === 'NotAllowedError') {
                    console.log('🔄 Attempting with simplified audio constraints...');
                    return originalGetUserMedia({ audio: true })
                      .then(function(stream) {
                        console.log('✅ Simplified audio access granted');
                        return stream;
                      })
                      .catch(function(retryError) {
                        console.error('❌ Retry also failed:', retryError.name);
                        throw error; // Throw original error
                      });
                  }

                  throw error;
                });
            };

            // Override permission query to always return granted for microphone
            if (navigator.permissions && navigator.permissions.query) {
              const originalQuery = navigator.permissions.query.bind(navigator.permissions);
              navigator.permissions.query = function(permissionDesc) {
                console.log('🔐 Permission query for:', permissionDesc.name);

                if (permissionDesc.name === 'microphone' || permissionDesc.name === 'camera') {
                  console.log('✅ Returning granted status for', permissionDesc.name);
                  return Promise.resolve({
                    state: 'granted',
                    onchange: null
                  });
                }

                return originalQuery(permissionDesc);
              };
            }

            // Fix MediaRecorder mimeType support for iOS/Safari
            if (typeof MediaRecorder !== 'undefined') {
              console.log('🎙️ Setting up MediaRecorder mimeType compatibility...');

              // Store original MediaRecorder
              const OriginalMediaRecorder = MediaRecorder;

              // Get supported mimeTypes for iOS/Safari
              const getSupportedMimeType = function() {
                const types = [
                  'audio/mp4',
                  'audio/webm;codecs=opus',
                  'audio/webm',
                  'audio/ogg;codecs=opus',
                  'audio/ogg',
                  'audio/wav',
                  ''  // Empty string means use default
                ];

                for (let type of types) {
                  if (type === '' || MediaRecorder.isTypeSupported(type)) {
                    console.log('✅ Supported mimeType found:', type || 'default');
                    return type;
                  }
                }

                console.log('⚠️ No specific mimeType supported, using default');
                return '';
              };

              // Override MediaRecorder constructor
              window.MediaRecorder = function(stream, options) {
                options = options || {};

                // If mimeType is specified but not supported, find a supported one
                if (options.mimeType && !MediaRecorder.isTypeSupported(options.mimeType)) {
                  console.warn('⚠️ Requested mimeType not supported:', options.mimeType);
                  const supportedType = getSupportedMimeType();
                  console.log('🔄 Using supported mimeType instead:', supportedType || 'default');

                  if (supportedType) {
                    options.mimeType = supportedType;
                  } else {
                    delete options.mimeType;
                  }
                }

                console.log('🎙️ Creating MediaRecorder with options:', JSON.stringify(options));
                return new OriginalMediaRecorder(stream, options);
              };

              // Copy static methods
              window.MediaRecorder.isTypeSupported = OriginalMediaRecorder.isTypeSupported.bind(OriginalMediaRecorder);

              // Copy prototype
              window.MediaRecorder.prototype = OriginalMediaRecorder.prototype;

              console.log('✅ MediaRecorder mimeType compatibility enabled');
            } else {
              console.warn('⚠️ MediaRecorder not available in this browser');
            }

            console.log('✅ Enhanced WebView media permission handler initialized');
          })();
        ''');
      },
      onReceivedError: (controller, request, error) {
        debugPrint("WebView error: ${error.description}");
      },
    );
  }

  void _showPermissionDialog(BuildContext context, String permissionType) {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                permissionType == 'microphone' ? Icons.mic : Icons.camera,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Ruxsat kerak'),
            ],
          ),
          content: Text(
            permissionType == 'microphone'
                ? 'Mikrofon funksiyasidan foydalanish uchun sozlamalarda ruxsat berishingiz kerak.\n\nSozlamalar → Parent-RS → Mikrofon → Ruxsat berish'
                : 'Kamera funksiyasidan foydalanish uchun sozlamalarda ruxsat berishingiz kerak.\n\nSozlamalar → Parent-RS → Kamera → Ruxsat berish',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Open app settings
                await openAppSettings();
              },
              child: const Text('Sozlamalarga o\'tish'),
            ),
          ],
        );
      },
    );
  }
}
