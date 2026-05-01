// In-Class Activity #14 — Firebase Cloud Messaging in Flutter
// CSC 4360 — Mobile App Development — Spring 2026
// Luci Liu

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FcmDemoApp());
}

class FcmDemoApp extends StatelessWidget {
  const FcmDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const NotificationScreen(),
    );
  }
}

// ── Notification log entry ────────────────────────────────────────────────

class NotificationEntry {
  final String title;
  final String body;
  final String handler; // 'Foreground', 'Background tap', 'Terminated tap'
  final String? dataPayload;
  final DateTime receivedAt;

  NotificationEntry({
    required this.title,
    required this.body,
    required this.handler,
    this.dataPayload,
  }) : receivedAt = DateTime.now();
}

// ── Main screen ───────────────────────────────────────────────────────────

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FcmService _fcmService = FcmService();
  final List<NotificationEntry> _notifications = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _fcmService.initialize(
      onForegroundMessage: (message) {
        _addEntry(message, 'Foreground');
      },
      onNotificationTap: (message) {
        final isTerminated =
            message.sentTime != null &&
            DateTime.now().difference(message.sentTime!).inSeconds > 5;
        _addEntry(
            message, isTerminated ? 'Terminated tap' : 'Background tap');
      },
    );
    if (mounted) setState(() => _token = token);
  }

  void _addEntry(RemoteMessage message, String handler) {
    final notification = message.notification;
    final entry = NotificationEntry(
      title: notification?.title ?? message.data['title'] ?? '(no title)',
      body: notification?.body ?? message.data['body'] ?? '(no body)',
      handler: handler,
      dataPayload: message.data.isNotEmpty ? message.data.toString() : null,
    );
    if (mounted) setState(() => _notifications.insert(0, entry));
  }

  Color _handlerColor(String handler, ColorScheme scheme) {
    switch (handler) {
      case 'Foreground':
        return Colors.green;
      case 'Background tap':
        return Colors.orange;
      case 'Terminated tap':
        return scheme.primary;
      default:
        return scheme.outline;
    }
  }

  IconData _handlerIcon(String handler) {
    switch (handler) {
      case 'Foreground':
        return Icons.notifications_active;
      case 'Background tap':
        return Icons.notifications_paused;
      case 'Terminated tap':
        return Icons.notification_add;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Demo'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear log',
              onPressed: () => setState(() => _notifications.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // FCM token card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key_outlined,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('FCM Device Token',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _token ?? 'Fetching token…',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendChip(
                    color: Colors.green, label: 'Foreground'),
                _LegendChip(
                    color: Colors.orange, label: 'Background tap'),
                _LegendChip(
                    color: scheme.primary, label: 'Terminated tap'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64,
                            color: scheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet.\nSend one from Firebase Console!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final color =
                          _handlerColor(n.handler, scheme);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(_handlerIcon(n.handler),
                                color: color, size: 22),
                          ),
                          title: Text(n.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.body),
                              if (n.dataPayload != null)
                                Text('Data: ${n.dataPayload}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic)),
                              const SizedBox(height: 2),
                              Text(
                                '${n.handler} • ${_formatTime(n.receivedAt)}',
                                style: TextStyle(
                                    fontSize: 11, color: color),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
