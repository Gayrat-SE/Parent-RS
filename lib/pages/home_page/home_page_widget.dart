import 'package:webviewx_plus/webviewx_plus.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import 'package:flutter/material.dart';
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
  bool _isControllerInitialized = false;
  late final WebViewXController _controller;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _isControllerInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((v) {
        _controller.reload();
      });
    }
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
                child: FlutterFlowWebView(
                  onCreated: (controller) async {
                    _controller = controller;
                    _isControllerInitialized = true;
                    await _controller.reload();
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
