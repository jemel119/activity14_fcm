import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fcm_service.dart';
import 'firebase_options.dart';

const defaultImage = 'assets/images/default.png';
const promoImage = 'assets/images/promo.png';

({String? assetPath, String diagnostic}) validatePayload(
  Map<String, dynamic> data,
) {
  if (data['action'] != 'update_ui') {
    return (
      assetPath: null,
      diagnostic: 'Rejected: expected action "update_ui".',
    );
  }

  return switch (data['asset']) {
    'default' => (assetPath: defaultImage, diagnostic: 'Payload accepted.'),
    'promo' => (assetPath: promoImage, diagnostic: 'Payload accepted.'),
    null => (assetPath: null, diagnostic: 'Rejected: missing asset.'),
    _ => (assetPath: null, diagnostic: 'Rejected: unsupported asset.'),
  };
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background work runs separately from the Android app's widget state.
  debugPrint('FCM background message received.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Activity 14 FCM',
      home: CampusUpdatesPage(),
    );
  }
}

class CampusUpdatesPage extends StatefulWidget {
  const CampusUpdatesPage({super.key});

  @override
  State<CampusUpdatesPage> createState() => _CampusUpdatesPageState();
}

class _CampusUpdatesPageState extends State<CampusUpdatesPage> {
  final _service = FCMService();

  String _title = 'Campus Updates';
  String _imagePath = defaultImage;
  String _handler = 'None yet';
  String _messageId = '—';
  String _diagnostic = 'Waiting for a message.';
  String _permission = 'Permission: checking…';
  String _setupStatus = 'Starting messaging…';
  int _receiptCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_startMessaging());
  }

  Future<void> _startMessaging() async {
    try {
      await _service.initialize(
        onData: _handleMessage,
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            if (status.startsWith('Permission:')) {
              _permission = status;
            } else {
              _setupStatus = status;
            }
          });
        },
      );

      if (!mounted) return;
      setState(() => _setupStatus = 'FCM token ready.');
    } catch (error) {
      debugPrint('FCM setup error: $error');
      if (!mounted) return;
      setState(
        () => _setupStatus = 'Messaging setup failed. Check debug logs.',
      );
    }
  }

  void _handleMessage(RemoteMessage message, String handler) {
    if (!mounted) return;

    final result = validatePayload(message.data);
    final assetPath = result.assetPath;

    setState(() {
      _handler = handler;
      _messageId = message.messageId ?? 'Unavailable';
      _receiptCount++;
      _diagnostic = result.diagnostic;

      if (assetPath != null) {
        final title = message.notification?.title?.trim();
        _title = title == null || title.isEmpty
            ? (assetPath == promoImage ? 'Campus Event' : 'Campus Updates')
            : title;
        _imagePath = assetPath;
      }
    });
  }

  Future<void> _copyFcmToken() async {
    String feedback;

    try {
      final token = await _service.getCurrentToken();

      if (token == null || token.isEmpty) {
        feedback = 'FCM token unavailable. Try again.';
      } else {
        await Clipboard.setData(ClipboardData(text: token));
        feedback = 'FCM token copied.';
      }
    } catch (error) {
      debugPrint('Could not copy FCM token: $error');
      feedback = 'Could not copy the FCM token. Try again.';
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(feedback)));
  }

  @override
  void dispose() {
    unawaited(_service.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 14 FCM')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                _imagePath,
                fit: BoxFit.contain,
                semanticLabel: _imagePath == promoImage
                    ? 'Campus Event card'
                    : 'Campus Updates card',
              ),
            ),
            const SizedBox(height: 16),
            Text('Last handler: $_handler'),
            Text('Receipt count: $_receiptCount'),
            Text('Message ID: $_messageId'),
            Text(_diagnostic),
            const SizedBox(height: 12),
            Text(_permission),
            Text(_setupStatus),
            if (kDebugMode)
              OutlinedButton(
                onPressed: _copyFcmToken,
                child: const Text('Copy FCM token'),
              ),
          ],
        ),
      ),
    );
  }
}
