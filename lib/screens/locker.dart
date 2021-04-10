import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../Utilities/dbhelper.dart';
import '../Utilities/classes.dart';

class LockerWidget extends StatefulWidget {
  static const routeName = '/locker';

  @override
  _LockerWidgetState createState() => _LockerWidgetState();
}

class _LockerWidgetState extends State<LockerWidget> {
  String _filename;
  File _docFile;
  DatabaseHelper database = DatabaseHelper();

  /// instance of dbhelper
  List<Map<String, dynamic>> lockerData;

  /// masterdata
  List<Locker> locker = [];

  Future<List<Locker>> getLockerData() async {
    locker = [];

    /// 1. getmasterdata returns tuples of form listofmaps which is stored in masterdata variable
    lockerData = await database.getLockerData();

    /// fetch data from db and store it to list my dictonary then this dictonary can be used to display data
    print('locker Table => $lockerData');

    /// for each row in masterdata it is converted into list of objects of DirectoryDB
    for (var directory in lockerData) {
      var flag = false;
      for (var dir in locker) {
        if (dir.path == directory['path']) {
          flag = true;
        }
      }
      if (!flag) {
        locker.add(
          Locker(
              name: directory['name'],
              path: directory['path'],
              createdOn: directory['created']),
        );
      }
    }
    locker = locker.reversed.toList();

    return locker;
  }

  Future pageRefresh() async {
    ////refresh homepage
    await getLockerData();
    setState(() {});
  }

  void getData() {
    pageRefresh();
  }

  Future<void> _filePicker() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path);
      setState(() {
        _docFile = file;
      });
    } else {
      // User canceled the picker
    }
  }

  Future<bool> inputfile() async {
    Directory scanDir = Directory("/storage/emulated/0/Doc_Buddy");
    Directory lockerPdfDir = Directory("/storage/emulated/0/Doc_Buddy/Locker");
    Directory selectedDirectory;
    try {
      if (!scanDir.existsSync()) {
        scanDir.createSync();
        lockerPdfDir.createSync();
      }
      if (!lockerPdfDir.existsSync()) {
        lockerPdfDir.createSync();
      }
      selectedDirectory = lockerPdfDir;
    } catch (e) {
      print(e);
    }
    final output = '${selectedDirectory.path}/$_filename.pdf';

    File tempdoc = await _docFile.copy(output);
    if (tempdoc != null) {
      Locker temp = Locker(
          name: _filename, createdOn: DateTime.now().toString(), path: output);
      await database.createLockerFile(file: temp);
      getLockerData();
      return true;
    }
    return false;
  }

  Widget _showBottomModatSheet(
    BuildContext contex,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.all(10),
          decoration:
              BoxDecoration(border: Border.all(color: Colors.blueAccent)),
          child: TextField(
            onChanged: (value) {
              if (value.trim() != '') {
                _filename = value;
              }
            },
            decoration: InputDecoration(
                border: InputBorder.none, hintText: 'Enter Name of Document'),
            controller: TextEditingController(text: _filename),
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              await _filePicker();
            },
            child: Text('Select file')),
        ElevatedButton(
            onPressed: _docFile != null
                ? () async {
                    await inputfile();
                    await pageRefresh();
                    Navigator.pop(context);
                  }
                : null,
            child: Text('Add')),
      ],
    );
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Locker"),
        ),
        body: RefreshIndicator(
            onRefresh: pageRefresh,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.only(bottom: 5.0),
                child: Text('Drag down to refresh'),
              ),
              Expanded(
                  child: FutureBuilder(
                      future: getLockerData(),
                      builder: (BuildContext contex, AsyncSnapshot snapshot) {
                        return ListView.builder(
                          itemCount: locker.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 5,
                              child: ListTile(
                                title: Text(
                                  'Name: ${locker[index].name}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    'Added on: ${locker[index].createdOn}'),
                                trailing: GestureDetector(
                                  child: Icon(
                                    Icons.delete,
                                    size: 30,
                                    color: Colors.red,
                                  ),
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Delete File'),
                                            content: const Text(
                                                "Are you sure you want to Delete File"),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel')),
                                              ElevatedButton(
                                                  onPressed: () async {
                                                    await database
                                                        .deleteLockerFile(
                                                            filePath:
                                                                locker[index]
                                                                    .path);
                                                    Directory(
                                                            locker[index].path)
                                                        .deleteSync(
                                                            recursive: true);
                                                    pageRefresh();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Delete')),
                                            ],
                                          );
                                        });
                                  },
                                ),
                                onTap: () async {
                                  final result =
                                      await OpenFile.open(locker[index].path);
                                  setState(() {
                                    String _openResult =
                                        "type=${result.type}  message=${result.message}";
                                    print(_openResult);
                                  });
                                },
                              ),
                            );
                          },
                        );
                      }))
            ])),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => _showBottomModatSheet(context),
              isScrollControlled: true,
            );
          },
        ),
      ),
    );
  }
}

// Expanded(
//             child: FutureBuilder(
//                 future: getLockerData(),
//                 builder: (BuildContext contex, AsyncSnapshot snapshot) {
//                   return ListView.builder(
//                     itemCount: locker.length,
//                     itemBuilder: (context, index) {
//                       return Card(
//                         elevation: 5,
//                         child: ListTile(
//                           title: Text('${locker[index].name}'),
//                           subtitle: Text('${locker[index].createdOn}'),
//                         ),
//                       );
//                     },
//                   );
//                 })),
