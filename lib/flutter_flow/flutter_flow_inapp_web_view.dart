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
        iframeAllow: "camera; microphone",
        iframeAllowFullscreen: true,
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
        // Handle permission requests for camera and microphone
        List<PermissionResourceType> resources = [];

        for (var resource in request.resources) {
          if (resource == PermissionResourceType.MICROPHONE) {
            // Request microphone permission
            final micStatus = await Permission.microphone.request();
            if (micStatus.isGranted) {
              resources.add(PermissionResourceType.MICROPHONE);
            }
          } else if (resource == PermissionResourceType.CAMERA) {
            // Request camera permission
            final cameraStatus = await Permission.camera.request();
            if (cameraStatus.isGranted) {
              resources.add(PermissionResourceType.CAMERA);
            }
          } else {
            resources.add(resource);
          }
        }

        return PermissionResponse(
          resources: resources,
          action: resources.isNotEmpty
              ? PermissionResponseAction.GRANT
              : PermissionResponseAction.DENY,
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

        // Inject JavaScript to handle getUserMedia
        await controller.evaluateJavascript(source: '''
          (function() {
            // Override getUserMedia to provide better error handling
            const originalGetUserMedia = navigator.mediaDevices.getUserMedia;

            navigator.mediaDevices.getUserMedia = function(constraints) {
              console.log('getUserMedia called with constraints:', JSON.stringify(constraints));

              return originalGetUserMedia.call(this, constraints)
                .then(function(stream) {
                  console.log('Microphone/Camera access granted successfully');
                  return stream;
                })
                .catch(function(error) {
                  console.error('Media access error:', error.name, error.message);
                  throw error;
                });
            };

            console.log('WebView media permission handler initialized');
          })();
        ''');
      },
      onReceivedError: (controller, request, error) {
        debugPrint("WebView error: ${error.description}");
      },
    );
  }
}
