import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  List results = [];
  ImagePicker imagePicker;

  _imgFromCamera() async {
    PickedFile pickedFile =
    await imagePicker.getImage(source: ImageSource.camera);
    _image = File(pickedFile.path);
    setState(() {
      _image;
      classify(context);
    });
  }

  _imgFromGallery() async {
    PickedFile pickedFile =
    await imagePicker.getImage(source: ImageSource.gallery);
    _image = File(pickedFile.path);
    setState(() {
      _image;
      classify(context);
    });
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

  String loadImage = '';
  List loadResult = [];
  runModel(context) async {
    try {
      if (_controller == null || !_controller.value.isInitialized) {
        return;
      }

      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      await _controller.takePicture(path);
      setState(() async {
        loadResult = await classify(path);
        loadImage = path;
      });
    } catch (e) {
      print('Error : ' + e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    imagePicker = ImagePicker();
    loadModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

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
                Center(
                  child: Ink(
                    width: 100,
                    height: 200,
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
                      iconSize: 50.0,
                      onPressed: () {
                        runModel(context);
                      },
                      icon: Icon(
                        Icons.wine_bar,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox.expand(
              child: DraggableScrollableSheet(
                initialChildSize: .08,
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
                            child: ListView.builder(
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
                                            height: 240,
                                            width: 300,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            loadResult[index]['label'].toString().split('|')[1] + ' - ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          (loadResult[index]['confidence'] as double).toStringAsFixed(2),
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              itemCount: loadResult.length,
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


