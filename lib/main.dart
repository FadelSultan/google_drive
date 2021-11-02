import 'dart:io' as f;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as ga;

import 'google_drive.dart';
import 'model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Google Drive'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _googleDrive = FSGoogleDrive() ;

  String? _displayName;
  String? _email;
  String? _photoUrl ;
  bool _isGoogleSignIn = false ;

  String? _fileSize ;
  String? _dataUploaded ;
  String? _progress ;
  bool _isFinishDownload = true ;
  String? _errorUpload;


  var _listFile = ga.FileList() ;

  GoogleDriveModel? item ;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    _googleDrive.setup(callBack: (data) {
      setState(() {
        _isGoogleSignIn = true ;
        _displayName = data.displayName ;
        _email = data.email ;
        _photoUrl = data.photoUrl ;

      });
      _downloadList();
    }) ;
  }

  void _downloadList() {
    print("Start download list ") ;
    _googleDrive.listGoogleDriveFiles(callBack: (files) {
      if(files.files != null) {
        setState(() {
          item = GoogleDriveModel.generate(files.files!);
        });
      }
      setState(() {
        _listFile = files ;
        print("_listFile: ${_listFile.files?.length}") ;
      });
    }) ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[

          if(_isGoogleSignIn)Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if(_photoUrl != null)CircleAvatar(
                  backgroundImage: NetworkImage(_photoUrl!),
                ),
                const SizedBox(width: 10,) ,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(_email != null)Text("Email: $_email" , style: const TextStyle(fontSize: 14 , color: Colors.black54 ,fontWeight: FontWeight.bold),),
                    if(_displayName != null)Text("DisplayName: $_displayName" , style: const TextStyle(fontSize: 14 , color: Colors.black54 ,fontWeight: FontWeight.bold),)
                  ],
                ),
                Center(
                  child: TextButton(onPressed: () async {
                    _googleDrive.handleSignOut();
                  }, child: const Text("Sign out")),
                ),
              ],
            ),
          ),

          if(!_isGoogleSignIn)TextButton(onPressed: () {
            // drive.httpClient();
            _googleDrive.handleSignIn() ;
            setState(() {

            });
          }, child: Text("Sign in")) ,

          if(_fileSize != null && _dataUploaded != null && _errorUpload == null)Row(children: [
            Text("File Size: $_fileSize"),
            const SizedBox(width: 10,),
            Text("Uploaded: $_dataUploaded"),
          ],) ,
          if(_progress != null && !_isFinishDownload && _errorUpload == null)Text("Uploading: $_progress %") ,
          if(_isFinishDownload && _errorUpload == null && _progress != null)const Text("Uploading is finish") ,
          if(_errorUpload != null )Text("Error: $_errorUpload") ,
          if(_isFinishDownload)TextButton(onPressed: () async {
            _isFinishDownload = false;
            var file = f.File("/Users/fadel/Desktop/icon-app.png");
            _googleDrive.upload(
              file: file ,
              sizeFile: (fileSize) => setState(() { _fileSize = fileSize; }),
              totalUploaded: (dataUploaded) => setState(() { _dataUploaded = dataUploaded; }),
              progress: (progress) => setState(() { _progress = progress; }),
              finish: (newFile) => setState(() {
                _isFinishDownload = true;
              }),
              error: (error) => setState(() { _errorUpload = error; _isFinishDownload = true; }),
            );
          }, child: Text("Upload new file")),

          TextButton(onPressed: () async {
            _downloadList() ;
            print("Start list") ;
          }, child: Text("download list")),

          const SizedBox(height: 5,),
          if(_listFile.files?.length != 0)Flexible(
            child: ListView.builder(
                itemCount:item?.fileList.length ,
                itemBuilder: (context ,index) {
                  return _row(_listFile.files?[index] , index);
                }),
          ),

        ],
      ),
    );
  }

  Widget _row(ga.File? file , int index) {
    final ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 14 , color: Colors.red));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Column(
            children: [
              Text("Title: ${file?.name}") ,
              Text("Date: ${file?.createdTime}"),
              Text("Size: ${file?.size}"),
              if(item?.downloadSize[index] != "" && item?.downloadPercent[index] != "" )Text("Start download: ${item?.downloadSize[index]} of ${file?.size} - ${item?.downloadPercent[index]}") ,
              if(item?.downloadFinish[index] != "") Text(item?.downloadFinish[index] ?? "") ,
              Row(
                children: [
                  ElevatedButton(
                    style: style,
                    onPressed: () {
                      _googleDrive.downloadGoogleDriveFile(fName: file?.name ?? "",gdID:  file?.id ?? "" , size: int.parse(file?.size ?? "0"),
                        downloadProgress: (downloadSize , percent){
                        setState(() {
                          item?.downloadSize[index] = downloadSize ;
                          item?.downloadPercent[index] = percent ;
                        });
                        },
                        downloadFinish: () {
                        setState(() {
                          item?.downloadSize[index] = "" ;
                          item?.downloadPercent[index] = "" ;
                        });
                        item?.downloadFinish[index] = "Download is finished!" ;
                        },
                        error: (e) {
                          final snackBar = SnackBar(content: Text(e.toString()) ,action: SnackBarAction(label: "ReConnect",onPressed: () {
                            FSGoogleDrive().handleSignIn() ;
                          },),);
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      ) ;
                    },
                    child: const Text('Download'),
                  ),
                  const SizedBox(width: 10,),
                  ElevatedButton(
                    style: style,
                    onPressed: () {
                      _googleDrive.delete(gdID: file!.id!,
                          done: (id) {
                        setState(() {
                          item?.fileList.removeAt(index) ;
                          item?.downloadFinish.removeAt(index);
                          item?.downloadPercent.removeAt(index) ;
                        });
                          }, error: (error) {
                            final snackBar = SnackBar(content: Text(error.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      });
                    },
                    child: const Text('Delete'),
                  ),
                ],
              )
            ],
          ),

        ],
      ),
    );
  }


}
