import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:reorderables/reorderables.dart';
import 'package:share_extend/share_extend.dart';

import '../Utilities/classes.dart';
import '../Utilities/dbhelper.dart';
import '../Utilities/file_operation.dart';
import './image_widget.dart';

bool enableSelect = false;
bool enableReorder = false;
bool showImage = false;
List<bool> selectedImageIndex = [];

class ScanDoc extends StatefulWidget {
  static const routeName = 'ScanDoc';
  final DirectoryDB directoryDB;

  ScanDoc({this.directoryDB});
  @override
  _ScanDocState createState() => _ScanDocState();
}

class _ScanDocState extends State<ScanDoc> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  //TransformationController _controller = new TransformationController();

  /// database instacnce
  DatabaseHelper database = DatabaseHelper();

  /// stores image path
  List<String> imageFilesPath = [];

  /// card vview of images
  List<Widget> imageCards = [];
  String imageFilePath;

  /// fileoperation instance
  FileOperations fileOperations;
  // holds directory path
  String dirPath;

  /// filename
  String fileName = '';

  /// list that holds directory data from db
  List<Map<String, dynamic>> directoryData;

  /// list that holdes images
  List<ImageDB> directoryImages = [];

  /// list that holdes initial images
  List<ImageDB> initDirectoryImages = [];

  bool enableSelectionIcons = false;
  bool resetReorder = false;
  bool quickScan = false;

  /// instance of image os
  ImageDB displayImage;
  //int imageQuality = 3;

  /// this works for making new directory when new button is pressed on scan home screen
  /// this function creates external directory and stores dirname in DirectoryDB class
  /// it finds external dir path and makes foldrer(dir ) in it with namr of datetime.now()
  Future<void> createDirectoryPath() async {
    Directory appDir = await getExternalStorageDirectory();
    dirPath = "${appDir.path}/Scan ${DateTime.now()}";
    fileName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    widget.directoryDB.dirName = fileName;
  }

  /// retrives masterdiectory details
  /// this works for getting data of already existing directory
  void getDirectoryData({
    bool updateFirstImage = false,
    bool updateIndex = false,
  }) async {
    directoryImages = [];
    initDirectoryImages = [];
    imageFilesPath = [];
    selectedImageIndex = [];
    int index = 1;
    directoryData = await database.getDirectoryData(widget.directoryDB.dirName);
    print('Directory table[$widget.directoryDB.dirName] => $directoryData');
    for (var image in directoryData) {
      // Updating first image path after delete
      if (updateFirstImage) {
        database.updateFirstImagePath(
            imagePath: image['img_path'], dirPath: widget.directoryDB.dirPath);
        updateFirstImage = false;
      }
      var i = image['idx'];

      // Updating index of images after delete
      if (updateIndex) {
        i = index;
        database.updateImageIndex(
          image: ImageDB(
            idx: i,
            imgPath: image['img_path'],
          ),
          tableName: widget.directoryDB.dirName,
        );
      }

      directoryImages.add(
        ImageDB(
          idx: i,
          imgPath: image['img_path'],
        ),
      );
      initDirectoryImages.add(
        ImageDB(
          idx: i,
          imgPath: image['img_path'],
        ),
      );
      imageFilesPath.add(image['img_path']);
      selectedImageIndex.add(false);
      index += 1;
    }
    print(selectedImageIndex.length);
    setState(() {});
  }

