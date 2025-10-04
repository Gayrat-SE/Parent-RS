import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_inapp_web_view.dart';
import '/flutter_flow/webview_permission_helper.dart';
import '/flutter_flow/api_logger_viewer.dart';
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

                    // Request and configure WebView permissions
                    await WebViewPermissionHelper
                        .requestAndConfigurePermissions();

                    debugPrint(
                        "InAppWebView created and configured for microphone access");
                  },
                  content: 'https://parent.rahimovschool.uz',
                  verticalScroll: false,
                  horizontalScroll: false,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_isControllerInitialized && _controller != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      APILoggerViewer(controller: _controller),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WebView not initialized yet'),
                ),
              );
            }
          },
          tooltip: 'View API Logs',
          child: const Icon(Icons.bug_report),
        ),
      ),
    );
  }
}
