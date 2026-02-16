import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/services/status_service.dart';

class StatusProvider extends ChangeNotifier {
  final StatusService _statusService = StatusService();

  StatusModel? _myStatus;
  List<StatusModel> _otherStatuses = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _myStatusSubscription;
  StreamSubscription? _otherStatusesSubscription;

  StatusModel? get myStatus => _myStatus;
  List<StatusModel> get otherStatuses => _otherStatuses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the current user has an active status.
  bool get hasMyStatus => _myStatus != null && _myStatus!.hasActiveStatus;

  /// Initialize listeners for the given user.
  void initialize(String userId) {
    _listenToMyStatus(userId);
    _listenToOtherStatuses(userId);
  }

  void _listenToMyStatus(String userId) {
    _myStatusSubscription?.cancel();
    _myStatusSubscription = _statusService.getMyStatus(userId).listen(
      (status) {
        _myStatus = status;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void _listenToOtherStatuses(String userId) {
    _otherStatusesSubscription?.cancel();
    _otherStatusesSubscription = _statusService.getAllStatuses(userId).listen(
      (statuses) {
        _otherStatuses = statuses;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Upload a text status.
  Future<void> uploadTextStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required String text,
    required String backgroundColor,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _statusService.uploadTextStatus(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        text: text,
        backgroundColor: backgroundColor,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload an image status.
  Future<void> uploadImageStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _statusService.uploadImageStatus(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        imageUrl: imageUrl,
        caption: caption,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a status item as viewed.
  Future<void> markAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
  }) async {
    try {
      await _statusService.markStatusAsViewed(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
        viewerId: viewerId,
      );
    } catch (e) {
      print('Error marking status as viewed: $e');
    }
  }

  /// Delete a specific status item.
  Future<void> deleteStatusItem({
    required String userId,
    required String statusItemId,
  }) async {
    try {
      await _statusService.deleteStatusItem(
        userId: userId,
        statusItemId: statusItemId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _myStatusSubscription?.cancel();
    _otherStatusesSubscription?.cancel();
    super.dispose();
  }
}
