import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Noti{

  static Future initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async{
    // var androidInitialize = new AndroidInitializationSettings('ic_launcher');
    var initializationSettings = InitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future showNotification({var id=0,required String title, required String body,var payload,required FlutterLocalNotificationsPlugin fln}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'example',
      'channel_name',
      playSound: true,
      importance: Importance.max,
      priority: Priority.high,
    );

    var not = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0,title,body,not);
  }
}

