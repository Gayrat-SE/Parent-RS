import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_inapp_web_view.dart';
import '/flutter_flow/permission_request_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with WidgetsBindingObserver {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  InAppWebViewController? _controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    WidgetsBinding.instance.addObserver(this);

    // Request microphone permission after a delay to ensure:
    // 1. App UI is fully loaded
    // 2. Other permissions (notifications, Firebase messaging) are requested first
    // 3. User sees the app before being prompted
    // 4. No conflicts with other permission requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a 3-second delay to ensure:
      // - Notification permissions are requested and completed first
      // - Firebase messaging permissions are handled
      // - App is fully initialized and stable
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          debugPrint('🎤 Requesting microphone permission after delay...');
          PermissionRequestHelper.requestMicrophonePermission(context);
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app is resumed from background
    if (state == AppLifecycleState.resumed && _isControllerInitialized) {
      // Reload the WebView
      WidgetsBinding.instance.addPostFrameCallback((v) {
        _controller?.reload();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: FlutterFlowInAppWebView(
                  onCreated: (controller) async {
                    _controller = controller;
                    _isControllerInitialized = true;
                  },
                  content: 'https://parent.rahimovschool.uz',
                  verticalScroll: false,
                  horizontalScroll: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
