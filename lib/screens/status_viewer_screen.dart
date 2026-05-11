import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/status_service.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusModel statusModel;
  final String currentUserId;
  final String? currentUserName;
  final bool isMyStatus;
  final String? initialStatusItemId;

  const StatusViewerScreen({
    Key? key,
    required this.statusModel,
    required this.currentUserId,
    this.currentUserName,
    this.isMyStatus = false,
    this.initialStatusItemId,
  }) : super(key: key);

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

  Stream<int> _watchCurrentViewCount() {
    return _statusService.watchStatusViewCount(
      statusOwnerId: widget.statusModel.userId,
      statusItemId: _activeItems[_currentIndex].id,
    );
  }

  @override
  void initState() {
    super.initState();
    _activeItems = widget.statusModel.activeStatusItems;
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
      duration: Duration(seconds: 5),
    )..addStatusListener(_onProgressStatus);

    _decryptAllEncrypted().then((_) {
      if (mounted) setState(() {});
    });
    _loadCurrentStatus();
    _markCurrentAsViewed();
  }

  /// Eagerly decrypt every encrypted item so swipes are instant. Each item
  /// goes from {url, iv, hash} on Firestore → AES-GCM ciphertext from Storage
  /// → plaintext bytes here. Failures (no key envelope, integrity mismatch)
  /// leave the slot empty; the builder shows a "⚠ couldn't decrypt" panel.
  Future<void> _decryptAllEncrypted() async {
    for (final item in _activeItems) {
      if (!item.type.startsWith('encrypted')) continue;
      try {
        final result = await _statusService.decryptStatusItem(
          ownerUid: widget.statusModel.userId,
          item: item,
          selfUid: widget.currentUserId,
        );
        if (result == null) continue;
        if (item.type == 'encrypted') {
          final j = result['json'] as Map<String, dynamic>;
          _decrypted[item.id] = _DecryptedStatus.text(
            text: (j['text'] as String?) ?? '',
            backgroundColor:
                (j['backgroundColor'] as String?) ?? '#6C5CE7',
          );
        } else {
          // Write decrypted bytes to a temp file so VideoPlayer / Image.file
          // can consume them. systemTemp is wiped by the OS.
          final bytes = result['bytes'] as Uint8List;
          final isVideo = item.type == 'encrypted_video';
          final ext = isVideo ? 'mp4' : 'jpg';
          final file = await File(
                  '${Directory.systemTemp.path}/dec_${item.id}.$ext')
              .writeAsBytes(bytes, flush: true);
          _decrypted[item.id] = _DecryptedStatus.media(
            localFile: file,
            bytes: bytes,
            isVideo: isVideo,
          );
        }
      } catch (_) {
        // skip — UI will show the "couldn't decrypt" placeholder.
      }
    }
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
            _progressController.duration = Duration(seconds: 5);
            _startProgress();
          }
        });
    } else {
      // Text or image: 5 seconds
      _progressController.duration = Duration(seconds: 5);
      _startProgress();
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
        duration: Duration(milliseconds: 300),
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
        duration: Duration(milliseconds: 300),
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
      shape: RoundedRectangleBorder(
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
            return Container(
              padding: EdgeInsets.all(20),
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
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: cs.onSurfaceVariant),
                      SizedBox(width: 8),
                      Text(
                        'Viewed by ${snapshot.data?.length ?? 0}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.data?.isEmpty ?? true)
                    Padding(
                      padding: EdgeInsets.all(20),
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
                            backgroundImage: NetworkImage(
                              user.photoUrl ??
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
                            ),
                          ),
                          title: Text(user.name),
                        )),
                ],
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
        title: Text('Delete Status'),
        content: Text('Are you sure you want to delete this status?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _progressController.forward();
            },
            child: Text('Cancel'),
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
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
    final mediaUrl = currentItem.type == 'image'
        ? currentItem.imageUrl
        : currentItem.thumbnailUrl ?? currentItem.videoUrl;

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
        statusReplyType: currentItem.type,
        statusReplyText: currentItem.text,
        statusReplyMediaUrl: mediaUrl,
        statusReplyCaption: currentItem.caption,
        statusReplyBackgroundColor: currentItem.backgroundColor,
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
      return Scaffold(
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
              physics: NeverScrollableScrollPhysics(),
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
                            padding: EdgeInsets.symmetric(horizontal: 2),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                    SizedBox(height: 12),

                    // User info row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            widget.statusModel.userPhotoUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.statusModel.userName)}&background=4CAF50&color=fff&size=128',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isMyStatus
                                    ? 'My Status'
                                    : widget.statusModel.userName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(currentItem.createdAt),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isMyStatus) ...[
                          IconButton(
                            icon: Icon(Icons.visibility,
                                color: Colors.white, size: 22),
                            onPressed: _showViewers,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.white, size: 22),
                            onPressed: _showDeleteDialog,
                          ),
                        ],
                        IconButton(
                          icon:
                              Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom: caption for image/video statuses
            if (currentItem.type != 'text' &&
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
                    style: TextStyle(
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
                      Icon(Icons.keyboard_arrow_up, color: Colors.white),
                      SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: _watchCurrentViewCount(),
                        initialData: currentItem.viewedBy.length,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count view${count == 1 ? '' : 's'}',
                            style: TextStyle(
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
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: Colors.white70, size: 48),
              SizedBox(height: 12),
              Text(
                'Decrypting…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
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

  Widget _buildTextStatus(StatusItem item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _parseColor(item.backgroundColor),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        item.text ?? '',
        style: TextStyle(
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.contain,
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
                return Center(
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
          : Center(
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
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          : Center(
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
    Key? key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// Minimal video player for an encrypted status item. Takes a local file
/// (the decrypted plaintext written to systemTemp) and plays it once.
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
    return AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c));
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
