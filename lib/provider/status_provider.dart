import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/services/status_service.dart';

class StatusProvider extends ChangeNotifier {
  final StatusService _statusService;

  StatusModel? _myStatus;
  List<StatusModel> _otherStatuses = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _myStatusSubscription;
  StreamSubscription? _otherStatusesSubscription;

  // Optimistic items the user has just posted but Firestore hasn't echoed
  // back yet. Merged into [myStatus] so the "My Status" tile updates the
  // moment the user taps Send — same UX guarantee as WhatsApp. Items are
  // dropped from this list as soon as the real status doc arrives with
  // their id, or if the upload fails.
  final List<StatusItem> _pendingMyItems = [];
  String? _pendingUserId;
  String? _pendingUserName;
  String? _pendingUserPhotoUrl;
  String? _pendingUserPhoneNumber;

  /// Cached merge of [_myStatus] with any still-pending optimistic items.
  /// Kept in sync by [_recomputeMerged], which runs on every state change
  /// (stream emit, pending add/remove) right before notifyListeners — so the
  /// getters below are pure reads that never return a stale value. Recomputing
  /// only on change (not on every getter call) also avoids minting a new
  /// StatusModel with a fresh DateTime.now() on each access, which would churn
  /// rebuilds.
  StatusModel? _cachedMergedStatus;

  /// Whether the user has at least one upload still in flight. Lets the UI
  /// show a subtle "uploading" hint instead of nothing.
  bool get hasPendingUpload => _pendingMyItems.isNotEmpty;

  StatusModel? get myStatus => _cachedMergedStatus;
  List<StatusModel> get otherStatuses => _otherStatuses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the current user has an active status.
  bool get hasMyStatus => _cachedMergedStatus?.hasActiveStatus ?? false;

  StatusProvider({StatusService? statusService})
      : _statusService = statusService ?? StatusService();

  void initialize(String userId) {
    // Eagerly populate the in-memory cache from local SQLite so
    // previously-seen text statuses render instantly — before any
    // Firestore query completes.
    unawaited(_statusService.preWarmFromDisk());
    _listenToMyStatus(userId);
    _listenToOtherStatuses(userId);
  }

  /// Rebuilds [_cachedMergedStatus] from [_myStatus] plus any still-pending
  /// optimistic items. Pending items whose id already appears in the real
  /// status (the server has echoed them back) are dropped here too, so a
  /// freshly-posted item is never shown twice. Call before notifyListeners on
  /// any change to [_myStatus] or [_pendingMyItems].
  void _recomputeMerged() {
    final real = _myStatus;
    if (_pendingMyItems.isEmpty) {
      _cachedMergedStatus = real;
      return;
    }
    final realIds = <String>{
      if (real != null) ...real.statusItems.map((s) => s.id),
    };
    final pending =
        _pendingMyItems.where((p) => !realIds.contains(p.id)).toList();
    if (pending.isEmpty) {
      _cachedMergedStatus = real;
      return;
    }
    _cachedMergedStatus = StatusModel(
      id: real?.id ?? _pendingUserId ?? '',
      userId: real?.userId ?? _pendingUserId ?? '',
      userName: real?.userName ?? _pendingUserName ?? '',
      userPhotoUrl: real?.userPhotoUrl ?? _pendingUserPhotoUrl,
      userPhoneNumber: real?.userPhoneNumber ?? _pendingUserPhoneNumber,
      statusItems: <StatusItem>[
        if (real != null) ...real.statusItems,
        ...pending,
      ],
      lastUpdated: DateTime.now(),
    );
  }

