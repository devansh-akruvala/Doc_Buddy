import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import './locker.dart';

class FingerPrintAuth extends StatefulWidget {
  static const routeName = '/fingerprint';
  @override
  _FingerPrintAuthState createState() => _FingerPrintAuthState();
}

class _FingerPrintAuthState extends State<FingerPrintAuth> {
  final LocalAuthentication localAuth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: Center(
        child: GestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 50,
              ),
              Text(
                'Click here to verify your Biomatric details',
              )
            ],
          ),
          onTap: () async {
            bool canCheck = await localAuth.canCheckBiometrics;
            if (canCheck) {
              try {
                bool status = await localAuth.authenticate(
                  localizedReason: 'Authenticate to proceed further',
                );
                if (status) {
                  Navigator.popAndPushNamed(context, LockerWidget.routeName);
                  print('done');
                } else {
                  print('Some error');
                }
              } on PlatformException catch (e) {
                print(e);
              }
            }
          },
        ),
      ),
    ));
  }
}
