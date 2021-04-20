import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Recognizer(),
    );
  }
}

class Recognizer extends StatefulWidget {
  @override
  _RecognizerState createState() => _RecognizerState();
}

class _RecognizerState extends State<Recognizer> {
  Future<File> imageFile;
  File _image;
  String result = '';
  ImagePicker imagePicker;

  _imgFromCamera() async {
    PickedFile pickedFile =
    await imagePicker.getImage(source: ImageSource.camera);
    _image = File(pickedFile.path);
    setState(() {
      _image;
      classify();
    });
  }

  _imgFromGallery() async {
    PickedFile pickedFile =
    await imagePicker.getImage(source: ImageSource.gallery);
    _image = File(pickedFile.path);
    setState(() {
      _image;
      classify();
    });
  }

  loadModel() async {
    String res = await Tflite.loadModel(
        model: "assets/popular_wine_V1_model.tflite",
        labels: "assets/popular_wine_V1_labelmap.txt",
        numThreads: 1, // defaults to 1
        isAsset: true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate: false // defaults to false, set to true to use GPU delegate
    );
  }

  classify() async {
    var recognitions = await Tflite.runModelOnImage(
        path: _image.path,   // required
        imageMean: 0.0,   // defaults to 117.0
        imageStd: 255.0,  // defaults to 1.0
        numResults: 5,    // defaults to 5
        threshold: 0.2,   // defaults to 0.1
        asynch: true      // defaults to true
    );

    print(recognitions);
    setState(() {
      result = '';
    });

    if(recognitions != null) {
      recognitions.forEach((element) {
        setState(() {
          result += element['label'] + ' ' + (element['confidence'] as double).toStringAsFixed(2) + '\n';
        });
      });
    }
  }

  @override
  void initState() {
    imagePicker = ImagePicker();
    loadModel();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: Column(
            children: [
              SizedBox(
                width: 100,
              ),
              Container(
                margin: EdgeInsets.only(top: 100),
                child: Stack(children: <Widget>[
                  Center(
                    child: FlatButton(
                      onPressed: _imgFromGallery,
                      onLongPress: _imgFromCamera,
                      child: Container(
                        margin: EdgeInsets.only(top: 5),
                        child: _image != null
                            ? Image.file(
                          _image,
                          width: 133,
                          height: 198,
                          fit: BoxFit.fill,
                        )
                            : Container(
                          width: 140,
                          height: 190,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Text(
                  '$result',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'finger_paint', fontSize: 26),
                ),
              ),
            ],
          ),
        )
    );
  }
}

