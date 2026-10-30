import 'package:flutter/material.dart';
import 'package:video_chat_app/services/native_call_service.dart';

class CallReadinessScreen extends StatefulWidget {
  const CallReadinessScreen({super.key});
  @override
  State<CallReadinessScreen> createState() => _CallReadinessScreenState();
}

class _CallReadinessScreenState extends State<CallReadinessScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final status = await NativeCallService.channel
          .invokeMapMethod<String, dynamic>('readiness');
      if (mounted)
        setState(() {
          _status = status;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not check call settings. Try again.');
    }
  }

  Future<void> _open(String page) async {
    final opened = await NativeCallService.channel
        .invokeMethod<bool>('openSettings', {'page': page});
    if (opened != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Open your phone settings to update this permission.')));
    }
  }

  Widget _check(String title, String detail, bool ready, String page) =>
      ListTile(
        leading: Icon(ready ? Icons.check_circle_outline : Icons.info_outline,
            color:
                ready ? Colors.green : Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(page),
      );
  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming call readiness')),
      body: _error != null
          ? Center(child: TextButton(onPressed: _load, child: Text(_error!)))
          : s == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Allow incoming calls to appear while your phone is locked or GupShupGo is in the background.')),
                      _check(
                          'Call notifications',
                          'Allow notifications, sound, and pop-up alerts.',
                          s['notifications'] == true &&
                              s['headsUp'] == true &&
                              s['ringtone'] == true,
                          'notifications'),
                      _check(
                          'Full-screen calls',
                          'Show incoming calls on the lock screen. Without access, Android uses a notification.',
                          s['fullScreen'] == true,
                          'fullScreen'),
                      _check(
                          'Battery and background activity',
                          'Allow background activity and choose unrestricted battery usage for GupShupGo.',
                          s['batteryUnrestricted'] == true &&
                              s['backgroundRestricted'] != true,
                          'battery'),
                      _check(
                          'Google Play services',
                          'Required for incoming call delivery on this Android device.',
                          s['playServices'] == true,
                          'app'),
                      if (s['xiaomi'] == true) ...[
                        ListTile(
                            leading:
                                const Icon(Icons.settings_suggest_outlined),
                            title:
                                const Text('Xiaomi / MIUI / HyperOS autostart'),
                            subtitle: const Text(
                                'Enable background autostart. Android cannot verify this setting automatically.'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open('autostart')),
                        ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text(
                                'Lock-screen and background pop-ups'),
                            subtitle: const Text(
                                'In Other permissions, allow Show on Lock screen and Display pop-up windows while running in the background. Set battery saver to No restrictions.'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open('app')),
                      ],
                      ListTile(
                          leading: Icon(s['registered'] == true
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined),
                          title: Text(s['registered'] == true
                              ? 'Device registered for calls'
                              : 'Device registration pending'),
                          subtitle: const Text(
                              'Registration refreshes automatically when a network is available.')),
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Do Not Disturb and silent mode can silence calls. After Force stop, reopen GupShupGo to receive calls again. Delivery also requires a working network; some phone battery managers may still delay it.')),
                    ]),
    );
  }
}
