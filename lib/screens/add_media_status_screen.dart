import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/services/status_service.dart';

/// Screen for capturing / picking image or video and posting as a status.
/// Launched from the camera FAB or from the status type selector.
class AddMediaStatusScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? userPhoneNumber;
  final File? preSelectedFile;
  final bool isVideo;

  const AddMediaStatusScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhoneNumber,
    this.preSelectedFile,
    this.isVideo = false,
  }) : super(key: key);

  @override
  State<AddMediaStatusScreen> createState() => _AddMediaStatusScreenState();
}

class _AddMediaStatusScreenState extends State<AddMediaStatusScreen> {
  final TextEditingController _captionController = TextEditingController();
  final StatusService _statusService = StatusService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedFile;
  bool _isVideo = false;
  bool _isUploading = false;
  bool _isPicking = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedFile != null) {
      _selectedFile = widget.preSelectedFile;
      _isVideo = widget.isVideo;
      if (_isVideo) {
        _initVideoPlayer();
      }
    } else {
      // Show picker immediately if no file pre-selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMediaSourcePicker();
      });
    }
  }

  void _initVideoPlayer() {
    if (_selectedFile == null) return;
    _videoController = VideoPlayerController.file(_selectedFile!)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      });
  }

  void _disposeVideoPlayer() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  void _showMediaSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Add Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.green),
                ),
                title: Text('Gallery Photo',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Choose an image from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.videocam, color: Colors.orange),
                ),
                title: Text('Record Video',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Record a short video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.video_library, color: Colors.purple),
                ),
                title: Text('Gallery Video',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Choose a video from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    ).then((value) {
      // If nothing was selected, no file is loaded, and not currently picking, go back
      if (_selectedFile == null && !_isPicking && mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    _isPicking = true;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      _isPicking = false;
      if (image != null) {
        _disposeVideoPlayer();
        setState(() {
          _selectedFile = File(image.path);
          _isVideo = false;
        });
      } else if (_selectedFile == null && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _isPicking = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
        if (_selectedFile == null) Navigator.pop(context);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    _isPicking = true;
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: 30),
      );

      _isPicking = false;
      if (video != null) {
        _disposeVideoPlayer();
        setState(() {
          _selectedFile = File(video.path);
          _isVideo = true;
        });
        _initVideoPlayer();
      } else if (_selectedFile == null && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _isPicking = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
        if (_selectedFile == null) Navigator.pop(context);
      }
    }
  }

  Future<void> _uploadStatus() async {
    if (_selectedFile == null) return;

    // Verify the file actually exists on disk
    if (!await _selectedFile!.exists()) {
      if (mounted) {
        _showErrorDialog(
            'The selected file could not be found. Please try selecting it again.');
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final caption = _captionController.text.trim();
      debugPrint('[Status] Starting ${_isVideo ? "video" : "image"} upload...');
      debugPrint('[Status] File path: ${_selectedFile!.path}');
      debugPrint('[Status] File size: ${await _selectedFile!.length()} bytes');

      if (_isVideo) {
        await _statusService.uploadVideoStatus(
          userId: widget.userId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          userPhoneNumber: widget.userPhoneNumber,
          videoFile: _selectedFile!,
          caption: caption.isNotEmpty ? caption : null,
        );
      } else {
        await _statusService.uploadImageStatus(
          userId: widget.userId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          userPhoneNumber: widget.userPhoneNumber,
          imageFile: _selectedFile!,
          caption: caption.isNotEmpty ? caption : null,
        );
      }

      debugPrint('[Status] Upload successful!');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Status] Upload failed: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showErrorDialog(
          e.toString().contains('unauthorized') ||
                  e.toString().contains('permission')
              ? 'Upload failed due to permission error.\n\nPlease make sure Firebase Storage security rules allow authenticated uploads.\n\nError: $e'
              : 'Failed to upload status.\n\nError: $e',
        );
      }
    } finally {
      if (mounted && _isUploading) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Upload Error'),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _disposeVideoPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media preview
          Positioned.fill(
            child: _isVideo ? _buildVideoPreview() : _buildImagePreview(),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
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
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Spacer(),
                  // Crop / edit icons (decorative for now)
                  IconButton(
                    icon: Icon(Icons.crop_rotate, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.text_fields, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with caption + send
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 12,
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
              child: Row(
                children: [
                  // Re-pick media button
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate, color: Colors.white),
                    onPressed: _isUploading ? null : _showMediaSourcePicker,
                  ),
                  // Caption input
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _captionController,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isUploading,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _isUploading ? null : _uploadStatus,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upload progress overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Uploading ${_isVideo ? "video" : "image"}...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      _selectedFile!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            // Play/pause overlay
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: AnimatedOpacity(
                opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                duration: Duration(milliseconds: 200),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Video duration badge
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_videoController!.value.duration),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
