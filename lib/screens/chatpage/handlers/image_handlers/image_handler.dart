import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

class ImageHandler {
  final ValueNotifier<File?> _fileNotifier = ValueNotifier<File?>(null);
  ValueNotifier<File?> get fileNotifier => _fileNotifier;

  final ImagePicker _imagePicker = ImagePicker();
  Future<void> pickImage() async{
    try{
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if(pickedFile != null){
        _fileNotifier.value = File(pickedFile.path);
        log('Image selected: ${_fileNotifier.value!.path}');
      }
      else{
        _fileNotifier.value = null;
        log('No image selected');
      }

    }
    catch (e,t){
      log('ChatBloc _pickImage error: $e \n $t');
    }
  }

  Future<void> pickImageFromCamera() async{
    try{
      final pickedFileFromCamera = await _imagePicker.pickImage(source: ImageSource.camera);
      if(pickedFileFromCamera != null){
        _fileNotifier.value = File(pickedFileFromCamera.path);
        log('Image selected: ${_fileNotifier.value!.path}');
      }
      else{
        _fileNotifier.value = null;
        log('No image selected');
      }

    }
    catch(e,t){
      log('ChatBloc _pickImageFromCamera error: $e \n $t');
    }
  }

  Future<void> openFile(String filePath) async {
    try {
      // Check if file exists first
      final file = File(filePath);
      if (await file.exists()) {
        // Use open_filex package
        await OpenFilex.open(filePath);
      } else {
        log("Cannot open file: File does not exist at $filePath");
      }
    } catch (e, t) {
      log('ChatBloc _openFile error: $e \n $t');
    }
  }
  void clear(){
    _fileNotifier.value = null;
    log('ImageHandler: cleared picked image');

  }

}