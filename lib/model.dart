import 'package:googleapis/drive/v3.dart' as ga;

class GoogleDriveModel {

  List<ga.File> fileList ;
  List<String> downloadSize ;
  List<String> downloadPercent ;
  List<String> downloadFinish ;

  GoogleDriveModel(this.fileList, this.downloadSize, this.downloadPercent , this.downloadFinish);

  static GoogleDriveModel generate(List<ga.File> list) {
    return GoogleDriveModel(list,
        List.generate(list.length, (index) => "" ),
        List.generate(list.length, (index) => "" ),
        List.generate(list.length, (index) => "" ),
    ) ;
  }
}