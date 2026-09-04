// The "Report a problem" dialog, shared by Settings and the home overflow menu.
//
// Extracted rather than copied: it is a form plus a Firestore write plus two
// snackbars, and a second hand-maintained copy would drift the moment either
// call site changed. The user identity is optional on purpose — a report from
// someone whose profile has not loaded yet is still worth receiving, and
// silently doing nothing would be the worst possible response to a tap on
// "Report a problem".

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';

abstract final class ReportProblemDialog {
  /// Collects a subject and description and files them to `problem_reports`.
  ///
  /// Returns once the report has been submitted or the user backed out.
  static Future<void> show(BuildContext context, {UserModel? user}) async {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final c = AppThemeColors.of(dialogContext);

          InputDecoration field(String hint) => InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.primary),
                ),
              );

          return AlertDialog(
            title: const Text('Report a Problem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: field('Brief summary'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 5,
                    decoration: field('Describe the problem...'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (submitted != true || !context.mounted) return;

      final subject = subjectController.text.trim().isNotEmpty
          ? subjectController.text.trim()
          : 'Bug Report';
      final body = bodyController.text.trim().isNotEmpty
          ? bodyController.text.trim()
          : 'No details provided';

      // Read off the context before the write: everything after the await
      // happens at a point where this context may already be gone.
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final platform = Theme.of(context).platform.name;

      unawaited(showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ));

      try {
        await FirebaseFirestore.instance.collection('problem_reports').add({
          'userId': user?.id ?? '',
          'userName': user?.name ?? '',
          'userEmail': user?.email ?? '',
          'subject': subject,
          'body': body,
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
          'emailSent': false,
        });

        navigator.pop(); // dismiss loading
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Report submitted — thanks for your feedback!'),
          ),
        );
      } catch (e) {
        navigator.pop(); // dismiss loading
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      subjectController.dispose();
      bodyController.dispose();
    }
  }
}
