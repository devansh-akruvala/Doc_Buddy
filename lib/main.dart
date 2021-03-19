import 'package:flutter/material.dart';

import './screens/home_page.dart';
import './screens/scan_home.dart';
import './screens/scan_doc.dart';
import './screens/locker.dart';
import './screens/image_compress.dart';
import './screens/pdf_edit.dart';
import './screens/fingerprint_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doc Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: 'homepage',
      routes: {
        'homepage': (ctx) => HomePage(),
        ScanHome.routeName: (ctx) => ScanHome(),
        ScanDoc.routeName: (ctx) => ScanDoc(),
        LockerWidget.routeName: (ctx) => LockerWidget(),
        ImageCompress.routeName: (ctx) => ImageCompress(),
        PdfEdit.routeName: (ctx) => PdfEdit(),
        FingerPrintAuth.routeName: (ctx) => FingerPrintAuth(),
      },
    );
  }
}
