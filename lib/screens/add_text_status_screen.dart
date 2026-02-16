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
    '#075E54', // WhatsApp dark green
    '#128C7E', // WhatsApp teal
    '#25D366', // WhatsApp green
    '#1E88E5', // Blue
    '#E53935', // Red
    '#8E24AA', // Purple
    '#FB8C00', // Orange
    '#3949AB', // Indigo
    '#00897B', // Teal
    '#D81B60', // Pink
    '#5E35B1', // Deep purple
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
      await _statusService.uploadTextStatus(
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
        userPhoneNumber: widget.userPhoneNumber,
        text: text,
        backgroundColor: _backgroundColors[_currentColorIndex],
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.text_fields, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.palette, color: Colors.white),
            onPressed: _cycleColor,
            tooltip: 'Change background color',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _textController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Type a status',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _isUploading ? null : _uploadStatus,
        child: _isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: bgColor,
                ),
              )
            : Icon(Icons.send, color: bgColor),
      ),
    );
  }
}
