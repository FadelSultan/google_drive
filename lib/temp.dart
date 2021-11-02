import 'dart:io' as f;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as h;
import 'package:path/path.dart' as path;

import 'google_client.dart';

class FSGoogleDrive {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    // clientId: "1045909319616-89h69414uuu9bl0ifkhi2uifgk8elo2t.apps.googleusercontent.com",
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/drive.appdata' , "https://www.googleapis.com/auth/drive" ,
    ],
  );


  static AuthenticateClient? _authenticateClient ;

  final _folderName = "FadelTest1" ;
  String? _idFolder ;

  Future<void> setup() async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        final baseClient =  h.Client();
        _authenticateClient = AuthenticateClient(await _googleSignIn.currentUser!.authHeaders, baseClient);
        _getFolder(_folderName , (id) {
          print("_idFolder: $id") ;
          _idFolder = id ;
        });
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> handleSignIn() async {
    print("handleSignIn");
    try {
      var login = await _googleSignIn.signIn();
      print(login!.email);
      setup();
    } catch (error) {
      print(error);
    }
  }

  Future<void> handleSignOut() => _googleSignIn.disconnect();



  //Create Folder
  Future _createFolder(String title , Function(String idFolder) callBack) async {
    // print(_authClient.)
    try {
      if(_authenticateClient != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;
        ga.File fileToUpload = ga.File();

        fileToUpload.name = title ;
        fileToUpload.mimeType = "application/vnd.google-apps.folder" ;

        var response = await drive.files.create(fileToUpload ,$fields: "id");//.asStream() ;

        // response.listen((event) {
        //   print(event.size) ;
        // });

        print(response.toJson()) ;
        callBack(response.toJson()["id"]) ;
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
  Future upload(f.File file) async {
    print("Start upload") ;
    print("_authenticateClient: $_authenticateClient") ;
    print("_idFolder: $_idFolder");
    try {
      if(_authenticateClient != null && _idFolder != null) {
        var drive = ga.DriveApi(_authenticateClient!) ;

        ga.File fileToUpload = ga.File();

        fileToUpload.name = "fadel${path.basename(file.absolute.path)}" ;
        fileToUpload.parents = [_idFolder!];

        var response = await drive.files.create(fileToUpload ,
            uploadMedia: ga.Media(file.openRead() , file.lengthSync() ,)
        );//.asStream() ;

        // response.listen((event) {
        //   print(event.size) ;
        // });

        print(response.toJson()) ;
      }else {
        setup() ;
      }
    }catch(e) {
      print(e);
    }

  }

}