import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/utils/avatar_image.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusModel statusModel;
  final String currentUserId;
  final String? currentUserName;
  final bool isMyStatus;
  final String? initialStatusItemId;

  const StatusViewerScreen({
    super.key,
    required this.statusModel,
    required this.currentUserId,
    this.currentUserName,
    this.isMyStatus = false,
    this.initialStatusItemId,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  final StatusService _statusService = StatusService();
  final ChatService _chatService = ChatService();
  final TextEditingController _replyController = TextEditingController();

  int _currentIndex = 0;
  late List<StatusItem> _activeItems;
  bool _isPaused = false;
  bool _isSendingReply = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  /// Cache of decrypted bytes for encrypted status items, keyed by item id.
  /// We decrypt eagerly on screen open so swiping between items is instant.
  /// For text items we cache the parsed JSON; for media we cache file bytes
  /// and a temp-file path that VideoPlayer.file / Image.file can consume.
  final Map<String, _DecryptedStatus> _decrypted = {};

  /// Items whose decrypt attempts were exhausted (or that are permanently
  /// unrecoverable). We show a "tap to retry" affordance for these instead of
  /// spinning forever — WhatsApp does the same once it gives up on a status.
  final Set<String> _failedItems = {};

  /// Ids with a decrypt loop currently running, so navigating back and forth
  /// over a still-decrypting item doesn't stack duplicate loops on top of the
  /// in-flight one.
  final Set<String> _decrypting = {};

  Stream<int> _watchCurrentViewCount() {
    return _statusService.watchStatusViewCount(
      statusOwnerId: widget.statusModel.userId,
      statusItemId: _activeItems[_currentIndex].id,
    );
  }

  @override
  void initState() {
    super.initState();
    // Filter out items that can't be decrypted on this install — AES key
    // was never vaulted (status never opened before reinstall). Showing a
    // spinner for them forever is worse than silently omitting, which is
    // exactly what WhatsApp does.
    //
    // But never collapse to an empty viewer when the status genuinely has
    // active items: a transient over-blacklist (envelope still propagating
    // for a freshly-posted status) would otherwise dead-end on the black
    // "No active status" screen with no retry. In that case we keep the raw
    // active items and let [_decryptOne]'s retry loop recover them.
    final active = widget.statusModel.activeStatusItems;
    final recoverable = active
        .where((item) => !StatusService.isUnrecoverable(item.id))
        .toList();
    _activeItems = recoverable.isNotEmpty ? recoverable : active;
    if (widget.initialStatusItemId != null) {
      final initialIndex = _activeItems.indexWhere(
        (item) => item.id == widget.initialStatusItemId,
      );
      if (initialIndex >= 0) {
        _currentIndex = initialIndex;
      }
    }
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onProgressStatus);

    // Hydrate from the process-wide cache synchronously so the first
    // frame already renders the plaintext when the provider pre-decrypted
    // ahead of us. This is the "no spinner" path.
    for (final item in _activeItems) {
      if (!item.type.startsWith('encrypted')) continue;
      final cached = StatusService.cachedPlaintext(item.id);
      if (cached == null) continue;
      _decrypted[item.id] = cached.text != null
          ? _DecryptedStatus.text(
              text: cached.text ?? '',
              backgroundColor: cached.backgroundColor ?? '#6C5CE7',
            )
          : _DecryptedStatus.media(
              localFile: cached.localFile!,
              bytes: cached.bytes!,
              isVideo: cached.isVideo,
            );
    }

    _decryptAllEncrypted();
    _loadCurrentStatus();
    _markCurrentAsViewed();
  }

  /// Decrypt the currently-visible item first so the user stops staring at
  /// the loader while later items round-trip. The remaining items run in
  /// parallel and each one rebuilds the UI as soon as it lands.
  Future<void> _decryptAllEncrypted() async {
    final encrypted = _activeItems
        .where((i) => i.type.startsWith('encrypted'))
        .toList();
    if (encrypted.isEmpty) return;

    final current = _activeItems[_currentIndex];
    if (current.type.startsWith('encrypted')) {
      await _decryptOne(current, patient: true);
    }

    await Future.wait(encrypted
        .where((i) => i.id != current.id)
        .map((item) => _decryptOne(item)));
  }

  /// Decrypts one encrypted item into [_decrypted], retrying across the brief
  /// propagation window for a freshly-posted status whose wrappedKey envelope /
  /// first-time Signal session hasn't reached this device yet.
  ///
  /// Each attempt goes through [StatusService.ensureDecrypted], which prefers
  /// the persistent disk cache and dedupes against the background pre-decrypt —
  /// so if the stream-driven pre-decrypt fills the cache while we wait, the very
  /// next cheap check picks it up (this is what turns a stuck spinner into an
  /// instant render the moment the key lands).
  ///
  /// [patient] is set for the item the user is actually looking at: it waits far
  /// longer (covering a cold open where the status key-unwrap queues behind a
  /// chat backlog on the shared Signal session) before surfacing a retry
  /// affordance. Prefetch of off-screen items gives up quickly and silently.
  Future<void> _decryptOne(StatusItem item, {bool patient = false}) async {
    if (_decrypted.containsKey(item.id)) return;
    if (_decrypting.contains(item.id)) return; // a loop is already on it
    _decrypting.add(item.id);
    try {
      final maxAttempts = patient ? 40 : 6;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        await _statusService.ensureDecrypted(
          ownerUid: widget.statusModel.userId,
          item: item,
          selfUid: widget.currentUserId,
        );
        final cached = StatusService.cachedPlaintext(item.id);
        if (cached != null) {
          _decrypted[item.id] = cached.text != null
              ? _DecryptedStatus.text(
                  text: cached.text ?? '',
                  backgroundColor: cached.backgroundColor ?? '#6C5CE7',
                )
              : _DecryptedStatus.media(
                  localFile: cached.localFile!,
                  bytes: cached.bytes!,
                  isVideo: cached.isVideo,
                );
          _failedItems.remove(item.id);
          if (mounted) {
            setState(() {});
            _onItemDecrypted(item.id);
          }
          return;
        }
        // Permanently undecryptable (genuine reinstall ghost) — stop early and
        // surface the retry affordance rather than spinning out the full window.
        if (StatusService.isUnrecoverable(item.id)) break;
        if (!mounted) return;
        final backoffMs = (500 * (attempt + 1)).clamp(500, 1500).toInt();
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
      // Exhausted (or blacklisted) without a plaintext: show "tap to retry"
      // instead of an eternal loader.
      if (mounted && !_decrypted.containsKey(item.id)) {
        setState(() => _failedItems.add(item.id));
      }
    } finally {
      _decrypting.remove(item.id);
    }
  }

  /// Called when an item finishes decrypting. If it's the one on screen, the
  /// progress bar has been held at zero waiting for it — start the countdown
  /// now so the timer measures time-visible, not time-spent-decrypting (this is
  /// the WhatsApp behaviour: the ring fills only once the content is shown).
  void _onItemDecrypted(String itemId) {
    if (_activeItems.isEmpty) return;
    if (_activeItems[_currentIndex].id != itemId) return;
    if (_isPaused) return;
    _progressController.duration = const Duration(seconds: 5);
    _startProgress();
  }

  /// User tapped "retry" on an item we'd given up on.
  void _retryDecrypt(StatusItem item) {
    // The parent tap handler fires onTapDown (pausing) before this inner tap
    // wins the gesture arena, and its onTapUp may not fire — clear the pause
    // here so _onItemDecrypted can start the bar once the retry succeeds.
    _isPaused = false;
    setState(() => _failedItems.remove(item.id));
    // ignore: discarded_futures
    _decryptOne(item, patient: true);
  }

  /// Whether the item currently on screen is ready to display (and therefore
  /// whether the progress timer may run). Plain items are always ready; an
  /// encrypted item is ready only once its plaintext is decrypted.
  bool _isCurrentReady() {
    if (_activeItems.isEmpty) return false;
    final item = _activeItems[_currentIndex];
    if (!item.type.startsWith('encrypted')) return true;
    return _decrypted.containsKey(item.id);
  }

  /// Initialize the current status - set appropriate duration, load video if needed.
  void _loadCurrentStatus() {
    if (_activeItems.isEmpty) return;
    final item = _activeItems[_currentIndex];

    _disposeVideoController();

    if (item.type == 'video' && item.videoUrl != null) {
      // For videos, wait until initialized to set duration
      _isVideoInitialized = false;
      _progressController.stop();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(item.videoUrl!),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            // Set progress duration to video duration
            final videoDuration = _videoController!.value.duration;
            _progressController.duration = videoDuration;
            _videoController!.play();
            _progressController.reset();
            _progressController.forward();
          }
        }).catchError((e) {
          print('Error initializing video: $e');
          if (mounted) {
            // Fallback: use 5s timer for broken videos
            _progressController.duration = const Duration(seconds: 5);
            _startProgress();
          }
        });
    } else {
      // Text / image / encrypted. Give it the 5s duration, but only START the
      // countdown once the content is actually ready to show. For an encrypted
      // item that hasn't decrypted yet we hold the bar at zero (showing the
      // loader) and make sure a patient decrypt loop is running; _onItemDecrypted
      // starts the timer the instant the plaintext lands.
      _progressController.duration = const Duration(seconds: 5);
      if (_isCurrentReady()) {
        _startProgress();
      } else {
        _progressController.stop();
        _progressController.reset();
        if (item.type.startsWith('encrypted') &&
            !_failedItems.contains(item.id) &&
            !_decrypting.contains(item.id)) {
          // ignore: discarded_futures
          _decryptOne(item, patient: true);
        }
      }
    }
  }

  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStatus();
    }
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _nextStatus() {
    if (_currentIndex < _activeItems.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStatus();
      _markCurrentAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStatus();
    } else {
      _loadCurrentStatus();
    }
  }

  void _markCurrentAsViewed() {
    if (!widget.isMyStatus && _currentIndex < _activeItems.length) {
      _statusService.markStatusAsViewed(
        statusOwnerId: widget.statusModel.userId,
        statusItemId: _activeItems[_currentIndex].id,
        viewerId: widget.currentUserId,
      );
    }
  }

  void _onTapDown(TapDownDetails details) {
    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
  }

  void _onTapUp(TapUpDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (!widget.isMyStatus && details.globalPosition.dy > screenHeight - 96) {
      return;
    }

    _isPaused = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth / 3) {
      _previousStatus();
    } else {
      _nextStatus();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isPaused = false;
    _progressController.forward();
    _videoController?.play();
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showViewers() {
    if (!widget.isMyStatus) return;

    final currentItem = _activeItems[_currentIndex];
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return FutureBuilder<List<UserModel>>(
          future: _statusService.getStatusViewers(
            statusOwnerId: widget.statusModel.userId,
            statusItemId: currentItem.id,
          ),
          builder: (context, snapshot) {
        return SafeArea(
          child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Viewed by ${snapshot.data?.length ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.data?.isEmpty ?? true)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No views yet',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...snapshot.data!.map((user) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarImage(
                              user.photoUrl ??
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
                              radius: 20,
                            ),
                          ),
                          title: Text(user.name),
                        )),
                ],
              ),
          ),
        );
          },
        );
      },
    ).whenComplete(() {
      if (!_isPaused) _progressController.forward();
    });
  }

  void _showDeleteDialog() {
    if (!widget.isMyStatus) return;

    _progressController.stop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _progressController.forward();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _statusService.deleteStatusItem(
                userId: widget.statusModel.userId,
                statusItemId: _activeItems[_currentIndex].id,
              );
              if (_activeItems.length <= 1) {
                Navigator.pop(context);
              } else {
                setState(() {
                  _activeItems.removeAt(_currentIndex);
                  if (_currentIndex >= _activeItems.length) {
                    _currentIndex = _activeItems.length - 1;
                  }
                });
                _startProgress();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendStatusReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty ||
        _isSendingReply ||
        widget.isMyStatus ||
        _activeItems.isEmpty) {
      return;
    }

    setState(() {
      _isSendingReply = true;
    });
    _progressController.stop();
    _videoController?.pause();

    final currentItem = _activeItems[_currentIndex];

    // For encrypted statuses the on-Firestore fields are opaque metadata
    // (caption holds a JSON blob with iv/hash, type is "encrypted*", text is
    // null). Sending those verbatim is what produced the "{enc:true,iv:…}"
    // reply preview. Project the *decrypted* fields into the reply
    // payload so the chat preview matches what the user actually saw.
    String replyType = currentItem.type;
    String? replyText = currentItem.text;
    String? replyCaption = currentItem.caption;
    String? replyBg = currentItem.backgroundColor;
    String? mediaUrl;

    if (currentItem.type.startsWith('encrypted')) {
      final cached = StatusService.cachedPlaintext(currentItem.id);
      String? embeddedCaption;
      try {
        final meta = jsonDecode(currentItem.caption ?? '{}')
            as Map<String, dynamic>;
        embeddedCaption = meta['caption'] as String?;
      } catch (_) {}

      if (currentItem.type == 'encrypted') {
        replyType = 'text';
        replyText = cached?.text ?? '';
        replyBg = cached?.backgroundColor ?? '#6C5CE7';
        replyCaption = null;
      } else {
        replyType =
            currentItem.type == 'encrypted_video' ? 'video' : 'image';
        replyText = null;
        replyBg = null;
        replyCaption = embeddedCaption;
      }
      // Never expose the ciphertext blob URL — the receiver couldn't
      // decrypt it anyway (no wrapped key addressed to them for the
      // reply context) and the placeholder thumbnail handles this case.
      mediaUrl = null;
    } else {
      mediaUrl = currentItem.type == 'image'
          ? currentItem.imageUrl
          : currentItem.thumbnailUrl ?? currentItem.videoUrl;
    }

    try {
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.statusModel.userId,
        text: reply,
        senderName: widget.currentUserName,
        statusReplyOwnerId: widget.statusModel.userId,
        statusReplyItemId: currentItem.id,
        statusReplyOwnerName: widget.statusModel.userName,
        statusReplyOwnerPhotoUrl: widget.statusModel.userPhotoUrl,
        statusReplyType: replyType,
        statusReplyText: replyText,
        statusReplyMediaUrl: mediaUrl,
        statusReplyCaption: replyCaption,
        statusReplyBackgroundColor: replyBg,
      );
      _replyController.clear();
      FocusScope.of(context).unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReply = false;
        });
        _isPaused = false;
        _progressController.forward();
        _videoController?.play();
      }
    }
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _pageController.dispose();
    _disposeVideoController();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No active status',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentItem = _activeItems[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeItems.length,
              itemBuilder: (context, index) {
                final item = _activeItems[index];
                if (item.type.startsWith('encrypted')) {
                  return _buildEncryptedStatus(item);
                }
                if (item.type == 'text') {
                  return _buildTextStatus(item);
                } else if (item.type == 'video') {
                  return _buildVideoStatus(item);
                } else {
                  return _buildImageStatus(item);
                }
              },
            ),

            // Top overlay: progress bars + user info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Progress bars
                    Row(
                      children: List.generate(
                        _activeItems.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: StatusAnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double progress;
                                if (index < _currentIndex) {
                                  progress = 1.0;
                                } else if (index == _currentIndex) {
                                  progress = _progressController.value;
                                } else {
                                  progress = 0.0;
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    minHeight: 2.5,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User info row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: avatarImage(
                            widget.statusModel.userPhotoUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.statusModel.userName)}&background=4CAF50&color=fff&size=128',
                            radius: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isMyStatus
                                    ? 'My Moments'
                                    : widget.statusModel.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatTimeAgo(currentItem.createdAt),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  // E2EE indicator inline next to the
                                  // timestamp, so viewers see at a glance
                                  // that the status is encrypted end-to-end.
                                  if (currentItem.type
                                      .startsWith('encrypted')) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.lock_outline_rounded,
                                        color: Colors.white70, size: 11),
                                    const SizedBox(width: 3),
                                    const Flexible(
                                      child: Text(
                                        'End-to-end encrypted',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.isMyStatus) ...[
                          IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.white, size: 22),
                            onPressed: _showViewers,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.white, size: 22),
                            onPressed: _showDeleteDialog,
                          ),
                        ],
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom: caption for image/video statuses. Encrypted statuses
            // store metadata JSON in the `caption` field — never render
            // that as user-visible text. (The plaintext caption from inside
            // the encrypted payload is extracted on decrypt and would need
            // a separate render path; out of scope here.)
            if (currentItem.type != 'text' &&
                !currentItem.type.startsWith('encrypted') &&
                currentItem.caption != null &&
                currentItem.caption!.isNotEmpty)
              Positioned(
                bottom: widget.isMyStatus ? 0 : 70,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    currentItem.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Bottom: viewers count for own status
            if (widget.isMyStatus)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showViewers,
                  child: Column(
                    children: [
                      const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      const SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: _watchCurrentViewCount(),
                        initialData: currentItem.viewedBy.length,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count view${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if (!widget.isMyStatus)
              Positioned(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                child: _buildReplyBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: TextField(
                controller: _replyController,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                onTap: () {
                  _isPaused = true;
                  _progressController.stop();
                  _videoController?.pause();
                },
                onSubmitted: (_) => _sendStatusReply(),
                decoration: InputDecoration(
                  hintText: 'Reply...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSendingReply ? null : _sendStatusReply,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSendingReply
                    ? Colors.white.withOpacity(0.35)
                    : Colors.white,
                shape: BoxShape.circle,
              ),
              child: _isSendingReply
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders an encrypted status item, either from the eagerly-decrypted
  /// cache or as a "couldn't decrypt" placeholder when this device wasn't
  /// authorised or the envelope hasn't arrived yet.
  Widget _buildEncryptedStatus(StatusItem item) {
    final dec = _decrypted[item.id];
    if (dec == null) {
      return _failedItems.contains(item.id)
          ? _buildDecryptFailed(item)
          : _buildDecryptLoading();
    }
    if (dec.text != null) {
      // Render as a text status using the decrypted text + bg colour.
      return _buildTextStatus(StatusItem(
        id: item.id,
        type: 'text',
        text: dec.text,
        backgroundColor: dec.backgroundColor ?? '#6C5CE7',
        createdAt: item.createdAt,
        viewedBy: item.viewedBy,
      ));
    }
    if (dec.isVideo && dec.localFile != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: _EncryptedVideoView(file: dec.localFile!),
      );
    }
    if (dec.bytes != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Image.memory(dec.bytes!, fit: BoxFit.contain),
      );
    }
    return const SizedBox.shrink();
  }

  /// WhatsApp-style loader shown while an encrypted item is being decrypted.
  /// A single calm spinner centred on black — the held progress bar at the top
  /// already signals "not started yet", so this stays deliberately minimal.
  Widget _buildDecryptLoading() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  /// Shown when decryption was exhausted/blacklisted: a quiet lock glyph with a
  /// tap-to-retry, instead of a spinner that never resolves.
  Widget _buildDecryptFailed(StatusItem item) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: GestureDetector(
          // Swallow the tap so it retries instead of advancing the story.
          onTap: () => _retryDecrypt(item),
          behavior: HitTestBehavior.opaque,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_reset_rounded, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text(
                "Couldn't load this update",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextStatus(StatusItem item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _parseColor(item.backgroundColor),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        item.text ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildImageStatus(StatusItem item) {
    // Status media is an unmodified camera frame — commonly 3000×4000, which
    // decodes to ~48 MB and is the kind of manual full-size decode Play
    // Console's bitmap check flags. fit: BoxFit.contain never paints wider
    // than the screen, so capping the decode at the physical screen width
    // costs nothing visually and bounds this at ~10 MB on a 1080p device.
    final decodeWidth = (MediaQuery.of(context).size.width *
            MediaQuery.of(context).devicePixelRatio)
        .round();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.contain,
              cacheWidth: decodeWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 64),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              },
            )
          : const Center(
              child: Icon(Icons.image, color: Colors.white54, size: 64),
            ),
    );
  }

  Widget _buildVideoStatus(StatusItem item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: _videoController != null && _isVideoInitialized
          ? Center(
              child: AspectAwareVideoPlayer(
                controller: _videoController!,
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
}

/// StatusAnimatedBuilder is a convenience wrapper for AnimatedWidget using a builder.
class StatusAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const StatusAnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// Minimal video player for an encrypted status item. Takes a local file
/// (decrypted plaintext written to the persistent media cache dir) and
/// plays it once.
class _EncryptedVideoView extends StatefulWidget {
  const _EncryptedVideoView({required this.file});
  final File file;
  @override
  State<_EncryptedVideoView> createState() => _EncryptedVideoViewState();
}

class _EncryptedVideoViewState extends State<_EncryptedVideoView> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.file);
    _ctrl = c;
    c.initialize().then((_) {
      if (mounted) {
        setState(() {});
        c
          ..setLooping(false)
          ..play();
      }
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white70);
    }
    return AspectAwareVideoPlayer(controller: c, measureFilePath: widget.file.path);
  }
}

/// Plaintext form of an encrypted StatusItem after the per-status content
/// key has been unwrapped and the blob decrypted. Either `text` or
/// `localFile` is populated, never both.
class _DecryptedStatus {
  _DecryptedStatus.text({required this.text, required this.backgroundColor})
      : localFile = null,
        bytes = null,
        isVideo = false;
  _DecryptedStatus.media({
    required File this.localFile,
    required Uint8List this.bytes,
    required this.isVideo,
  })  : text = null,
        backgroundColor = null;

  final String? text;
  final String? backgroundColor;
  final File? localFile;
  final Uint8List? bytes;
  final bool isVideo;
}
