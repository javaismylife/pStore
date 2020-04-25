import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:device_info/device_info.dart';


void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'pStore Login'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 2. created object of localauthentication class
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  // 3. variable for track whether your device support local authentication means
  //    have fingerprint or face recognization sensor or not
  bool _hasFingerPrintSupport = false;
  // 4. we will set state whether user authorized or not
  bool _authorizedOrNot = false;
  // 5. list of avalable biometric authentication supports of your device will be saved in this array
  List<BiometricType> _availableBuimetricType = List<BiometricType>();

  Future<void> _getBiometricsSupport() async {
    // 6. this method checks whether your device has biometric support or not
    bool hasFingerPrintSupport = false;
    try {
      hasFingerPrintSupport = await _localAuthentication.canCheckBiometrics;
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    setState(() {
      _hasFingerPrintSupport = hasFingerPrintSupport;
    });
  }

  Future<void> _getAvailableSupport() async {
    // 7. this method fetches all the available biometric supports of the device
    List<BiometricType> availableBuimetricType = List<BiometricType>();
    try {
      availableBuimetricType =
      await _localAuthentication.getAvailableBiometrics();
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    setState(() {
      _availableBuimetricType = availableBuimetricType;
    });
  }

  Future<void> _authenticateMe() async {
    try {
      while(!_authorizedOrNot) {
        _authorizedOrNot =
        await _localAuthentication.authenticateWithBiometrics(
          localizedReason: "Authenticate for Testing", // message for dialog
          useErrorDialogs: true, // show error in dialog
          stickyAuth: false, // native process
        );
      }
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => new CredentialPage()),
        );
  }

  @override
  void initState() {
    _getBiometricsSupport();
    _getAvailableSupport();
    _authenticateMe();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Has FingerPrint Support : $_hasFingerPrintSupport"),
            Text(
                "List of Biometrics Support: ${_availableBuimetricType.toString()}"),
            Text("Authorized : $_authorizedOrNot"),

          ],
        ),
      ),
    );
  }
}
class CredentialPage extends StatefulWidget {

  CredentialPage();


  @override
  _CredentialPageState createState() => _CredentialPageState();
}
class _CredentialPageState extends State<CredentialPage> {
  List<Credentials>  credentialsList = new List();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credentials Page'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.add),
            onPressed: () =>     Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddCredentialOverlay(index:0,operation:"ADD",credentialsList:this.credentialsList)),
            )
          ),
        ],
      ),
     body: ListView.builder(
       physics: const AlwaysScrollableScrollPhysics(),
             // Let the ListView know how many items it needs to build.
      itemCount: credentialsList.length,
      // Provide a builder function. This is where the magic happens.
      // Convert each item into a widget based on the type of item it is.
      itemBuilder: (context, index) => _listItemBuilder(index),
    ),
    );
  }
  ListTile _listItemBuilder(int index) {
    return
          ListTile(
            title: Text(credentialsList[index].title,  style: new TextStyle(color: Colors.redAccent)
            , textAlign: TextAlign.center),


            subtitle:
              Table(
                children: [
                  TableRow(
                    children:[
                      TableCell(child: Center(child: Text("User Name"))),
                      TableCell(child: Center(child: Text("Password")))
                    ]
                    ),
                  TableRow(
                      children:[
                        TableCell(child: Center(child: Text(credentialsList[index].userName))),
                        TableCell(child: Center(child: Text(credentialsList[index].password)))
                      ]
                  ),
                  TableRow(
                      children:[
                        TableCell(child: Center(child:     new FlatButton(onPressed: () {_edit(index);}, child: new Text("EDIT")))),
                        TableCell(child: Center(child:   new FlatButton(onPressed: () {_delete(index);},
                            child: new Text("DELETE",
                              style: new TextStyle(color: Colors.redAccent),))))
                    ,

                      ]
                  )
                ])
          );

  }
  void _getData() {
    LocalStorageHelper storageHelper = new LocalStorageHelper();
    storageHelper._getListFromJsonFile().then((List<Credentials> credentialsList) {
      setState(() {
        credentialsList.sort((a, b) {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        this.credentialsList = credentialsList;
        print(    this.credentialsList);

      });

    });

  }

  void _delete(int index){
    setState(() {
      this.credentialsList.removeAt(index);
      LocalStorageHelper localStorageHelper = new LocalStorageHelper();
      localStorageHelper._writeContent(jsonEncode(  this.credentialsList.map((e) => e.toJson()).toList()));
    });
  }
  void _edit(int index){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddCredentialOverlay(index:index,operation:"EDIT",credentialsList:this.credentialsList)));
  }
  @override
  void initState(){
    _getData();
    super.initState();

  }
}


