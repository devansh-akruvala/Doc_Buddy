import 'dart:io';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:image_cropper/image_cropper.dart';
import '../Utilities/classes.dart';
import '../Utilities/dbhelper.dart';
import './scan_doc.dart';

class ImageCard extends StatefulWidget {
  final Function fileEditCallback;
  final DirectoryDB directoryDB;
  final ImageDB imageDB;
  final Function selectCallback;
  final Function imageViewerCallback;

  const ImageCard({
    this.fileEditCallback,
    this.directoryDB,
    this.imageDB,
    this.selectCallback,
    this.imageViewerCallback,
  });
  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  DatabaseHelper database = DatabaseHelper();

  selectionOnPressed() {
    setState(() {
      selectedImageIndex[widget.imageDB.idx - 1] = true;
    });
    widget.selectCallback();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(children: [
      Card(
        child: FocusedMenuHolder(
          menuWidth: size.width * 0.5,
          onPressed: () {
            (enableSelect)
                ? selectionOnPressed()
                : widget.imageViewerCallback();
          },
          menuItems: [
            FocusedMenuItem(
              title: Text("Edit"),
              onPressed: () async {
                File croppedFile = await ImageCropper.cropImage(
                    sourcePath: widget.imageDB.imgPath,
                    // aspectRatioPresets: [
                    //   CropAspectRatioPreset.square,
                    //   CropAspectRatioPreset.ratio3x2,
                    //   CropAspectRatioPreset.original,
                    //   CropAspectRatioPreset.ratio4x3,
                    //   CropAspectRatioPreset.ratio16x9
                    // ],
                    androidUiSettings: AndroidUiSettings(
                        toolbarTitle: 'Cropper',
                        toolbarColor: Colors.blue,
                        toolbarWidgetColor: Colors.white,
                        initAspectRatio: CropAspectRatioPreset.original,
                        lockAspectRatio: false),
                    iosUiSettings: IOSUiSettings(
                      minimumAspectRatio: 1.0,
                    ));
                File image = croppedFile;
                File temp = File(widget.imageDB.imgPath
                        .substring(0, widget.imageDB.imgPath.lastIndexOf(".")) +
                    "c.jpg");
                File(widget.imageDB.imgPath).deleteSync();
                if (image != null) {
                  image.copySync(temp.path);
                }
                widget.imageDB.imgPath = temp.path;
                print(temp.path);
                database.updateImagePath(
                  tableName: widget.directoryDB.dirName,
                  image: widget.imageDB,
                );
                if (widget.imageDB.idx == 1) {
                  database.updateFirstImagePath(
                    imagePath: widget.imageDB.imgPath,
                    dirPath: widget.directoryDB.dirPath,
                  );
                }

                widget.fileEditCallback();
              },
            ),
            FocusedMenuItem(
                title: Text("Delete"),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Delete Page'),
                          content:
                              Text('Are you sure you want to delete this page'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  File(widget.imageDB.imgPath).deleteSync();
                                  database.deleteImage(
                                      imgPath: widget.imageDB.imgPath,
                                      tableName: widget.directoryDB.dirName);

                                  database.updateImageCount(
                                    tableName: widget.directoryDB.dirName,
                                  );
                                  try {
                                    Directory(widget.directoryDB.dirPath)
                                        .deleteSync(recursive: false);
                                    database.deleteDirectory(
                                        dirPath: widget.directoryDB.dirPath);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    widget.fileEditCallback();
                                  }
                                  widget.selectCallback();
                                  Navigator.pop(context);
                                },
                                child: Text('Delete')),
                          ],
                        );
                      });
                }),
          ],
          child: Image.file(
            File(widget.imageDB.imgPath),
            width: size.width * 0.30,
            height: size.height * 0.20,
          ),
        ),
      ),
      (selectedImageIndex[widget.imageDB.idx - 1] && enableSelect)
          ? Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedImageIndex[widget.imageDB.idx - 1] = false;
                  });
                  widget.selectCallback();
                },
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: Colors.red,
                    ),
                  ),
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
            )
          : Container(
              width: 0.001,
              height: 0.001,
            ),
      (enableReorder)
          ? Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            )
          : Container(
              width: 0.001,
              height: 0.001,
            ),
    ]);
  }
}
