import 'package:flutter/material.dart';
import 'user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  // Setter for user object
  void setUser(User user) {
    _user = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Update nickname
  void updateUserNickname(String newNickname) {
     if (_user == null) {
    // Add error handling logic (e.g. log output or debug messages)
    print('Error: _user is null');
    return;
  }
    if (_user != null) {
      _user = User(_user!.userKey, _user!.userId, newNickname, _user!.dis_type);
      notifyListeners();
    }
  }


  // Updating types
void updateDisType(int disType) {
  if (_user == null) {
    // Add error handling logic (e.g. log output or debug messages)
    print('Error: _user is null');
    return;
  }

  // Update if _user is not null
  _user = User(
    _user!.userKey, 
    _user!.userId, 
    _user!.user_nickname, 
    disType
  );

  // Notify status changes
  notifyListeners();
}


//  // Deleting UserKey records from the provider when a member leaves
//   void setUserKeytoNULL() {
//     if (_user != null) {
//       _user = User(
//           null,
//           _user!.userId,
//           _user!.user_nickname,
//           null);
//     } else {
//       _user = User(
//           null,
//           _user!.userId, // int.parse() Remove, use userId directly
//           'New User', // Setting a default nickname
//           null);
//     }
//     _isLoggedIn = true;
//     notifyListeners();
//   }

  // Log out
  void logOut() {
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}
