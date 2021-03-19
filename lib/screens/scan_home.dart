import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import './scan_doc.dart';

import '../Utilities/dbhelper.dart';
import '../Utilities/classes.dart';

class ScanHome extends StatefulWidget {
  static const routeName = 'ScanHome';

  @override
  _ScanHomeState createState() => _ScanHomeState();
}

class _ScanHomeState extends State<ScanHome> {
  DatabaseHelper database = DatabaseHelper();

  /// instance of dbhelper
  List<Map<String, dynamic>> masterData;

  /// masterdata
  List<DirectoryOS> masterDirectories = [];

  /// list of deerictoreis

  Future homeRefresh() async {
    ////refresh homepage
    await getMasterData();
    setState(() {});
  }

  void getData() {
    homeRefresh();
  }

  /// deals with permission of camera and storage

  /// function to get data of masterdirectory table  and store it in masterdata(list of map)
  ///
  Future<List<DirectoryOS>> getMasterData() async {
    masterDirectories = [];

    /// 1. getmasterdata returns tuples of form listofmaps which is stored in masterdata variable
    masterData = await database.getMasterData();

    /// fetch data from db and store it to list my dictonary then this dictonary can be used to display data
    print('Master Table => $masterData');

    /// for each row in masterdata it is converted into list of objects of DirectoryOS
    for (var directory in masterData) {
      var flag = false;
      for (var dir in masterDirectories) {
        if (dir.dirPath == directory['dir_path']) {
          flag = true;
        }
      }
      if (!flag) {
        masterDirectories.add(
          DirectoryOS(
            dirName: directory['dir_name'],
            dirPath: directory['dir_path'],
            created: DateTime.parse(directory['created']),
            imageCount: directory['image_count'],
            firstImgPath: directory['first_img_path'],
            lastModified: DateTime.parse(directory['last_modified']),
            newName: directory['new_name'],
          ),
        );
      }
    }
    masterDirectories = masterDirectories.reversed.toList();
    return masterDirectories;
  }

  Future<void> _delete(String dirpath) async {
    await database.deleteDirectory(dirPath: dirpath);
    Directory(dirpath).deleteSync(recursive: true);
    homeRefresh();
  }

  Future<void> _rename(DirectoryOS directory) async {
    database.renameDirectory(directory: directory);
    homeRefresh();
  }

  @override
  void initState() {
    getMasterData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Home'),
      ),
      body: RefreshIndicator(
        onRefresh: homeRefresh,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 5.0),
              child: Text('Drag down to refresh'),
            ),
            Expanded(
                child: FutureBuilder(
              future: getMasterData(),
              builder: (BuildContext contex, AsyncSnapshot snapshot) {
                return ListView.builder(
                    itemCount: masterDirectories.length,
                    itemBuilder: (contex, index) {
                      return Card(
                        elevation: 5,
                        child: FocusedMenuHolder(
                          onPressed: null,
                          child: ListTile(
                              contentPadding: EdgeInsets.all(5.0),
                              leading: Image.file(
                                File(masterDirectories[index].firstImgPath),
                                width: 50,
                                height: 50,
                              ),
                              title: Text(
                                masterDirectories[index].newName ??
                                    masterDirectories[index].dirName,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last Modified: ${masterDirectories[index].lastModified.day}-${masterDirectories[index].lastModified.month}-${masterDirectories[index].lastModified.year}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    '${masterDirectories[index].imageCount} ${(masterDirectories[index].imageCount == 1) ? 'image' : 'images'}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_right,
                                size: 30,
                                color: Colors.red,
                              ),
                              onTap: () async {
                                print(masterDirectories[index]);

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (contex) => ScanDoc(
                                              directoryOS:
                                                  masterDirectories[index],
                                            ))).whenComplete(homeRefresh);
                              }),
                          menuItems: [
                            FocusedMenuItem(
                                title: Text('Delete'),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (contex) {
                                        return AlertDialog(
                                          title: Text('Delete File'),
                                          content: Text(
                                              'Are you sure you want to delete this item'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancle'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () {
                                                _delete(masterDirectories[index]
                                                    .dirPath);
                                                Navigator.pop(context);
                                              },
                                            )
                                          ],
                                        );
                                      });
                                }),
                            FocusedMenuItem(
                                title: Text('Rename'),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (contex) {
                                        String fileName = '';

                                        return AlertDialog(
                                          title: Text('Rename'),
                                          content: TextField(
                                            onChanged: (value) {
                                              fileName = value;
                                            },
                                            controller: TextEditingController(
                                                text: fileName),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancle'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Rename'),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                masterDirectories[index]
                                                    .newName = fileName;
                                                _rename(
                                                    masterDirectories[index]);
                                              },
                                            ),
                                          ],
                                        );
                                      }).whenComplete(() {
                                    setState(() {});
                                  });
                                }),
                          ],
                        ),
                      );
                    });
              },
            ))
          ],
        ),
      ),

      /// it goes to scan doc when perssed
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanDoc(
                directoryOS: DirectoryOS(),
              ),
            ),
          ).whenComplete(() {
            homeRefresh();
          });
        },
      ),
    );
  }
}
