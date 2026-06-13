import 'package:flutter/foundation.dart';

import '../domain/pos_models.dart';

/// Holds the signed-in user and the active cashier shift for the session.
/// Exposed via `provider` so any screen can read or react to changes.
class AppSession extends ChangeNotifier {
  AppUser? _user;
  PosShift? _shift;

  AppUser? get user => _user;
  PosShift? get shift => _shift;

  bool get isAuthenticated => _user != null;
  bool get hasOpenShift => _shift != null && _shift!.isOpen;

  void signIn(AppUser user) {
    _user = user;
    _shift = null;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _shift = null;
    notifyListeners();
  }

  void setShift(PosShift? shift) {
    _shift = shift;
    notifyListeners();
  }
}
