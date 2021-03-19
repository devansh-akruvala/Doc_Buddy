import 'dart:io';

//import 'package:flutter_scanner_cropper/flutter_scanner_cropper.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import './classes.dart';
import './dbhelper.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileOperations {
  String appName = 'doc_buddy';
  static bool pdfStatus;
  DatabaseHelper database = DatabaseHelper();

  /// return app path (if path dne it creates)
  Future<String> getAppPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$appName/');

    if (await _appDocDirFolder.exists()) {
      return _appDocDirFolder.path;
    } else {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

//  // CREATE PDF
  Future<bool> createPdf({selectedDirectory, fileName, images}) async {
    try {
      final output = File("${selectedDirectory.path}/$fileName.pdf");

      int i = 0;

      final doc = pw.Document();

      for (i = 0; i < images.length; i++) {
        // final image = PdfImage.file(
        //   doc.document,
        //   bytes: images[i].readAsBytesSync(),
        // );
        final image = pw.MemoryImage(
          images[i].readAsBytesSync(),
        );

        doc.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image)); // Center
            }));
      }

      output.writeAsBytesSync(await doc.save());
      print('edit till here');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // ADD IMAGES
  /// tahe pic using camera
  Future<File> openCamera() async {
    File image;
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.camera);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    return image;
  }

  /// tahe pic using galary
  Future<File> openGallery() async {
    File image;
    final _picker = ImagePicker();
    var picture = await _picker.getImage(source: ImageSource.gallery);
    if (picture != null) {
      final requiredPicture = File(picture.path);
      image = requiredPicture;
    }
    return image;
  }

  ///if directiry dne then create directory and calls create Createdirectory() which
  /// insert values in table DerictoryDetails
//// It also creates another table with foldername(directory name) to store info about images
  ///
  /// if dir exist it stores image in that dir with name = datetime.now() and add its info
  /// to directoryTable
  ///
  Future<void> saveImage(
      {File image, int index, String dirPath, int shouldCompress}) async {
    if (!await Directory(dirPath).exists()) {
      new Directory(dirPath).create();
      await database.createDirectory(
        directory: DirectoryOS(
          dirName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          dirPath: dirPath,
          imageCount: 0,
          created: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
          newName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
          lastModified: DateTime.parse(dirPath
              .substring(dirPath.lastIndexOf('/') + 1)
              .substring(
                  dirPath.substring(dirPath.lastIndexOf('/') + 1).indexOf(' ') +
                      1)),
          firstImgPath: null,
        ),
      );
    }

    /// Removed Index in image path
    File tempPic = File("$dirPath/${DateTime.now()}.jpg");
    image.copy(tempPic.path);
    database.createImage(
      image: ImageOS(
        imgPath: tempPic.path,
        idx: index,
        shouldCompress: shouldCompress,
      ),
      tableName: dirPath.substring(dirPath.lastIndexOf('/') + 1),
    );
    if (index == 1) {
      database.updateFirstImagePath(imagePath: tempPic.path, dirPath: dirPath);
    }
  }

  // // SAVE TO DEVICE
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

    Directory newDirectory = await DirectoryPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    return newDirectory;
  }

  Future<String> saveToDevice({
    BuildContext context,
    String fileName,
    dynamic images,
  }) async {
    print('1');
    Directory selectedDirectory;
    Directory scanDir = Directory("/storage/emulated/0/Doc_Buddy");
    Directory scanPdfDir = Directory("/storage/emulated/0/Doc_Buddy/PDF");

    try {
      if (!scanDir.existsSync()) {
        scanDir.createSync();
        scanPdfDir.createSync();
      }
      selectedDirectory = scanPdfDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }
    List<ImageOS> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (ImageOS image in images) {
        tempImages.add(File(image.imgPath));
      }
      images = tempImages;
    }
    fileName = fileName.replaceAll('-', '');
    fileName = fileName.replaceAll('.', '');
    fileName = fileName.replaceAll(':', '');

    pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );

    return (pdfStatus) ? selectedDirectory.path : null;
  }

  ///// this fun saves pdf to directory
  Future<bool> saveToAppDirectory(
      {BuildContext context, String fileName, dynamic images}) async {
    Directory selectedDirectory = await getApplicationDocumentsDirectory();
    List<ImageOS> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (ImageOS image in images) {
        tempImages.add(File(image.imgPath));
      }
      images = tempImages;
    }
    pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );
    print('PDF STATUS $pdfStatus');
    return pdfStatus;
  }

//// this delete image from pictures folder
  /// recursive true means empty dir or not it will completely delete the directory
  ///
  Future<void> deleteTemporaryFiles() async {
    // Delete the temporary files created by the image_picker package
    Directory appDocDir = await getExternalStorageDirectory();
    String appDocPath = "${appDocDir.path}/Pictures/";
    Directory del = Directory(appDocPath);
    if (await del.exists()) {
      del.deleteSync(recursive: true);
    }
    new Directory(appDocPath).create();
  }
  /////////////////////////////////////////
  ///
  ///
  ///

  Future<String> saveEditedToDevice({
    BuildContext context,
    String fileName,
    dynamic images,
  }) async {
    print('1');
    Directory selectedDirectory;
    Directory scanDir = Directory("/storage/emulated/0/Doc_Buddy");
    Directory editedPdfDir =
        Directory("/storage/emulated/0/Doc_Buddy/Edited_PDF");

    try {
      if (!scanDir.existsSync()) {
        scanDir.createSync();
        editedPdfDir.createSync();
      }
      if (!editedPdfDir.existsSync()) {
        editedPdfDir.createSync();
      }
      selectedDirectory = editedPdfDir;
    } catch (e) {
      print(e);
      selectedDirectory = await pickDirectory(context, selectedDirectory);
    }
    List<ImageOS> foo = [];
    if (images.runtimeType == foo.runtimeType) {
      var tempImages = [];
      for (ImageOS image in images) {
        tempImages.add(File(image.imgPath));
      }
      images = tempImages;
    }
    fileName = fileName.replaceAll('-', '');
    fileName = fileName.replaceAll('.', '');
    fileName = fileName.replaceAll(':', '');

    pdfStatus = await createPdf(
      selectedDirectory: selectedDirectory,
      fileName: fileName,
      images: images,
    );

    return (pdfStatus) ? selectedDirectory.path : null;
  }
}
/////////////////////////////////////////////////////////////////
///
///
