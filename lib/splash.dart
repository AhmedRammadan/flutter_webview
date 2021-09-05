import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'WebViewExample.dart';

class SplashScreen extends StatefulWidget {
  final TargetPlatform? platform;

  SplashScreen({Key? key, this.platform}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  /// Asks for contact permission.
  Future<void> askPermissions(
      Permission requestedPermission,
      var completionCallback,
      ) async {
    // Check permission status
    PermissionStatus status = await requestedPermission.status;
    // Request permission
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.permanentlyDenied) {
      status = await requestedPermission.request();
    }
    completionCallback(status);
  }

  Future<void> ensurePermissionAndMakeCall() async {
    print("1111");
    await askPermissions(Permission.microphone, (PermissionStatus status) async {
      print("22222222");
      print(status.isDenied);
      print(status.isGranted);
      print(status.isRestricted);
      print(status.isPermanentlyDenied);
      print(status.isLimited);

      // status is always permanentlyDenied
      // even just after user installs the application
    });
  }

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 2 ), () async {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) => WebViewExample(
                    platform: widget.platform,
                  )));
    });
  }
  getMicrophonePer() async {
    bool mic = await Permission.microphone.isGranted;
    print('microphone permission? $mic');
    try {
      if (!mic) {
        PermissionStatus status = await Permission.microphone.request();
        print("status.isDenied ${status.isDenied}");
      }
    } catch (e) {
      print("message ${e}");
    }
  }
  @override
  Widget build(BuildContext context) {
    return    Image.asset(
      "assets/splash.jpeg",
      width: MediaQuery.of(context).size.width,
      height: 100,//MediaQuery.of(context).size.height,
    );
    return Scaffold(
      body: Column(
        children: [

          Image.asset(
            "assets/splash.jpeg",
            width: MediaQuery.of(context).size.width,
            height: 100,//MediaQuery.of(context).size.height,
          ),
          FlatButton(onPressed: (){
            ensurePermissionAndMakeCall();
          }, child: Text("asdasd"
          )),
        ],
      ),
    );
  }
}
