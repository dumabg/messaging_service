import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:messaging_service/messaging_service.dart';
import 'package:test/test.dart';

class MessageTest {
  final String value;
  MessageTest(this.value);
}

class MessagingTestDispatcher extends MessagingDispatcher<MessageTest> {
  MessagingTestDispatcher() : super('test');

  @override
  MessageTest getMessage(RemoteMessage message) {
    return MessageTest(message.data['value'] as String);
  }
}

class ChatMessageTest {
  final String text;

  ChatMessageTest(this.text);
}

class ChatTestDispatcher extends MessagingDispatcher<ChatMessageTest> {
  ChatTestDispatcher() : super('chat');

  @override
  ChatMessageTest getMessage(RemoteMessage message) {
    return ChatMessageTest(message.data['text'] as String);
  }
}

class MockMessagingService extends MessagingService {
  bool notDispatched = false;

  Stream<MessageTest> messagingTest() => stream<MessageTest>();
  Stream<ChatMessageTest> messagingChat() => stream<ChatMessageTest>();

  @override
  Future<void> onTokenRefresh() async {}

  @override
  void messageNotDispatched(RemoteMessage message) {
    notDispatched = true;
  }
}

void main() {
  final messagingService = MockMessagingService();
  group('One dispatcher', () {
    final messagingTestDispatcher = MessagingTestDispatcher();
    messagingService.registerDispatcher<MessageTest>(messagingTestDispatcher);
    test('Stream', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final subscription1 =
          messagingService.messagingTest().listen((MessageTest message) {
        expect(message.value, '0');
        completer1.complete();
      });
      final subscription2 =
          messagingService.messagingTest().listen((MessageTest message) {
        expect(message.value, '0');
        completer2.complete();
      });
      // Simulate than a message arrives
      messagingService.dispatch(RemoteMessage.fromMap({
        'data': {'type': 'test', 'value': '0'}
      }));
      await Future.wait([completer1.future, completer2.future]);
      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('Message not dispatched', () {
      messagingService.dispatch(RemoteMessage.fromMap({
        'data': {'type': 'other'}
      }));
      expect(messagingService.notDispatched, true);
    });
  });

  test('Two dispatchers', () async {
    final chatTestDispatcher = ChatTestDispatcher();
    messagingService.registerDispatcher<ChatMessageTest>(chatTestDispatcher);
    final completer1 = Completer<void>();
    final completer2 = Completer<void>();
    final subscription1 =
        messagingService.messagingChat().listen((ChatMessageTest message) {
      expect(message.text, 'Hola mundo');
      completer1.complete();
    });
    final subscription2 =
        messagingService.messagingTest().listen((MessageTest message) {
      expect(message.value, '0');
      completer2.complete();
    });
    // Simulate than a message arrives
    messagingService
      ..dispatch(RemoteMessage.fromMap({
        'data': {'type': 'test', 'value': '0'}
      }))
      ..dispatch(RemoteMessage.fromMap({
        'data': {'type': 'chat', 'text': 'Hola mundo'}
      }));
    await Future.wait([completer1.future, completer2.future]);
    await subscription1.cancel();
    await subscription2.cancel();
  });
}
