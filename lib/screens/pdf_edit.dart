import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import '../Utilities/classes.dart';
import '../Utilities/file_operation.dart';
import 'package:share_extend/share_extend.dart';
import '../Utilities/dbhelper.dart';

import './image_widget_edit.dart';

bool enableSelect = false;
bool enableReorder = false;
bool showImage = false;
List<bool> selectedImageIndex = [];
ImageDB displayImage;

class PdfEdit extends StatefulWidget {
  static const routeName = '/editPdf';
  @override
  _PdfEdit createState() => _PdfEdit();
}

class _PdfEdit extends State<PdfEdit> {
  String fileName;
  DatabaseHelper database = DatabaseHelper();
  DirectoryDB tempDir = new DirectoryDB();
  List<ImageDB> tempImages;
  List<ImageDB> tempImages1;
  List<Widget> imageCards;
  bool enableSelectionIcons = false;
  bool resetReorder = false;
  bool quickScan = false;
  FileOperations fileOperations = FileOperations();
  bool fileStatus = false;
  List<String> imageFilesPath;
  List<Map<String, dynamic>> directoryData;
  int counter = 0;
  void getDirectoryData({
    bool updateFirstImage = false,
    bool updateIndex = false,
  }) async {
    tempImages = [];
    tempImages1 = [];
    imageFilesPath = [];
    selectedImageIndex = [];
    int index = 1;
    directoryData = await database.getTempDirectoryData();
    print('Directory => $directoryData');
    for (var image in directoryData) {
      // Updating first image path after delete

      var i = image['idx'];
      print('Index $i');
      // Updating index of images after delete

      i = index;

      tempImages.add(
        ImageDB(
          idx: i,
          imgPath: image['img_path'],
        ),
      );
      tempImages1.add(
        ImageDB(
          idx: i,
          imgPath: image['img_path'],
        ),
      );
      imageFilesPath.add(image['img_path']);
      selectedImageIndex.add(false);
      index += 1;
    }
    print('Temp images: $tempImages');
    setState(() {});
  }

  Future<void> createDirectoryPath() async {
    print('dffs 1');
    Directory appDir = await getExternalStorageDirectory();
    print('dffs 2');
    String dirPath = '${appDir.path}/temp';
    print('dffs 3');
    print(dirPath);
    tempDir = DirectoryDB(dirPath: dirPath, dirName: DateTime.now().toString());
    print('dffs 5');

    new Directory(dirPath).create();
    print('dffs 6');
  }