  void _listenToMyStatus(String userId) {
    _myStatusSubscription?.cancel();
    _myStatusSubscription = _statusService.getMyStatus(userId).listen(
      (status) {
        _myStatus = status;
        // Drop pending items the server has echoed back — now matched by the
        // shared status-item id (see postEncrypted*StatusInBackground).
        if (status != null) {
          final serverIds = status.statusItems.map((s) => s.id).toSet();
          _pendingMyItems.removeWhere((p) => serverIds.contains(p.id));
        }
        _recomputeMerged();
        notifyListeners();
        if (status != null) {
          _statusService.preDecryptStatuses([status], userId);
        }
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
        _statusService.preDecryptStatuses(statuses, userId);
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void _trackIdentity({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
  }) {
    _pendingUserId = userId;
    _pendingUserName = userName;
    _pendingUserPhotoUrl = userPhotoUrl;
    _pendingUserPhoneNumber = userPhoneNumber;
  }

  void _addPending(StatusItem item) {
    _pendingMyItems.add(item);
    _recomputeMerged();
    notifyListeners();
  }

  void _removePending(String id) {
    final before = _pendingMyItems.length;
    _pendingMyItems.removeWhere((p) => p.id == id);
    if (_pendingMyItems.length == before) return; // already gone — no rebuild
    _recomputeMerged();
    notifyListeners();
  }

  /// Fire-and-forget post of an encrypted text status. Returns immediately
  /// after the optimistic state is registered. The real upload, key fan-out,
  /// and Firestore writes happen in the background; the stream replaces the
  /// optimistic item once Firestore echoes it back.
  void postEncryptedTextStatusInBackground({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required String text,
    required String backgroundColor,
    required List<String> viewerUids,
  }) {
    _trackIdentity(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
    );
    // Generate the real status-item id up front and use it for BOTH the
    // optimistic placeholder and the uploaded item. Sharing the id lets the
    // stream listener drop the placeholder the instant the server echoes the
    // real item (same id) — no transient "2 updates" flicker.
    final statusItemId = _statusService.newStatusItemId();
    _addPending(StatusItem(
      id: statusItemId,
      type: 'text',
      text: text,
      backgroundColor: backgroundColor,
      createdAt: DateTime.now(),
    ));
    // ignore: discarded_futures
    _statusService
        .uploadEncryptedTextStatus(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      text: text,
      backgroundColor: backgroundColor,
      viewerUids: viewerUids,
      itemId: statusItemId,
    )
        .then((_) {
      // Success is normally handled by the stream echo (same id); this is a
      // belt-and-suspenders cleanup and the sole path on failure.
      _removePending(statusItemId);
    }).catchError((e) {
      _error = 'Failed to post status: $e';
      _removePending(statusItemId);
    });
  }

  /// Same contract as [postEncryptedTextStatusInBackground] but for image.
  void postEncryptedImageStatusInBackground({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File imageFile,
    String? caption,
    required List<String> viewerUids,
  }) {
    _trackIdentity(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
    );
    final statusItemId = _statusService.newStatusItemId();
    _addPending(StatusItem(
      id: statusItemId,
      type: 'image',
      imageUrl: imageFile.path, // local path; tile can render a thumbnail
      caption: caption,
      createdAt: DateTime.now(),
    ));
    // ignore: discarded_futures
    _statusService
        .uploadEncryptedImageStatus(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      imageFile: imageFile,
      caption: caption,
      viewerUids: viewerUids,
      itemId: statusItemId,
    )
        .then((_) {
      _removePending(statusItemId);
    }).catchError((e) {
      _error = 'Failed to post status: $e';
      _removePending(statusItemId);
    });
  }

  /// Same contract as [postEncryptedTextStatusInBackground] but for video.
  void postEncryptedVideoStatusInBackground({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File videoFile,
    String? caption,
    required List<String> viewerUids,
  }) {
    _trackIdentity(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
    );
    final statusItemId = _statusService.newStatusItemId();
    _addPending(StatusItem(
      id: statusItemId,
      type: 'video',
      videoUrl: videoFile.path,
      caption: caption,
      createdAt: DateTime.now(),
    ));
    // ignore: discarded_futures
    _statusService
        .uploadEncryptedVideoStatus(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      videoFile: videoFile,
      caption: caption,
      viewerUids: viewerUids,
      itemId: statusItemId,
    )
        .then((_) {
      _removePending(statusItemId);
    }).catchError((e) {
      _error = 'Failed to post status: $e';
      _removePending(statusItemId);
    });
  }

  /// Legacy plaintext text status upload. Kept for callers that haven't
  /// migrated to the encrypted path.
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

  Future<void> uploadImageStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File imageFile,
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
        imageFile: imageFile,
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

  Future<void> uploadVideoStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File videoFile,
    String? caption,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _statusService.uploadVideoStatus(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        videoFile: videoFile,
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
      debugPrint('Error marking status as viewed: $e');
    }
  }

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
