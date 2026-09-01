import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/models/subscription_model.dart' show PlanLimits;
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Largest video status this device can actually post, in bytes.
///
/// Two independent ceilings sit above a status video and this is the lower of
/// them, deliberately:
///
///   * `EncryptedMediaService.encryptAndUpload` does `file.readAsBytes()`,
///     GCM-encrypts that into a second buffer and concatenates into a third, so
///     a video costs roughly 3× its size in heap before the upload even starts.
///     At 100 MB that is an out-of-memory kill on a mid-range phone, not a slow
///     upload.
///   * `storage.rules` rejects anything at or above 100 MB under `statuses/`.
///
/// 64 MB keeps the encrypt step inside ~200 MB of heap and leaves the Storage
/// rule as pure headroom, so an oversized pick always meets the message below
/// rather than a crash or a silent server rejection.
///
/// This is **not** a plan limit. Pro buys a longer video (90 s vs 30 s), never a
/// bigger file — see `PlanLimits.maxStatusVideoSec`. But nothing in this app
/// compresses video (`image_picker` hands back the raw capture), so a
/// high-bitrate 1080p 90 s recording can exceed this. That case is exactly what
/// the message exists to explain.
const int _maxStatusVideoBytes = 64 * 1024 * 1024;

String _formatMb(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';

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
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhoneNumber,
    this.preSelectedFile,
    this.isVideo = false,
  });

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Resolved through AppThemeColors rather than the raw AppColors
        // constants: those are the *light* palette, so the icons below used to
        // render light-theme accents on a dark sheet.
        final c = AppThemeColors.of(context);
        return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.camera_alt_rounded, color: c.primary),
                ),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.online.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: c.online),
                ),
                title: const Text('Gallery Photo',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Choose an image from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Colors.orange),
                ),
                title: const Text('Record Video',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Record a short video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.primaryLt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.video_library_rounded,
                      color: c.primary),
                ),
                title: const Text('Gallery Video',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Choose a video from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
        );
      },
    ).then((value) {
      // If nothing was selected, no file is loaded, and not currently picking, go back
      if (_selectedFile == null && !_isPicking && mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    _isPicking = true;
    // Read before the picker await — `use_build_context_synchronously`.
    final pro = context.read<SubscriptionProvider>().hasProMediaQuality;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        // These bounds are applied *before* `ImageCompressor.compressForStatus`
        // runs, so they are a hard ceiling on the Pro quality tier: at 1920px /
        // q80 a Pro upload would be re-encoded from an already-shrunk image and
        // never reach the 2560px it is entitled to. Pro therefore hands the
        // original through untouched (`null` = no picker resize or re-encode)
        // and lets the compressor make the single quality decision. Free keeps
        // 1920 / 80 exactly as before.
        maxWidth: pro ? null : 1920,
        maxHeight: pro ? null : 1920,
        imageQuality: pro ? null : 80,
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
    // Read before the picker await — `use_build_context_synchronously`.
    final sub = context.read<SubscriptionProvider>();
    final maxSec = sub.maxStatusVideoSec;
    final canUpsell = sub.isProFeatureVisible && !sub.isProUnlocked;
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: maxSec),
      );

      _isPicking = false;
      if (video != null) {
        // Checked here rather than at upload time so the answer arrives before
        // the caption is written, and so the rejection is a sentence about the
        // video instead of the "permission error" dialog a Storage rejection
        // would surface.
        final file = File(video.path);
        if (!await _isPostableVideo(file, maxSec, canUpsell: canUpsell)) {
          // Straight back to the source sheet: the pick failed, the screen has
          // not, and popping out would make choosing a shorter clip a restart.
          if (mounted) _showMediaSourcePicker();
          return;
        }
        _disposeVideoPlayer();
        setState(() {
          _selectedFile = file;
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

  /// True when [file] can actually be posted; otherwise explains why not and
  /// returns false.
  ///
  /// Video only. An oversized *image* is not a problem to report: the picker
  /// bound and `ImageCompressor.compressForStatus` re-encode it to 2560 px at
  /// q90 — a couple of megabytes — so rejecting a 40 MB photo that would have
  /// compressed fine would be a bug, not a guard.
  ///
  /// Size is checked before duration so a 389 MB pick is rejected on a `stat`
  /// rather than by handing it to a video decoder first.
  Future<bool> _isPostableVideo(
    File file,
    int maxSec, {
    required bool canUpsell,
  }) async {
    final bytes = await file.length();
    if (bytes > _maxStatusVideoBytes) {
      if (!mounted) return false;
      // Awaited: the caller reopens the source sheet the moment this returns,
      // and a sheet drawn over the dialog is how the message got buried the
      // first time round.
      await _showErrorDialog(
        'This video is ${_formatMb(bytes)}, and the most a status can carry is '
        '${_formatMb(_maxStatusVideoBytes)}.\n\n'
        'Videos are uploaded at the quality your camera recorded them, so a '
        'high-resolution clip gets large quickly. Try a shorter one, or drop '
        'your camera to a lower recording quality and film it again.',
        title: 'Video is too large',
      );
      return false;
    }

    final duration = await _probeDuration(file);
    // A 1 s grace: a camera capture bounded by `maxDuration` routinely comes
    // back a few frames over the limit it was given, and rejecting the app's
    // own recording would be absurd.
    if (duration != null && duration.inMilliseconds > (maxSec + 1) * 1000) {
      if (!mounted) return false;
      await _showErrorDialog(
        'This video is ${_formatDuration(duration)} long, and a status can be '
        'up to ${_formatDuration(Duration(seconds: maxSec))}.'
        '${canUpsell ? '\n\nGupShupGo Pro raises the limit to '
            '${_formatDuration(Duration(seconds: PlanLimits.maxStatusVideoSec(true)))}.' : ''}',
        title: 'Video is too long',
      );
      return false;
    }
    return true;
  }

  /// Reads a video's duration, or `null` if it cannot be determined.
  ///
  /// This check exists because `image_picker`'s `maxDuration` binds the *camera*
  /// only — Android passes it to the capture intent as `EXTRA_DURATION_LIMIT`
  /// and ignores it completely for a gallery pick. Without this, the advertised
  /// 30 s / 90 s cap was enforced against people who filmed inside the app and
  /// nobody else: picking an existing file let anyone post a ten-minute
  /// "status", which is also the one case the size guard above can miss, since a
  /// long low-bitrate clip fits comfortably under 64 MB.
  Future<Duration?> _probeDuration(File file) async {
    final probe = VideoPlayerController.file(file);
    try {
      await probe.initialize();
      final d = probe.value.duration;
      return d == Duration.zero ? null : d;
    } catch (_) {
      // Unreadable metadata lets the post through rather than blocking a valid
      // upload on a probe failure. The size guard and the Storage rules still
      // apply, so the failure mode is a too-long status, not an unbounded one.
      return null;
    } finally {
      await probe.dispose();
    }
  }

  Future<void> _uploadStatus() async {
    if (_selectedFile == null) return;

    // Read before the first await — `use_build_context_synchronously`.
    final sub = context.read<SubscriptionProvider>();
    final maxSec = sub.maxStatusVideoSec;
    final canUpsell = sub.isProFeatureVisible && !sub.isProUnlocked;

    // Verify the file actually exists on disk
    if (!await _selectedFile!.exists()) {
      if (mounted) {
        _showErrorDialog(
            'The selected file could not be found. Please try selecting it again.');
      }
      return;
    }

    // Second gate, for the `preSelectedFile` route that never passed through
    // `_pickVideo`. It is the last point where a rejection can still be a
    // sentence: the post below is fire-and-forget, so after it starts a Storage
    // rejection reaches the user only as a status that silently never appeared.
    if (_isVideo &&
        !await _isPostableVideo(_selectedFile!, maxSec,
            canUpsell: canUpsell)) {
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

      // E2EE: encrypt the file and wrap the content key for every viewer.
      final viewers =
          await _statusService.defaultViewerUids(widget.userId);
      if (viewers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'No contacts yet — start a chat before posting a status.')),
          );
        }
        return;
      }
      // Fire-and-forget: provider inserts an optimistic StatusItem
      // immediately, then runs compression + AES-GCM encrypt + Storage
      // upload + Signal key fan-out + Firestore writes in the background.
      // The screen closes in the same frame as the tap.
      if (!mounted) return;
      final provider = context.read<StatusProvider>();
      if (_isVideo) {
        provider.postEncryptedVideoStatusInBackground(
          userId: widget.userId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          userPhoneNumber: widget.userPhoneNumber,
          videoFile: _selectedFile!,
          caption: caption.isNotEmpty ? caption : null,
          viewerUids: viewers,
        );
      } else {
        provider.postEncryptedImageStatusInBackground(
          userId: widget.userId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          userPhoneNumber: widget.userPhoneNumber,
          imageFile: _selectedFile!,
          caption: caption.isNotEmpty ? caption : null,
          viewerUids: viewers,
        );
      }

      debugPrint('[Status] Upload kicked off in background');
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

  /// Completes when the dialog is dismissed, so a caller can put something else
  /// on screen afterwards without racing it.
  Future<void> _showErrorDialog(String message,
      {String title = 'Upload Error'}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
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
      return const Scaffold(
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
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Crop / edit icons (decorative for now)
                  IconButton(
                    icon: const Icon(Icons.crop_rotate, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_fields, color: Colors.white),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // E2EE assurance line above the caption row.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'End-to-end encrypted',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Re-pick media button
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                        onPressed: _isUploading ? null : _showMediaSourcePicker,
                      ),
                  // Caption input — no box, just plain text on gradient
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        filled: false,
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isUploading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _isUploading ? null : _uploadStatus,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        // Pinned to the dark palette rather than resolved from
                        // the app theme: this bar sits on a black scrim over the
                        // picked photo, so the surface is dark whatever the app
                        // setting is, and the dark palette's lighter accent is
                        // the one that reads against it.
                        color:
                            AppThemeColors.forBrightness(Brightness.dark).primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                    ),
                  ),
                ],
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
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading ${_isVideo ? "video" : "image"}...',
                        style: const TextStyle(
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
      return const Center(
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
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_videoController!.value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
