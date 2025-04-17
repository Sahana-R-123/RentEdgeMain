import 'package:flutter/material.dart';
import 'dart:io';

class ProfileProvider with ChangeNotifier {
  File? _profileImage;

  File? get profileImage => _profileImage;

  void updateProfileImage(File image) {
    _profileImage = image;
    notifyListeners(); // Notify listeners to rebuild the UI
  }
}