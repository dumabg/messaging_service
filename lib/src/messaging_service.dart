import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'messaging_dispatcher.dart';

/// Base class for create a messaging service based on Firebase Messaging.
///
abstract class MessagingService {
  /// The vapidKey for getting token in web environment.
  /// See Firebase Console / Project Settings / Cloud Messaging.
  String? vapidKey;

  FirebaseMessaging? _firebaseMessaging;
  StreamSubscription<RemoteMessage>? _messagingStream;
  String? _token;

  /// The FirebaseMessaging token
  String? get token => _token;
  bool _hasPermission = false;

  /// True if the user accepted receive messages.
  bool get hasPermission => _hasPermission;

  final Map<Type, MessagingDispatcher<dynamic>> _dispatchers = {};

  /// Initialize FirebaseMessaging and request permission
  Future<void> initialize() async {
    await stop();
    _initMessaging();
    await requestPermission();
  }

  /// Register a dispatcher
  void registerDispatcher<T>(MessagingDispatcher<T> dispatcher) {
    _dispatchers[T] = dispatcher;
  }

  /// Called when FirebaseMessaging token is refresh
  Future<void> onTokenRefresh();

  /// Return the stream associated to the dispatcher
  Stream<T> stream<T>() {
    return _dispatchers[T]!.stream as Stream<T>;
  }

  /// Called when receives a message that is not processed for any dispatcher
  void messageNotDispatched(RemoteMessage message) {}

  void _initMessaging() {
    _firebaseMessaging = FirebaseMessaging.instance;
    _messagingStream = FirebaseMessaging.onMessage.listen(dispatch);
    _firebaseMessaging!.onTokenRefresh.listen(
      (String token) async {
        if (_token != token) {
          _token = token;
          await onTokenRefresh();
        }
        _hasPermission = true;
      },
    );
  }

  void dispatch(RemoteMessage message) {
    for (final MessagingDispatcher<dynamic> dispatcher in _dispatchers.values) {
      if (dispatcher.dispatch(message)) {
        return;
      }
    }
    messageNotDispatched(message);
  }

  /// Request permission to user for accepting incoming messages. This method
  /// is already called automatically in [initialize]
  Future<void> requestPermission() async {
    if (_firebaseMessaging == null) {
      _initMessaging();
    }
    final NotificationSettings response =
        await _firebaseMessaging!.requestPermission();
    _hasPermission =
        (response.authorizationStatus == AuthorizationStatus.authorized) ||
            (response.authorizationStatus == AuthorizationStatus.provisional);
  }

  /// Stops receiving messages. FirebaseMessaging is destroyed. To return to
  /// receive messages call again [initialize].
  Future<void> stop() async {
    await _messagingStream?.cancel();
    _messagingStream = null;
    _firebaseMessaging = null;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging?.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging?.unsubscribeFromTopic(topic);
  }
}
