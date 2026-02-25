/// See [FirebaseMessaging.requestPermissions]
class MessagingPermissions {
  final bool alert;
  final bool announcement;
  final bool badge;
  final bool carPlay;
  final bool criticalAlert;
  final bool provisional;
  final bool sound;
  final bool providesAppNotificationSettings;

  MessagingPermissions({
    this.alert = true,
    this.announcement = false,
    this.badge = true,
    this.carPlay = false,
    this.criticalAlert = false,
    this.provisional = false,
    this.sound = true,
    this.providesAppNotificationSettings = false,
  });
}
