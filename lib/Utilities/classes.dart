class DirectoryDB {
  String dirName;
  String dirPath;
  DateTime created;
  int imageCount;
  String firstImgPath;
  DateTime lastModified;
  String newName;

  DirectoryDB({
    this.dirName,
    this.created,
    this.dirPath,
    this.firstImgPath,
    this.imageCount,
    this.lastModified,
    this.newName,
  });
}

class ImageDB {
  int idx;
  String imgPath;
  int shouldCompress;

  ImageDB({
    this.idx,
    this.imgPath,
    this.shouldCompress,
  });
}

class Locker {
  String name;
  String createdOn;
  String path;
  Locker({this.name, this.path, this.createdOn});
}
