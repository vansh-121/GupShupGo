import 'package:flutter/foundation.dart';

enum CallState { Idle, Calling, Ringing, Connected, Ended }

class CallStateNotifier extends ChangeNotifier {
  CallState _state = CallState.Idle;

  CallState get state => _state;

  void updateState(CallState newState) {
    _state = newState;
    notifyListeners();
  }
}
