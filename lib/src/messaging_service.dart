import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'messaging_dispatcher.dart';
import 'messaging_exception.dart';
import 'messaging_permissions.dart';

/// Base class for create a messaging service based on Firebase Messaging.
///
abstract class MessagingService {
  /// The vapidKey for getting token in web environment.
  /// See Firebase Console / Project Settings / Cloud Messaging.
  String? vapidKey;

  final FirebaseMessaging _firebaseMessaging;
  StreamSubscription<RemoteMessage>? _messagingStream;
  String? _token;

  /// The FirebaseMessaging token
  String? get token => _token;
  bool _hasPermission = false;

  /// True if the user accepted receive messages.
  bool get hasPermission => _hasPermission;

  final Map<Type, MessagingDispatcher<dynamic>> _dispatchers = {};

  MessagingService({FirebaseMessaging? firebaseMessaging})
    : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance {
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      if (_token != token) {
        _token = token;
        await onTokenRefresh();
      }
    });
  }

  /// Initialize FirebaseMessaging and request permission
  Future<void> initialize({MessagingPermissions? permissions}) async {
    if (Platform.isIOS) {
      await _initializeIOS(3);
    }
    _token = await _firebaseMessaging.getToken();
    _messagingStream = FirebaseMessaging.onMessage.listen(dispatch);
    await requestPermission(permissions);
  }

  Future<void> _initializeIOS(int retries) async {
    // For apple platforms, make sure the APNS token is available before making
    //any FCM plugin API calls
    final String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken == null) {
      if (retries == 0) {
        throw MessagingException(
          'Can'
          't initialize iOS APNSToken',
        );
      }
      // APNS token isn't available, retry.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _initializeIOS(retries - 1);
    }
    // APNS token is available, make FCM plugin API requests.
  }

  /// Register a dispatcher
  void registerDispatcher<T>(MessagingDispatcher<T> dispatcher) {
    _dispatchers[T] = dispatcher;
  }

  /// Unregister a dispatcher
  void unregisterDispatcher<T>(MessagingDispatcher<T> dispatcher) {
    _dispatchers.remove(T);
  }

  /// Called when FirebaseMessaging token is refresh
  Future<void> onTokenRefresh();

  /// Return the stream associated to the dispatcher
  Stream<T> stream<T>() {
    return _dispatchers[T]!.stream as Stream<T>;
  }

  /// Called when receives a message that is not processed for any dispatcher
  void messageNotDispatched(RemoteMessage message) {}

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
  Future<void> requestPermission(MessagingPermissions? permissions) async {
    final NotificationSettings response = permissions == null
        ? await _firebaseMessaging.requestPermission()
        : await _firebaseMessaging.requestPermission(
            alert: permissions.alert,
            announcement: permissions.announcement,
            badge: permissions.badge,
            carPlay: permissions.carPlay,
            criticalAlert: permissions.criticalAlert,
            provisional: permissions.provisional,
            sound: permissions.sound,
            providesAppNotificationSettings:
                permissions.providesAppNotificationSettings,
          );

    _hasPermission =
        (response.authorizationStatus == AuthorizationStatus.authorized) ||
        (response.authorizationStatus == AuthorizationStatus.provisional);
  }

  /// Stops receiving messages. FirebaseMessaging is destroyed. To return to
  /// receive messages call again [initialize].
  Future<void> stop() async {
    await _messagingStream?.cancel();
    _messagingStream = null;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
