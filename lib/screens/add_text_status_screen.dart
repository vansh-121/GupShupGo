import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/status_service.dart';

class AddTextStatusScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? userPhoneNumber;

  const AddTextStatusScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhoneNumber,
  }) : super(key: key);

  @override
  State<AddTextStatusScreen> createState() => _AddTextStatusScreenState();
}

class _AddTextStatusScreenState extends State<AddTextStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final StatusService _statusService = StatusService();
  bool _isUploading = false;

  int _currentColorIndex = 0;

  final List<String> _backgroundColors = [
    '#6C5CE7', // Brand primary (default)
    '#5246BE', // Brand dark
    '#9B8FF0', // Brand light
    '#10B981', // Emerald green
    '#25D366', // WhatsApp green
    '#1E88E5', // Blue
    '#E53935', // Red
    '#FB8C00', // Orange
    '#D81B60', // Pink
    '#3949AB', // Indigo
    '#00897B', // Teal
    '#43A047', // Green
    '#F4511E', // Deep orange
    '#1565C0', // Dark blue
    '#6D4C41', // Brown
    '#546E7A', // Blue grey
  ];

  void _cycleColor() {
    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % _backgroundColors.length;
    });
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _uploadStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // E2EE: encrypt the status under a per-item key and wrap the key for
      // every viewer's device. If the user has zero contacts, we have no one
      // to share it with — surface that explicitly rather than silently
      // dropping the post.
      final viewers = await _statusService.defaultViewerUids(widget.userId);
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
      await _statusService.uploadEncryptedTextStatus(
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
        userPhoneNumber: widget.userPhoneNumber,
        text: text,
        backgroundColor: _backgroundColors[_currentColorIndex],
        viewerUids: viewers,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(_backgroundColors[_currentColorIndex]);
    final isDark = bgColor.computeLuminance() < 0.4;
    final onBg = isDark ? Colors.white : Colors.black87;
    final onBgMuted = isDark ? Colors.white60 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: onBg),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined, color: onBg),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.text_fields_rounded, color: onBg),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.palette_rounded, color: onBg),
            onPressed: _cycleColor,
            tooltip: 'Change background color',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _textController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: onBg,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: 'Type a status...',
              hintStyle: GoogleFonts.poppins(
                color: onBgMuted,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: _isUploading ? null : _uploadStatus,
        child: _isUploading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: bgColor,
                ),
              )
            : Icon(Icons.send_rounded, color: bgColor),
      ),
    );
  }
}
