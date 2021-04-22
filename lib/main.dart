import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      home: Recognizer(),
    );
  }
}

class Recognizer extends StatefulWidget {
  @override
  _RecognizerState createState() => _RecognizerState();
}

String loadImage = '';
List loadResult = [];
var status = 'live';
var sheetStatus = 'closed';
class _RecognizerState extends State<Recognizer> {
  Future<File> imageFile;
  List results = [];
  ImagePicker imagePicker;

  fromGallery() async {
    try {
      PickedFile pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
      loadResult = await classify(pickedFile.path);
      loadImage = pickedFile.path;
      setState(() {
        sheetStatus = 'open';
      });
      print('open');
    } catch (e) {
      print(e);
    }
  }

  CameraController _controller;

  void initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    onNewCameraSelected(firstCamera);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_controller.value.hasError) {
        print('Camera Error');
      }
    });

    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }
  }

  loadModel() async {
    String res = await Tflite.loadModel(
        model: "assets/popular_wine_V1_model.tflite",
        labels: "assets/popular_wine_V1_labelmap.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false
    );
  }

  classify(path) async {
    var recognitions = await Tflite.runModelOnImage(
        path: path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 5,
        threshold: 0.2,
        asynch: true
    );

    print(recognitions);
    setState(() {
      results = [];
    });

    if (recognitions != null) {
      recognitions.forEach((element) {
        results.add(element);
      });
    }

    return results;
  }

  fromCamera() async {
    try {
      if (_controller == null || !_controller.value.isInitialized) {
        return;
      }

      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      await _controller.takePicture(path);
      loadResult = await classify(path);
      loadImage = path;
      setState(() {
        sheetStatus = 'open';
      });
    } catch (e) {
      print('Error : ' + e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    loadModel();
    initCamera();
    Timer(Duration(seconds: 1), () {
      sheetStatus = 'closed';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
      if(!EasyLoading.isShow)
        EasyLoading.show(status: 'loading...');
      return Container(
        color: Colors.black,
      );
    }
    else if(EasyLoading.isShow)
      EasyLoading.dismiss();

    return Scaffold(
      backgroundColor: Color(0xff202020),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Popular\nWines Classifier',
                        style: TextStyle(
                          color: Color(0xfffdea94),
                          fontSize: 65,
                          fontFamily: 'Tangerine',
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Icon(
                          Icons.wine_bar_outlined,
                        color: Color(0xfffdea94),
                        size: 30,
                      )
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 400,
                        width: 300,
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: CameraPreview(_controller),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 340, right: 40),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(
                              Icons.refresh_sharp,
                            color: Color(0xfffdea94),
                            size: 30,
                          ),
                          splashRadius: 24,
                          onPressed: () {
                            _controller.dispose();
                            initCamera();
                          },
                        ),
                      ),
                    )
                  ],
                ),
                Stack(
                  children: [
                    Center(
                      child: Ink(
                        width: 80,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Color(0xfffdea94),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xfffdea94),
                              offset: Offset(4.0, 4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            ),
                            BoxShadow(
                              color: Color(0xfffdea94),
                              offset: Offset(-4.0, -4.0),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            )
                          ],
                        ),
                        child: IconButton(
                          iconSize: 40.0,
                          onPressed: () async {
                            if(!EasyLoading.isShow)
                              EasyLoading.show(status: 'loading...');
                            if(status == 'live')
                              await fromCamera();
                            else
                              await fromGallery();
                            _controller.dispose();
                            Navigator.pushReplacement(
                              context,
                              PageTransition(
                                  child: Recognizer(),
                                  type: PageTransitionType.bottomToTop,
                                  duration: Duration(milliseconds: 750)),
                            );
                            if(EasyLoading.isShow)
                              EasyLoading.dismiss();
                          },
                          icon: Icon(
                            Icons.wine_bar,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 24, top: 80),
                        child: Container(
                          height: 40,
                          width: 80,
                          decoration: BoxDecoration(
                              color: Color(0xff343434),
                              borderRadius: BorderRadius.all(Radius.circular(30))
                          ),
                          child: FlatButton(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                        color: status == 'gallery' ? Color(0xfffdea94) : Color(0xff343434),
                                    ),
                                  ),
                                  Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: Color(0xfffdea94),
                                      fontFamily: 'Charmonman',
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    width: 2,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                        color: Color(0xfffdea94),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                status = 'gallery';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 24, top: 80),
                        child: Container(
                          height: 40,
                          width: 80,
                          decoration: BoxDecoration(
                              color: Color(0xff343434),
                              borderRadius: BorderRadius.all(Radius.circular(30))
                          ),
                          child: FlatButton(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                        color: status == 'live' ? Color(0xfffdea94) : Color(0xff343434)
                                    ),
                                  ),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Color(0xfffdea94),
                                      fontFamily: 'Charmonman',
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    width: 2,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                        color: Color(0xfffdea94),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                status = 'live';
                              });
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            SizedBox.expand(
              child: DraggableScrollableSheet(
                initialChildSize: sheetStatus == 'closed' ? .08 : .85,
                minChildSize: .08,
                maxChildSize: .85,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(0xff343434),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                              color: Color(0xfffdea94)
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                ListView.builder(
                                  controller: scrollController,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        if(index == 0) Column(
                                          children: [
                                            SizedBox(height: 24),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.file(
                                                File(loadImage),
                                                fit: BoxFit.cover,
                                                height: 200,
                                                width: 240,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Center(
                                              child: Text(
                                                'Predictions',
                                                style: TextStyle(
                                                    color: Color(0xfffdea94),
                                                    fontWeight: FontWeight.bold,
                                                  fontSize: 24,
                                                  fontFamily: 'Charmonman'
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Table(
                                              border: TableBorder.all(),
                                              children: [
                                                TableRow(
                                                  children: [
                                                    Container(
                                                      height: 36,
                                                      color: Color(0xfffdea94),
                                                      child: Center(
                                                        child: Text(
                                                            'Wine',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                            fontFamily: 'Charmonman'
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      height: 36,
                                                      color: Color(0xfffdea94),
                                                      child: Center(
                                                        child: Text(
                                                          'Model Confidence',
                                                          style: TextStyle(
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: 'Charmonman'
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                ),
                                              ]
                                            ),
                                          ],
                                        ),
                                        Table(
                                          border: TableBorder.all(),
                                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                          children: [
                                            TableRow(
                                              children: [
                                                TableCell(
                                                  child: Text(
                                                    loadResult[index]['label'].toString().split('|')[1],
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xfffdea94),
                                                      fontFamily: 'Charmonman'
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 48,
                                                  child: Center(
                                                    child: Text(
                                                      ((loadResult[index]['confidence'] * 100) as double).toStringAsFixed(2) + ' %',
                                                      style: TextStyle(
                                                        color: Color(0xfffdea94),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily: 'Charmonman'
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                  itemCount: loadResult.length,
                                ),
                                ListView.builder(
                                  controller: scrollController,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      height: 500,
                                      child: Center(
                                          child: Text(
                                              "Sorry, But We Don't Have Any Picture To Run The Model On",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: loadResult.length == 0 ? Colors.grey : Colors.transparent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              fontFamily: 'Charmonman'
                                            ),
                                          )
                                      ),
                                    );
                                  },
                                  itemCount: 1,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