class AddCredentialOverlay extends StatelessWidget {
  int index;
  final String operation;
  List<Credentials> credentialsList;
  TextEditingController nameInputController = new TextEditingController();
  TextEditingController userNameInputController = new TextEditingController();
  TextEditingController passwordInputController = new TextEditingController();
  Credentials tempCredentials;
  AddCredentialOverlay({this.index,@required this.operation,@required this.credentialsList} ) : super(){
    if(this.operation == 'EDIT') {
      nameInputController.text = this.credentialsList[index].title;
      userNameInputController.text = this.credentialsList[index].userName;
      passwordInputController.text = this.credentialsList[index].password;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Form(
          child: ListView(
            children: <Widget>[
              TextFormField(

                controller: nameInputController,
                decoration: InputDecoration(
                    labelText: 'Name',
                ),
              ),
              SizedBox(height: 16.0,),
              TextFormField(

                controller: userNameInputController,
                decoration: InputDecoration(
                    labelText: 'User Name'
                ),
              ),
              SizedBox(height: 16.0,),
              TextFormField(
                controller: passwordInputController,
                decoration: InputDecoration(
                    labelText: 'Password'
                ),
              ),
              SizedBox(height: 16.0,),
              RaisedButton(
                child: Text('SUBMIT'),
                onPressed: () {
                  tempCredentials = new Credentials(this.nameInputController.text,
                      this.userNameInputController.text,  this.passwordInputController.text);
                  _save(this.tempCredentials);
                  Navigator.pop(context);
                  },
              )
            ],
          ),
        ),
      ),
    );
  }
  void _save(  Credentials credentials){
    LocalStorageHelper localStorageHelper = new LocalStorageHelper();
    if(operation == 'EDIT') {
      this.credentialsList.removeAt(index);
      this.credentialsList.insert(index,credentials);
    }else{
      this.credentialsList.add(credentials);
    }
    localStorageHelper._writeContent(
        jsonEncode(this.credentialsList.map((e) => e.toJson()).toList()));
  }
}

class Credentials{

  String title;
  String userName;
  String password;
  Credentials(String title,String userName,String password) {

    this.title =title;
    this.userName = userName;
    this.password = password;
  }
  factory Credentials.fromJson(Map<String, dynamic> json){
    return new Credentials(

    json['userName'],
       json['title'],
     json['password'],
    );
  }
  Map toJson() => {
    'title': this.title,
    'userName': this.title,
    'password': this.password
  };

}
//class CredentialsList {
//  final List<Credentials> credentials;
//
//  CredentialsList({
//    this.credentials,
//  });
//  factory CredentialsList.fromJson(List<dynamic> parsedJson) {
//
//    List<Credentials> credentials = parsedJson.map((i)=>Credentials.fromJson(i)).toList();
//
//    return new CredentialsList(
//      credentials: credentials,
//    );
//  }
//}

class LocalStorageHelper{
  var base64Key = 'Sf8GZrbuxRCfC7ZHLFI';
  var utf8Key = 'Sf8GZrbuxRCfC7ZHLFI';
  Future<String>  _localPath() async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    return directory.path;
  }
  Future<File>  _localFile() async {
    final path = await _localPath();
    return File('$path/credentials.json');
  }
  Future<File> _writeContent(String credentialsJsonString) async {
    final file = await _localFile();
    credentialsJsonString = base64.encode(utf8.encode(credentialsJsonString) );
    if(await file.exists()) {
      return file.writeAsString(credentialsJsonString);
    }else {
      final path = await _localPath();
      var myFile = new File('$path/credentials.json');
      return myFile.writeAsString(credentialsJsonString);
    }
  }
  Future< List<Credentials>>  _getListFromJsonFile() async {
    final file = await _localFile();
    if (await file.exists()) {
      String contents = await file.readAsString();
      contents = utf8.decode(base64.decode(contents));
      List<dynamic> credentialsJson = jsonDecode(contents) as List;
      return credentialsJson.map((i) =>
          Credentials.fromJson(i)).toList();
    }else {
     return new List<Credentials>();
    }
  }

}