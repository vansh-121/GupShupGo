// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:video_chat_app/provider/call_state_provider.dart';
// import 'package:video_chat_app/screens/call_screen.dart';
// import 'package:video_chat_app/services/fcm_service.dart';
// import 'package:audioplayers/audioplayers.dart';

// class IncomingCallScreen extends StatefulWidget {
//   final String callerId;
//   final String channelId;

//   const IncomingCallScreen({
//     required this.callerId,
//     required this.channelId,
//   });

//   @override
//   _IncomingCallScreenState createState() => _IncomingCallScreenState();
// }

// class _IncomingCallScreenState extends State<IncomingCallScreen> {
//   late AudioPlayer _audioPlayer;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _playRingtone();
//   }

//   Future<void> _playRingtone() async {
//     try {
//       // Play the ringtone from the assets folder and loop it
//       await _audioPlayer.setSource(AssetSource('ringtone.mp3'));
//       await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the ringtone
//       await _audioPlayer.resume();
//     } catch (e) {
//       print('Error playing ringtone: $e');
//     }
//   }

//   Future<void> _stopRingtone() async {
//     try {
//       await _audioPlayer.stop();
//       await _audioPlayer.release();
//     } catch (e) {
//       print('Error stopping ringtone: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _stopRingtone();
//     _audioPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _acceptCall(BuildContext context) async {
//     await _stopRingtone(); // Stop the ringtone before proceeding
//     final callState = Provider.of<CallStateNotifier>(context, listen: false);
//     callState.updateState(CallState.Connected);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             CallScreen(channelId: widget.channelId, isCaller: false),
//       ),
//     );
//   }

//   Future<void> _declineCall(BuildContext context) async {
//     await _stopRingtone(); // Stop the ringtone before proceeding
//     final callState = Provider.of<CallStateNotifier>(context, listen: false);
//     callState.updateState(CallState.Ended);

//     // Notify the caller that the call was declined
//     await FCMService()
//         .sendCallEndedNotification(widget.callerId, widget.channelId);

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black87,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundImage: NetworkImage(
//                 'https://ui-avatars.com/api/?name=${widget.callerId}&background=4CAF50&color=fff&size=128',
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Incoming Call',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               widget.callerId,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 30,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 100),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Decline button
//                 GestureDetector(
//                   onTap: () => _declineCall(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(15),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.call_end,
//                       color: Colors.white,
//                       size: 40,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 50),
//                 // Accept button
//                 GestureDetector(
//                   onTap: () => _acceptCall(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(15),
//                     decoration: const BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.call,
//                       color: Colors.white,
//                       size: 40,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