//// open camera and tahe image it also saves the image on external storage and helps in refresh page
  ///after adding image
  Future<dynamic> createImage() async {
    File image;
    image = await fileOperations.openCamera();
    if (image != null) {
      CroppedFile croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );
      File imageFile = File(croppedFile.path ?? image.path);
      Directory tempDir = await getTemporaryDirectory();
      imageFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${tempDir.path}.jpeg',
        quality: 80,
      );
      setState(() {});
      await fileOperations.saveImage(
        image: imageFile,
        index: directoryImages.length + 1,
        dirPath: dirPath,
        shouldCompress: 0,
      );
      await fileOperations.deleteTemporaryFiles();
      getDirectoryData();
    }
  }

  getImageCards() {
    imageCards = [];
    print(selectedImageIndex);
    for (var image in directoryImages) {
      ImageCard imageCard = ImageCard(
        imageDB: image,
        directoryDB: widget.directoryDB,
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
    bool isFirstImage = false;
    if (imageDB.imgPath == widget.directoryDB.firstImgPath) {
      isFirstImage = true;
    }
    getDirectoryData(
      updateFirstImage: isFirstImage,
      updateIndex: true,
    );
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
    ImageDB image1 = directoryImages.removeAt(oldIndex);
    directoryImages.insert(newIndex, image1);
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
    bool isFirstImage = false;
    for (var i = 0; i < directoryImages.length; i++) {
      /// for every image if image is slected
      if (selectedImageIndex[i]) {
        print('${directoryImages[i].idx}: ${directoryImages[i].imgPath}');

        /// if image is first image
        if (directoryImages[i].imgPath == widget.directoryDB.firstImgPath) {
          isFirstImage = true;
        }

        /// delete image from storage
        File(directoryImages[i].imgPath).deleteSync();

        /// remove image data frim db
        database.deleteImage(
          imgPath: directoryImages[i].imgPath,
          tableName: widget.directoryDB.dirName,
        );
      }
    }

    /// for end

    /// change image count in master table
    database.updateImageCount(
      tableName: widget.directoryDB.dirName,
    );

    /// recursive false means if it is last image then delete whole
    /// folder and entry in masterdirectory table
    try {
      Directory(widget.directoryDB.dirPath).deleteSync(recursive: false);
      database.deleteDirectory(dirPath: widget.directoryDB.dirPath);
    } catch (e) {
      /// if there are images get data with update index
      getDirectoryData(
        updateFirstImage: isFirstImage,
        updateIndex: true,
      );
    }
    removeSelection();
    Navigator.pop(context);
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
    super.initState();
    fileOperations = FileOperations();
    if (widget.directoryDB.dirPath != null) {
      dirPath = widget.directoryDB.dirPath;
      fileName = widget.directoryDB.newName;
      getDirectoryData();
    } else {
      createDirectoryPath();
      createImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: WillPopScope(
      onWillPop: () {
        if (enableSelect || enableReorder || showImage) {
          setState(() {
            enableSelect = false;
            removeSelection();
            enableReorder = false;
            showImage = false;
          });
        } else {
          Navigator.pop(context);
        }
        return;
      },
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
                                directoryImages = [];
                                for (var image in initDirectoryImages) {
                                  directoryImages.add(image);
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
            fileName,
            overflow: TextOverflow.ellipsis,
          ),

          /// action is for button on rhs in appbar
          actions: [
            (enableReorder)

                /// if reororder is enable then display done button
                ? GestureDetector(
                    /// when done is pressed update image path
                    onTap: () {
                      for (var i = 1; i <= directoryImages.length; i++) {
                        directoryImages[i - 1].idx = i;
                        if (i == 1) {
                          /// when first image is modified update first image path
                          database.updateFirstImagePath(
                            dirPath: widget.directoryDB.dirPath,
                            imagePath: directoryImages[i - 1].imgPath,
                          );

                          /// change object attribute
                          widget.directoryDB.firstImgPath =
                              directoryImages[i - 1].imgPath;
                        }

                        /// update rest image path other than first
                        database.updateImagePath(
                          image: directoryImages[i - 1],
                          tableName: widget.directoryDB.dirName,
                        );
                        print('$i: ${directoryImages[i - 1].imgPath}');
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
                            images: directoryImages,
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
        body: RefreshIndicator(
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
        ),

        /// It calls createImage to create new image in existing directory
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera_alt),
          onPressed: createImage,
        ),
      ),
    ));
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
                savedDirectory = await fileOperations.saveToDevice(
                  context: context,
                  fileName: fileName,
                  images: directoryImages,
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
                images: directoryImages,
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

// child: Column(
//   children: [
//     Padding(
//       padding: EdgeInsets.only(bottom: 5.0),
//       child: Text('Pull to refresh'),
//     ),
//     Expanded(
//       child: GridView.builder(
//         itemCount: imageFilesPath.length,
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3),
//         itemBuilder: (BuildContext context, int index) {
//           return FocusedMenuHolder(
//             onPressed: null,
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 side: BorderSide(color: Colors.black, width: 2),
//                 borderRadius: BorderRadius.circular(0),
//               ),
//               elevation: 5,
//               child: GridTile(
//                 child: Image.file(
//                   File(imageFilesPath[index]),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             menuItems: [
//               FocusedMenuItem(
//                   title: Text('Delete'),
//                   onPressed: () {
//                     showDialog(
//                         context: context,
//                         builder: (context) {
//                           return AlertDialog(
//                             title: Text('Delete page'),
//                             content: Text(
//                                 'Are you sure you want to delete page'),
//                             actions: [
//                               TextButton(
//                                   onPressed: () =>
//                                       Navigator.pop(context),
//                                   child: Text('Cancle')),
//                               TextButton(
//                                   onPressed: () async {
//                                     await _delete(
//                                         imageFilesPath[index]);
//                                   },
//                                   child: Text('Delete'))
//                             ],
//                           );
//                         });
//                   }),
//               FocusedMenuItem(title: Text('Edit'), onPressed: () {}),
//             ],
//           );
//         },
//       ),
//     )
//   ],
// ),
