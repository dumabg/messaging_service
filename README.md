Library for creating a messaging service for different kind of messages received from FirebaseMessaging.

## Features

- Testable
- Encapsulate FirebaseMessaging dependencies.
- Create different dispatchers for every kind of messages received.
- Request permissions to user.

## How it works

 When a Firebase Messaging message is received, MessagingService iterates
 over all the registered dispatchers calling the dispatch method,
 until one of them returns true, meaning than the dispatcher recognizes the
 incoming message.

 The dispatcher has the responsibility to interpret the incoming message,
 transform it in a T object and send it to its stream.

 T is the class of the message that will be produced.

 To identify the message, the dispatcher tries to find a field with a specific value in the data of the Firebase Messaging (RemoteMessage). 


## Usage
Create a class that represents your messaging service.

```dart
class MyMessagingService extends MessagingService {
}
```
For every kind of message that receives, create a class that represents the data received and a class dispatcher for that kind of message. The dispatcher is responsible to analyze the data received and transform it to the class.

### Example: Chat message
Imagine than a chat message is identified when in his data has a key 'type' and value 'chat'.

- Create a class that represents a chat message:
```dart
 class ChatMessage {
    final DateTime when;
    final String msg;
    final bool isMe;

   ChatMessage(this.when, this.msg, this.isMe);
 }
```

- Create a dispatcher for that kind of message. See the 'chat' on the super constructor. It's the value that identifies the received message. The default key is 'type'. 

```dart
 class MessagingChatDispatcher extends MessagingDispatcher<ChatMessage> {
 MessagingChatDispatcher(): super('chat');

  @override
  ChatMessage getMessage(RemoteMessage message) {
    var data = message.data;
    return ChatMessage(data['when'], data['msg'], data['isMe']);
  }
 }
```

- Modify your messaging service offering your new kind messages:
```dart
class MyMessagingService extends MessagingService {
    Stream<ChatMessage> messagingChat() => stream<ChatMessage>();
}
```

That's all. For starting MyMessagingService, you need to register your new dispatcher and call the `initialize` method:

```dart
    var messagingService = MyMessagingService();
    var messagingChatDispatcher = MessagingChatDispatcher();
    messagingService.registerDispatcher<ChatMessage>(messagingChatDispatcher);
    messagingService.initialize();
```

## Additional information
- See an example on test.
- For testing, simulate incoming messages. See test.
