import 'dart:io' as f;
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as h;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'google_client.dart';

class FSGoogleDrive {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    // clientId: "",
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/drive.appdata' , "https://www.googleapis.com/auth/drive" ,
    ],
  );


  static AuthenticateClient? _authenticateClient ;

  final _folderName = "FadelTest2" ;
  String? _idFolder ;

  Future<void> setup({Function(GoogleSignInAccount)? callBack}) async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        final baseClient =  h.Client();
        _authenticateClient = AuthenticateClient(await _googleSignIn.currentUser!.authHeaders, baseClient);
        _getFolder(_folderName , (id) {
          _idFolder = id ;
          callBack!(account);
        });
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> handleSignIn() async {
    print("handleSignIn");
    try {
      var login = await _googleSignIn.signIn();
      setup();
    } catch (error) {
      print(error);
    }
  }

  Future<void> handleSignOut() => _googleSignIn.disconnect();

  //Create Folder
  Future _createFolder(String title , Function(String idFolder) callBack) async {
    try {
      if(_authenticateClient != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;
        ga.File fileToUpload = ga.File();

        fileToUpload.name = title ;
        fileToUpload.mimeType = "application/vnd.google-apps.folder" ;

        await drive.files.create(fileToUpload ,$fields: "id");

      }else {
        setup() ;
      }
    }catch(e) {
      print(e);
    }

  }

  void _getFolder(String title , Function(String) idFolder) async{
    print("Start Get Folder");
    try {
      if(_authenticateClient != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;
        var response = await drive.files.list(q: "name contains '$title'",pageSize: 1);
        print(response.toJson()) ;

        // print("value get folder void: ${response.files?.first.id}") ;
        if(response.files!.isEmpty) {
          _createFolder(_folderName, (newValue) => idFolder(newValue)) ;
        }else {
          _idFolder = response.files?.first.id ;
          idFolder(response.files!.first.id!) ;
        }


      }else {
        setup() ;
      }
    }catch(e) {
      print("Error _getFolder $e");
    }

  }

  //Upload File
  void upload({required f.File file , required Function(String) sizeFile , required Function(String) totalUploaded , required Function(String) progress , required Function(ga.File) finish , required Function(String) error}) async {
    try {
      if(_authenticateClient != null && _idFolder != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;

        ga.File fileToUpload = ga.File();

        fileToUpload.name = path.basename(file.absolute.path) ;
        fileToUpload.parents = [_idFolder!];

        drive.files.create(fileToUpload ,
            uploadMedia: ga.Media(file.openRead() , file.lengthSync() ,) ,uploadOptions: ga.UploadOptions.resumable ,$fields: "*"
        ).catchError((er, stackTrace) => error(er.toString()));

        int _total = 0 , _received = 0;
        _total =  file.absolute.lengthSync() ;
        sizeFile("${((_total / 1024) / 1024).toStringAsFixed(2)} MB");

        file.openRead().listen((value) {
          _received += value.length;
          totalUploaded("${((_received   / 1024) / 1024).toStringAsFixed(2)} MB");
          progress(((_received / _total) * 100).toStringAsFixed(1));
        }, onError: (error) {
          print("Error onError") ;

          error(error.toString());
        },onDone: () {
          print("Done!") ;

          finish(fileToUpload);
        });
      }else {
        setup() ;
      }
    }catch(e) {
      print("Error catch") ;
      error(e.toString());
    }

  }

  void listGoogleDriveFiles({required Function(ga.FileList) callBack}) async {
    try {
      if(_authenticateClient != null && _idFolder != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;
        drive.files.list(q: "'$_idFolder' in parents",$fields: "*").then((value) {
          callBack(value) ;
        }) ;
      }else {
        setup() ;
      }
    }catch(e) {
      print("Error catch") ;
    }

  }

  void downloadGoogleDriveFile({required String fName, required String gdID , required int size , required Function(String , String) downloadProgress , required Function() downloadFinish , required Function(dynamic) error}) async {

    try {
      if(_authenticateClient != null && _idFolder != null) {
        var drive = ga.DriveApi(_authenticateClient!);


        ga.Media response = await drive.files.get(gdID, downloadOptions: ga.DownloadOptions.fullMedia) as ga.Media;




        int _total = size, _received = 0;
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        print(tempPath) ;

        var writeFile = File('$tempPath/$fName').openWrite() ;
        response.stream.listen((data) {
          _received += data.length ;
          downloadProgress("${((_received   / 1024) / 1024).toStringAsFixed(2)} MB" , "${((_received / _total) * 100).toStringAsFixed(2)} %");
          writeFile.add(data);
        }, onDone: () async {
          writeFile.close() ;
          downloadFinish();
        }, onError: (error) {
          print("Some Error");
        });

      }
    }catch(e) {
      print(e) ;
      error(e);
    }
  }

  void delete({required String gdID , required Function(String ) done , required Function(dynamic) error}) async {

    try {
      if(_authenticateClient != null && _idFolder != null) {
        var drive = ga.DriveApi(_authenticateClient!);

        await drive.files.delete(gdID)
            .whenComplete(() => done(gdID))
            .onError((e, stackTrace) => error(e));

      }
    }catch(e) {
      print(e) ;
      error(e);
    }
  }




}