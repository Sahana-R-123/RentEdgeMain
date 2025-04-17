import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Import the AppUser model

class UserProvider with ChangeNotifier {
  AppUser? _user;

  // Getter for the current user
  AppUser? get user => _user;

  // Setter for the current user
  void setUser(AppUser user) {
    _user = user;
    notifyListeners(); // Notify listeners to update the UI
  }
}