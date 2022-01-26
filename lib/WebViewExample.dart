import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

const debug = true;

class WebViewExample extends StatefulWidget {
  final TargetPlatform? platform;

  WebViewExample({Key? key, this.platform}) : super(key: key);

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController controller;
  bool isLoading = true;
  bool isLangEng = true;
  var url = 'https://emanage.net/mob';
  late String _localPath;
  late bool _permissionReady;
  var taskId;
  var _status;
  var _progressI;
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    _bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);

    _permissionReady = false;

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    _prepare();
    getMicrophonePer();
  }



  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: $data');
      }
      String? id = data[0];
      DownloadTaskStatus? status = data[1];
      int? progress = data[2];

      if (taskId != null && taskId!.isNotEmpty) {
        final task = taskId!.firstWhere((taskId) => taskId == id);
        setState(() {
          _status = status;
          _progressI = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<Null> _prepare() async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {

      await _prepareSaveDir();
    }
  }

  getMicrophonePer() async {
    PermissionStatus status = await Permission.microphone.request();
    print(status);
    bool mic = await Permission.microphone.isGranted;
    print('microphone permission? $mic');
    try {
      if (!mic) {
        PermissionStatus status = await Permission.microphone.request();
        print(status);
      }
    } catch (e) {
      print("message $e");
    }
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        var result = await Permission.storage.request();
        if (result == PermissionStatus.granted ) {
          print("storage True");
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<void> _prepareSaveDir() async {
    _localPath =
        (await _findLocalPath())! + Platform.pathSeparator + 'Download';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory?.path;
  }

  Widget navigationControls(
      Future<WebViewController> _webViewControllerFuture) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        bool webViewReady = snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data!;
        return webViewReady
            ? Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: !webViewReady
                        ? () {}
                        : () async {
                            if (await controller.canGoBack()) {
                              await controller.goBack();
                            } else {
                              Scaffold.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("No back history item")),
                              );
                              return;
                            }
                          },
                  ),
                ],
              )
            : Container();
      },
    );
  }

  void _requestDownload(link) async {
    taskId = await FlutterDownloader.enqueue(
        url: link,
        headers: {"auth": "test_for_sql_encoding"},
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true);
  }

  Future<bool> _openDownloadedFile() {
    if (taskId != null) {
      return FlutterDownloader.open(taskId: taskId);
    } else {
      return Future.value(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: (url == 'https://daralmaarefschools.com/cp')
      //      ? null
      //     : Drawer(
      //   child: ListView(
      //     children: [
      //       ListTile(
      //         leading: Icon(Icons.home),
      //         title: Text("Home"),
      //         onTap: () {
      //           Navigator.pop(context);
      //           url =
      //               "https://daralmaarefschools.com/cp";
      //           controller.loadUrl(url);
      //           setState(() {});
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.home),
      //         title: Text("Personal Data"),
      //         onTap: () {
      //           Navigator.pop(context);
      //           url =
      //               "https://daralmaarefschools.com/btn_01.php?Page_ID=1250";
      //           controller.loadUrl(url);
      //           setState(() {});
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      // appBar: AppBar(
      //   // leading: (url == 'https://daralmaarefschools.com/mob/')
      //   //     ? Container()
      //   //     : navigationControls(_controller.future),
      //   centerTitle: false,
      //   title: InkWell(
      //     onTap: (){
      //       url =
      //       "https://daralmaarefschools.com/cp";
      //       controller.loadUrl(url);
      //       setState(() {});
      //     },
      //     child: Text((url == 'https://daralmaarefschools.com/mob/')
      //         ? 'Sign In'
      //         : 'My School'),
      //   ),
      //   actions: <Widget>[
      //     FlatButton.icon(
      //       onPressed: () {
      //         isLangEng = !isLangEng;
      //         url =
      //         "https://daralmaarefschools.com/cp/${isLangEng ? "ar" : "en"}";
      //         controller.loadUrl(url);
      //         setState(() {});
      //       },
      //       icon: Icon(Icons.language_sharp, color: Colors.white),
      //       label: Text(
      //         isLangEng ? "English" : "عربي",
      //         style: TextStyle(color: Colors.white),
      //       ),
      //     ),
      //     FlatButton.icon(
      //       onPressed: () {
      //         if(taskId !=null) {
      //           _openDownloadedFile();
      //         }
      //       },
      //       icon: Icon(Icons.insert_drive_file, color: Colors.white),
      //       label: Text(
      //         "open file" ,
      //         style: TextStyle(color: Colors.white),
      //       ),
      //     )
      //   ],
      // ),
      body: Builder(builder: (BuildContext context) {
        return Column(
          children: [
            Container(
              color: Colors.green,
              height: 22,
            ),
            Expanded(
              child: WebView(
                initialUrl: url,
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller.complete(webViewController);
                  controller = webViewController;
                },
                onProgress: (int progress) {
                  print("WebView is loading (progress : $progress%)");
                  if (progress == 100) {
                    print("Done!! $taskId");
                    Timer(Duration(seconds: 1), () {
                      _openDownloadedFile();
                    });
                  }
                },
                javascriptChannels: <JavascriptChannel>{
                  _toasterJavascriptChannel(context),
                },
                navigationDelegate: (NavigationRequest request) {
                  url = request.url;

                  setState(() {});
                  if (request.url.endsWith('.pdf')) {
                    _requestDownload(url);
                  }
                  print('allowing navigation to ${request.url}');
                  return NavigationDecision.navigate;
                },
                onPageStarted: (String url) {
                  isLoading = true;
                  // _progress(context: context);
                  print('Page started loading: $url');
                },
                onPageFinished: (String url) {
                  isLoading = false;
                  //  _progress(context: context);
                  print('Page finished loading: $url');
                },
                gestureNavigationEnabled: true,
              ),
            )
          ],
        );
        return WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          javascriptChannels: <JavascriptChannel>{
            _toasterJavascriptChannel(context),
          },
          navigationDelegate: (NavigationRequest request) {
            url = request.url;
            setState(() {});
            if (request.url.startsWith('https://www.youtube.com/')) {
              print('blocking navigation to $request}');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            isLoading = true;
            _progress(context: context);
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            isLoading = false;
            _progress(context: context);
            print('Page finished loading: $url');
          },
          gestureNavigationEnabled: true,
        );
      }),
    );
  }

  _progress({required BuildContext context}) {
    if (isLoading) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            content: Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.transparent,
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }
}
