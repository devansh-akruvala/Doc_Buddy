import 'dart:io';

import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompress extends StatefulWidget {
  static const routeName = '/CompressImage';
  @override
  _ImageCompressState createState() => _ImageCompressState();
}

class _ImageCompressState extends State<ImageCompress> {
  File _image;
  File _compressedImage;
  final picker = ImagePicker();

  int _value = 0;
  Future<void> getimage() async {
    File image;
    var picture = await picker.pickImage(source: ImageSource.gallery);
    print(picture);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    setState(() {
      _compressedImage = null;
      print('picked');
      _image = image;
    });
  }

  Future<void> compressFile(File file) async {
    Directory tempDir = Directory.systemTemp; //await getTemporaryDirectory();

    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      '${tempDir.path}.jpeg',
      quality: (100 - _value),
    );
    print(file.lengthSync());
    print(result.lengthSync());

    setState(() {
      print('Comp');
      _compressedImage = result;
    });
  }

  Future<Directory> pickDirectory(
      BuildContext context, selectedDirectory) async {
    Directory directory = selectedDirectory;
    try {
      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/");
      } else {
        directory = await getExternalStorageDirectory();
      }
    } catch (e) {
      print(e);
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await FolderPicker.pick(
      allowFolderCreation: true,
      context: context,
      rootDirectory: directory,
    );

    return newDirectory;
  }

  Future<bool> saveCompressedImage() async {
    Directory selectedDirectory;
    Directory scanDir = Directory("/storage/emulated/0/Doc_Buddy");
    Directory scanPdfDir =
        Directory("/storage/emulated/0/Doc_Buddy/Compressed");

    try {
      if (!scanDir.existsSync()) {
        scanDir.createSync();
        scanPdfDir.createSync();
      }
      if (!scanPdfDir.existsSync()) {
        scanPdfDir.createSync();
      }
      selectedDirectory = scanPdfDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }

    //final filePath = _image.absolute.path;
    // Create output file path
    // eg:- "Volume/VM/abcd_out.jpeg"

    try {
      var name = DateTime.now().toString();
      name = name.replaceAll(RegExp(r':'), '_');
      final output = "${selectedDirectory.path}/$name.jpg";
      print(output);
      print('before');
      File temp = await _compressedImage.copy(output);
      print('After');
      if (temp != null) {
        return true;
      }
      return false;
      // // await _compressedImage.copy('${path.path}/image1.jpeg');
      // print('asdasd');o
    } catch (e) {
      print(e);
      return false;
    }
  }

  final appbar = AppBar(
    title: Text("Compress image"),
  );
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: appbar,
      body: Container(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.only(bottom: 10)),
            Container(
                width: double.infinity,
                height: (size.height -
                        appbar.preferredSize.height -
                        statusbarHeight) *
                    0.6,
                child: _image == null
                    ? Center(
                        child: Text('select image'),
                      )
                    : Image.file(_image)),
            Divider(
              thickness: 2,
              indent: 8,
              endIndent: 8,
            ),
            Container(
                height: (size.height -
                        appbar.preferredSize.height -
                        statusbarHeight) *
                    0.1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image != null
                        ? Text(
                            'Original size= ${_image.lengthSync() / 1000000} mb',
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'Original size= 0 mb',
                            overflow: TextOverflow.ellipsis,
                          ),
                    _compressedImage != null
                        ? Text(
                            'Compressed size= ${_compressedImage.lengthSync() / 1000000} mb',
                            overflow: TextOverflow.ellipsis,
                          )
                        : _image != null
                            ? Text(
                                'Compressed size= ${_image.lengthSync() / 1000000} mb',
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                'Compressed size= 0 mb',
                                overflow: TextOverflow.ellipsis,
                              ),
                  ],
                )),
            Container(
                height: (size.height -
                        appbar.preferredSize.height -
                        statusbarHeight) *
                    0.1,
                child: Column(
                  children: [
                    const Text('Select Compression rate: '),
                    Slider(
                        value: _value.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 4,
                        activeColor: Colors.blue,
                        label: '$_value %',
                        onChanged: (double newValue) {
                          setState(() {
                            _value = newValue.round();
                          });
                        },
                        semanticFormatterCallback: (double newValue) {
                          return '${newValue.round()} dollars';
                        }),
                  ],
                )),
            Container(
              height: (size.height -
                      appbar.preferredSize.height -
                      statusbarHeight) *
                  0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _image != null && _value != 0
                        ? () async {
                            setState(() {
                              _compressedImage = null;
                            });
                            compressFile(_image);
                          }
                        : null,
                    child: Text('Compress'),
                  ),
                  ElevatedButton(
                    onPressed: _compressedImage != null && _value != 0
                        ? () async {
                            /// save function here
                            bool status = await saveCompressedImage();
                            showDialog(
                                context: context,
                                builder: (contex) {
                                  return AlertDialog(
                                    title: const Text("Export status"),
                                    content: status
                                        ? Text(
                                            'File successfully saved to /storage/emulated/0/Doc_Buddy/Compressed')
                                        : Text(
                                            'Some error has occured please try again'),
                                    actions: [
                                      ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('OK'))
                                    ],
                                  );
                                });
                          }
                        : null,
                    child: Text('Export'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _image = null;
          await getimage();
          setState(() {});
        },
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