  Future<void> _addAndConvert() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    database.deleteTempDirectory();
    if (result != null) {
      print('abcd');
      final document = await PdfDocument.openFile(result.files.single.path);
      int count = document.pagesCount;
      String fn = document.sourceName.substring(
          document.sourceName.lastIndexOf('/') + 1,
          document.sourceName.lastIndexOf('.'));
      print('NAme : $fn');
      for (int i = 1; i <= count; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageFormat.PNG,
        );
        await page.close();
        final fileabc = File('${tempDir.dirPath}/tempimg_$i.jpg');
        await fileabc.writeAsBytes(pageImage.bytes);
        //print(fileabc.path);
        print('$i');
        database.createImageTemp(image: ImageDB(idx: i, imgPath: fileabc.path));
        setState(() {
          counter = i;
        });
        if (i == count) {
          setState(() {
            fileStatus = true;
            fileName = fn;
            getDirectoryData();
          });
        }
      }
    } else {
      // User canceled the picker
    }
  }

  getImageCards() {
    print('in card: $tempImages');
    imageCards = [];
    print(selectedImageIndex);
    for (var image in tempImages) {
      ImageCardEdit imageCard = ImageCardEdit(
        imageDB: image,
        directoryDB: tempDir,
        fileEditCallback: () {
          fileEditCallback(imageDB: image);
        },
        selectCallback: () {
          selectionCallback(imageDB: image);
        },
        imageViewerCallback: () {
          imageViewerCallback(imageDB: image);
        },
      );

      if (!imageCards.contains(imageCard)) {
        imageCards.add(imageCard);
      }
    }
    print('image card returned $imageCards');
    return imageCards;
  }

  selectionCallback({ImageDB imageDB}) {
    if (selectedImageIndex.contains(true)) {
      setState(() {
        enableSelectionIcons = true;
      });
    } else {
      setState(() {
        enableSelectionIcons = false;
      });
    }
  }

  void fileEditCallback({ImageDB imageDB}) {
    getDirectoryData();
  }

  imageViewerCallback({ImageDB imageDB}) {
    setState(() {
      displayImage = imageDB;
      showImage = true;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    print(newIndex);
    Widget image = imageCards.removeAt(oldIndex);
    imageCards.insert(newIndex, image);
    ImageDB image1 = tempImages.removeAt(oldIndex);
    tempImages.insert(newIndex, image1);
  }

  //// this function removes selection by simply making selectedimageIndex= false
  removeSelection() {
    setState(() {
      for (var i = 0; i < selectedImageIndex.length; i++) {
        selectedImageIndex[i] = false;
      }
      enableSelect = false;
    });
  }

  /// this fun deletes multiple images
  deleteMultipleImages() {
    for (var i = 0; i < tempImages.length; i++) {
      /// for every image if image is slected
      if (selectedImageIndex[i]) {
        print('${tempImages[i].idx}: ${tempImages[i].imgPath}');
        database.deleteTempImage(imgPath: tempImages[i].imgPath);
        File(tempImages[i].imgPath).deleteSync();
      }
    }

    try {
      Directory(tempDir.dirPath).deleteSync(recursive: false);
      database.deleteTempDirectory();
    } catch (e) {
      /// if there are images get data with update index
      getDirectoryData();
    }
    removeSelection();
    Navigator.pop(context);
    print('Delete Done');
  }

  /// this fun handles click of pop up menu of 3 dots
  void handleClick(String value) {
    switch (value) {
      case 'Reorder':
        setState(() {
          enableReorder = true;
        });
        break;
      case 'Select':
        setState(() {
          enableSelect = true;
        });
        break;
      case 'Share':
        // showModalBottomSheet(
        //   context: context,
        //   builder: null,
        // );
        showModalBottomSheet(context: context, builder: _showDialog);
        break;
    }
  }

  @override
  void initState() {
    print('init called');
    createDirectoryPath();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (fileStatus) {
      print(getImageCards());
    }

    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          leading: (enableSelect || enableReorder)
              ? IconButton(
                  //displays X button to cancle select/ reorder
                  icon: Icon(
                    Icons.close,
                    size: 30,
                  ),
                  onPressed:
                      (enableSelect) //// pressed when enable select then rempve selection
                          ? () {
                              removeSelection();
                            }
                          : () {
                              //// pressed when enable reorder then undo reorder
                              //// changes using initial dirimages array
                              setState(() {
                                tempImages = [];
                                for (var image in tempImages1) {
                                  tempImages.add(image);
                                }
                                enableReorder = false;
                              });
                            },
                )
              : IconButton(
                  /// else show simple back button and pop page
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
          title: Text(
            'Edit',
            overflow: TextOverflow.ellipsis,
          ),

          /// action is for button on rhs in appbar
          actions: [
            (enableReorder)

                /// if reororder is enable then display done button
                ? GestureDetector(
                    /// when done is pressed update image path
                    onTap: () {
                      for (var i = 1; i <= tempImages.length; i++) {
                        tempImages[i - 1].idx = i;

                        /// update rest image path other than first
                        database.updateTempImagePath(
                          image: tempImages[i - 1],
                        );
                        print('$i: ${tempImages[i - 1].imgPath}');
                      }
                      setState(() {
                        enableReorder = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.only(right: 25),
                      alignment: Alignment.center,
                      child: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: null,
                      ),
                    ),
                  )
                : //// if enable select is pressed show delete icon for multiple image
                (enableSelect)
                    ? IconButton(
                        icon: Icon(
                          Icons.delete,
                          color:
                              (enableSelectionIcons) ? Colors.red : Colors.grey,
                        ),
                        onPressed: (enableSelectionIcons)
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      title: Text('Delete'),
                                      content: Text(
                                          'Do you really want to delete this file?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: deleteMultipleImages,
                                          child: Text(
                                            'Delete',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            : () {},
                      )

                    /// if nithing is selected normal view then show 3 dot button for displaying
                    //// option and
                    : IconButton(
                        icon: Icon(Icons.picture_as_pdf),
                        onPressed: () async {
                          print('abcd');
                          await fileOperations.saveToAppDirectory(
                            context: context,
                            fileName: fileName,
                            images: tempImages,
                          );
                          Directory storedDirectory =
                              await getApplicationDocumentsDirectory();
                          final result = await OpenFile.open(
                              '${storedDirectory.path}/$fileName.pdf');

                          setState(() {
                            String _openResult =
                                "type=${result.type}  message=${result.message}";
                            print(_openResult);
                          });
                        },
                      ),
            PopupMenuButton<String>(
              onSelected: handleClick,
              color: Colors.white.withOpacity(0.95),
              elevation: 30,
              offset: Offset.fromDirection(20, 20),
              icon: Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: 'Select',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select'),
                        SizedBox(width: 10),
                        Icon(
                          Icons.select_all,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Reorder',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reorder'),
                        SizedBox(width: 10),
                        Icon(
                          Icons.reorder,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Share',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Export'),
                        SizedBox(width: 10),
                        Icon(
                          Icons.share,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: fileStatus
            ? RefreshIndicator(
                onRefresh: () async {
                  getDirectoryData();
                },
                ////here previpus code was tere
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Text('Pull to refresh'),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ReorderableWrap(
                          spacing: 5,
                          runSpacing: 5,
                          minMainAxisCount: 2,
                          maxMainAxisCount: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: getImageCards(),
                          onReorder: _onReorder,
                        )
                      ],
                    ),
                  )
                ]),
              )
            : counter == 0
                ? Center(
                    child: Text(
                    'Select A File',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ))
                : Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_chart),
          onPressed: () async {
            await _addAndConvert();
          },
        ),
      ),
    );
  }

  Widget _showDialog(BuildContext context) {
    FileOperations fileOperations = FileOperations();
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            child: Text(
              '$fileName',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(
            thickness: 0.2,
            indent: 8,
            endIndent: 8,
          ),
          ListTile(
              leading: Icon(Icons.save_alt),
              title: Text('Save to device'),
              onTap: () async {
                print('saved clicked');
                String savedDirectory;
                savedDirectory = await fileOperations.saveEditedToDevice(
                  context: context,
                  fileName: fileName,
                  images: tempImages,
                );
                Navigator.pop(context);
                String displayText;
                (savedDirectory != null)
                    ? displayText = "PDF Saved at\n$savedDirectory"
                    : displayText = "Failed to generate pdf. Try Again.";
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: StatefulBuilder(
                        builder: (BuildContext context,
                            void Function(void Function()) setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Saved to Directory',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 20),
                                child: Text(
                                  displayText,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Done')),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                );
              }),
          Divider(
            thickness: 0.2,
            indent: 8,
            endIndent: 8,
          ),
          ListTile(
            //////////////// this function is used to share pdf doc
            leading: Icon(Icons.share),
            title: Text('Share'),
            onTap: () async {
              fileOperations.saveToAppDirectory(
                context: context,
                fileName: fileName,
                images: tempImages,
              );
              print('share pressed');
              Directory storedDirectory =
                  await getApplicationDocumentsDirectory();
              ShareExtend.share(
                  '${storedDirectory.path}/$fileName.pdf', 'file');
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}
