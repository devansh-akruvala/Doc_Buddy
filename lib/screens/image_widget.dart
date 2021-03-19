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
  final DirectoryOS directoryOS;
  final ImageOS imageOS;
  final Function selectCallback;
  final Function imageViewerCallback;

  const ImageCard({
    this.fileEditCallback,
    this.directoryOS,
    this.imageOS,
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
      selectedImageIndex[widget.imageOS.idx - 1] = true;
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
                    sourcePath: widget.imageOS.imgPath,
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
                File temp = File(widget.imageOS.imgPath
                        .substring(0, widget.imageOS.imgPath.lastIndexOf(".")) +
                    "c.jpg");
                File(widget.imageOS.imgPath).deleteSync();
                if (image != null) {
                  image.copySync(temp.path);
                }
                widget.imageOS.imgPath = temp.path;
                print(temp.path);
                database.updateImagePath(
                  tableName: widget.directoryOS.dirName,
                  image: widget.imageOS,
                );
                if (widget.imageOS.idx == 1) {
                  database.updateFirstImagePath(
                    imagePath: widget.imageOS.imgPath,
                    dirPath: widget.directoryOS.dirPath,
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
                                  File(widget.imageOS.imgPath).deleteSync();
                                  database.deleteImage(
                                      imgPath: widget.imageOS.imgPath,
                                      tableName: widget.directoryOS.dirName);

                                  database.updateImageCount(
                                    tableName: widget.directoryOS.dirName,
                                  );
                                  try {
                                    Directory(widget.directoryOS.dirPath)
                                        .deleteSync(recursive: false);
                                    database.deleteDirectory(
                                        dirPath: widget.directoryOS.dirPath);
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
            File(widget.imageOS.imgPath),
            width: size.width * 0.30,
            height: size.height * 0.20,
          ),
        ),
      ),
      (selectedImageIndex[widget.imageOS.idx - 1] && enableSelect)
          ? Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedImageIndex[widget.imageOS.idx - 1] = false;
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