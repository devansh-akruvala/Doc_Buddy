import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import './classes.dart';

class DatabaseHelper {
  //// singleton constructor
  DatabaseHelper._privateConstructor();

  DatabaseHelper();

  static final instance = DatabaseHelper._privateConstructor();
  static final _dbName = "mydb.db";
  static final _dbVersion = 1;

  ///master table name
  static final _masterTableName = 'DirectoryDetails';
  static final _lockerTableName = 'LockerDetails';
  static final _editTableName = 'EditDetails';

  /// global database instance for this file
  static Database _database;

  String path;
  String _dirTableName;

  /// if database instance is not null return instance else create instane;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  /// this create instane of db
  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  /// gives directory names after cleaning
  getDirectoryTableName(String dirName) {
    dirName = dirName.replaceAll('-', '');
    dirName = dirName.replaceAll('.', '');
    dirName = dirName.replaceAll(' ', '');
    dirName = dirName.replaceAll(':', '');
    _dirTableName = '"' + dirName + '"';
  }

  /// this fun creates table DirectoryDetails in db
  FutureOr<void> _onCreate(Database db, int version) {
    //// creating table masterTable
    db.execute('''
      CREATE TABLE $_masterTableName(
      dir_name TEXT,
      dir_path TEXT,
      created TEXT,
      image_count INTEGER,
      first_img_path TEXT,
      last_modified TEXT,
      new_name TEXT)
      ''');

    //// Creating Locker Table
    db.execute('''
    CREATE TABLE $_lockerTableName(
      name TEXT,
      created TEXT,
      path TEXT)
    ''');
    db.execute('''
      CREATE TABLE $_editTableName(
      idx INTEGER,
      img_path TEXT,
      shouldCompress INTEGER)
      ''');
  }

  //// this is used to insert values in table DerictoryDetails
//// It also creates another table with foldername(directory name) to store info about images
  ///
  Future createDirectory({DirectoryOS directory}) async {
    Database db = await instance.database;
    int index = await db.insert(_masterTableName, {
      'dir_name': directory.dirName,
      'dir_path': directory.dirPath,
      'created': directory.created.toString(),
      'image_count': directory.imageCount,
      'first_img_path': directory.firstImgPath,
      'last_modified': directory.lastModified.toString(),
      'new_name': directory.newName
    });

    getDirectoryTableName(directory.dirName);
    print('Directory Index: $index');
    db.execute('''
      CREATE TABLE $_dirTableName(
      idx INTEGER,
      img_path TEXT,
      shouldCompress INTEGER)
      ''');
  }

