import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/status_service.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusModel statusModel;
  final String currentUserId;
  final bool isMyStatus;

  const StatusViewerScreen({
    Key? key,
    required this.statusModel,
    required this.currentUserId,
    this.isMyStatus = false,
  }) : super(key: key);

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  final StatusService _statusService = StatusService();

  int _currentIndex = 0;
  late List<StatusItem> _activeItems;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _activeItems = widget.statusModel.activeStatusItems;
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..addStatusListener(_onProgressStatus);

    _startProgress();
    _markCurrentAsViewed();
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
      _startProgress();
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
      _startProgress();
    } else {
      _startProgress();
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
  }

  void _onTapUp(TapUpDetails details) {
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
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isPaused = false;
    _progressController.forward();
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'Viewed by ${currentItem.viewedBy.length}',
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
                          style: TextStyle(color: Colors.grey[600]),
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

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _pageController.dispose();
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
                if (item.type == 'text') {
                  return _buildTextStatus(item);
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

            // Bottom: caption for image statuses
            if (currentItem.type == 'image' &&
                currentItem.caption != null &&
                currentItem.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
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
                      Text(
                        '${currentItem.viewedBy.length} views',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
