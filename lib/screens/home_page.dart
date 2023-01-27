import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/image_compress.dart';
import '../screens/pdf_edit.dart';
import './fingerprint_auth.dart';
import './scan_home.dart';

class HomePage extends StatefulWidget {
  static const routeName = 'homepage';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<bool> _requestPermission() async {
    // final PermissionHandler _permissionHandler = PermissionHandler();
    // var result = await _permissionHandler.requestPermissions(
    //     <PermissionGroup>[PermissionGroup.storage, PermissionGroup.camera]);
    Map<Permission, PermissionStatus> result = await [
      Permission.storage,
      Permission.camera,
      Permission.manageExternalStorage
    ].request();
    if (result[Permission.storage] == PermissionStatus.granted &&
        result[Permission.camera] == PermissionStatus.granted &&
        result[Permission.manageExternalStorage] == PermissionStatus.granted) {
      print('Granted');
      return true;
    }
    print('not Granted');
    return false;
  }

  void askPermission() async {
    await _requestPermission();
  }

  @override
  void initState() {
    askPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doc Buddy'),
      ),
      body: SafeArea(
        child: Center(
          child: GridView(
            padding: const EdgeInsets.all(25),
            shrinkWrap: true,
            children: [
              InkWell(
                child: Card(
                  child: Center(
                      child: const Text(
                    'Scan Document',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )),
                  color: Colors.blue,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(ScanHome.routeName);
                },
              ),
              InkWell(
                child: Card(
                  child: Center(
                      child: const Text(
                    'Locker',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )),
                  color: Colors.blue,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(FingerPrintAuth.routeName);
                },
              ),
              InkWell(
                child: Card(
                  child: Center(
                      child: const Text(
                    'Compress Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )),
                  color: Colors.blue,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(ImageCompress.routeName);
                },
              ),
              InkWell(
                child: Card(
                  child: Center(
                      child: const Text(
                    'Edit Pdf',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  )),
                  color: Colors.blue.shade400,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(PdfEdit.routeName);
                },
              ),
            ],
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// GridView(
//       padding: const EdgeInsets.all(25),
//       children: DUMMY_CATEGORIES
//           .map((catData) =>
//               CategoryItem(catData.id, catData.title, catData.color))
//           .toList(),
//       gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//         maxCrossAxisExtent: 200,
//         childAspectRatio: 3 / 2,
//         crossAxisSpacing: 20,
//         mainAxisSpacing: 20,
//       ),
//     );