  //// this fun insert info about images in directories(folder) tables
  ///it also update master table Derectories details (update count of image for new image inseryed)
  Future createImage({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    int index = await db.insert(_dirTableName, {
      'idx': image.idx,
      'img_path': image.imgPath,
      'shouldCompress': image.shouldCompress,
    });
    print('Image Index: $index');

    var data = await db.query(
      _masterTableName,
      columns: ['image_count'],
      where: 'dir_name == ?',
      whereArgs: [tableName],
    );
    int tempcount = data[0]['image_count'];
    await db.update(
        _masterTableName,
        {
          'image_count': tempcount + 1, //+ 1, add it one please
          'last_modified': DateTime.now().toString()
        },
        where: 'dir_name == ?',
        whereArgs: [tableName]);
  }

  /// this fun delect floder table (directory table) and removes info from master table
  Future deleteDirectory({String dirPath}) async {
    Database db = await instance.database;
    await db
        .delete(_masterTableName, where: 'dir_path == ?', whereArgs: [dirPath]);
    String dirName = dirPath.substring(dirPath.lastIndexOf("/") + 1);
    getDirectoryTableName(dirName);
    await db.execute('DROP TABLE $_dirTableName');
  }

  /// this fun delete images from directory(folder) and removes its entry
  Future deleteImage({String imgPath, String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    await db
        .delete(_dirTableName, where: 'img_path == ?', whereArgs: [imgPath]);
  }

  /// <---- Master Table Operations ---->

  /// returns info in main table;
  Future getMasterData() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_masterTableName);
    return data;
  }

//// updates firsyt imahe path
  Future<int> updateFirstImagePath({String imagePath, String dirPath}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'first_img_path': imagePath},
        where: 'dir_path == ?', whereArgs: [dirPath]);
  }

  /// rename file name (explore not sure)
  Future<int> renameDirectory({DirectoryOS directory}) async {
    Database db = await instance.database;
    return await db.update(_masterTableName, {'new_name': directory.newName},
        where: 'dir_name == ?', whereArgs: [directory.dirName]);
  }

  //// update image count in master table
  void updateImageCount({String tableName}) async {
    Database db = await instance.database;
    var data = await getDirectoryData(tableName);
    db.update(
      _masterTableName,
      {'image_count': data.length},
      where: 'dir_name == ?',
      whereArgs: [tableName],
    );
  }

  /// <---- Directory Table Operations ---->
  /// return directory data
  Future getDirectoryData(String tableName) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    List<Map<String, dynamic>> data = await db.query(_dirTableName);
    return data;
  }

  // update images path
  Future<int> updateImagePath({String tableName, ImageOS image}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'img_path': image.imgPath,
        },
        where: 'idx == ?',
        whereArgs: [image.idx]);
  }

  // update images index
  Future<int> updateImageIndex({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    getDirectoryTableName(tableName);
    return await db.update(
        _dirTableName,
        {
          'idx': image.idx,
        },
        where: 'img_path == ?',
        whereArgs: [image.imgPath]);
  }

  /// info about compress
  ///
  Future<int> updateShouldCompress({ImageOS image, String tableName}) async {
    Database db = await instance.database;
    getDirectoryData(tableName);
    return await db.update(
        _dirTableName,
        {
          'shouldCompress': false,
        },
        where: 'img_path == ?',
        whereArgs: [image.imgPath]);
  }

//////////////// Locker Operations
  /// this method is used to insert data in locker table
  Future createLockerFile({Locker file}) async {
    Database db = await instance.database;
    int index = await db.insert(_lockerTableName,
        {'name': file.name, 'created': file.createdOn, 'path': file.path});
    print('Locker ind: $index');
  }

  /// returns info in locker table;
  Future getLockerData() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> data = await db.query(_lockerTableName);
    return data;
  }

  /// this deletes a locker file and removes its entry from lockaer table
  Future deleteLockerFile({String filePath}) async {
    Database db = await instance.database;
    await db
        .delete(_lockerTableName, where: 'path == ?', whereArgs: [filePath]);
  }

///////////////////// Pdf Edit database
  Future createImageTemp({ImageOS image}) async {
    Database db = await instance.database;
    print(image.imgPath);
    int index = await db.insert(_editTableName, {
      'idx': image.idx,
      'img_path': image.imgPath,
      'shouldCompress': image.shouldCompress,
    });
    print('Image Index: $index');
  }

  /// this fun delect floder table (directory table) and removes info from master table
  Future deleteTempDirectory() async {
    Database db = await instance.database;
    await db.delete(_editTableName);
  }

  /// this fun delete images from directory(folder) and removes its entry
  Future deleteTempImage({String imgPath}) async {
    Database db = await instance.database;
    await db
        .delete(_editTableName, where: 'img_path == ?', whereArgs: [imgPath]);
  }

  Future getTempDirectoryData() async {
    Database db = await instance.database;
    getDirectoryTableName(_editTableName);
    List<Map<String, dynamic>> data = await db.query(_dirTableName);
    return data;
  }

  Future<int> updateTempImagePath({ImageOS image}) async {
    Database db = await instance.database;
    return await db.update(
        _editTableName,
        {
          'img_path': image.imgPath,
        },
        where: 'idx == ?',
        whereArgs: [image.idx]);
  }
}
