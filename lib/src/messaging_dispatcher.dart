import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Base class for define a dispatcher to register on [MessagingService].
///
/// When a Firebase Messaging message is received, [MessagingService] iterates
/// over all the registered dispatchers calling the [dispatch] method,
/// until one of them returns true, meaning than the dispatcher recognizes the
/// incoming message.
///
/// The dispatcher has the responsibility to interpret the incoming message,
/// transform it in a [T] object and send it to its [stream].
///
/// [T] is the class of the message that will be produced.
///
/// To identify the message, the dispatcher tries to find a field with a specific value
/// in the [data] of the Firebase Messaging [RemoteMessage]. The field key and value could be
/// defined using the constructor. By default, the field key is 'type'.
///
/// Example: Chat messages are identified by the field key 'type' with the value 'chat'.
///   See the super on constructor, that pass 'chat' (the value 'type' for the field key
///  is, by default, 'type').
///
/// ```dart
///
/// class ChatMessage {
///    final DateTime when;
///    final String msg;
///    final bool isMe;
///
///   ChatMessage(this.when, this.msg, this.isMe);
/// }
///
/// class MessagingChatDispatcher extends MessagingDispatcher<ChatMessage> {
/// MessagingChatDispatcher(): super('chat');
///
///  @override
///  ChatMessage getMessage(RemoteMessage message) {
///    var data = message.data;
///    return ChatMessage(data['when'], data['msg'], data['isMe']);
///  }
/// }
/// ```
abstract class MessagingDispatcher<T> {
  final _controller = StreamController<T>.broadcast();
  final String typeKey;
  final String type;

  MessagingDispatcher(this.type, {this.typeKey = 'type'});

  Stream<T> get stream => _controller.stream;

  T getMessage(RemoteMessage message);

  bool dispatch(RemoteMessage message) {
    Map<String, dynamic> data = message.data;
    if (data.containsKey(typeKey) && ((data[typeKey] == type))) {
      _controller.add(getMessage(message));
      return true;
    } else {
      return false;
    }
  }

  void close() {
    _controller.close();
  }
}
