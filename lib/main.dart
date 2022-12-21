import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_project/favorites.dart';
import 'package:flutter_project/home_page.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/palette.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'notification.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =  FlutterLocalNotificationsPlugin();

const fetchBackground = "fetchBackground";
void callbackDispatcher() {
  Workmanager().executeTask((fetchBackground, inputData) async {
    switch (fetchBackground) {
      case 'fetchBackground':
        debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =  FlutterLocalNotificationsPlugin();
        const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/ic_launcher');
        final InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid);
        bool pick = true;
        var id = new DateTime.now().toString();
        if(pick)
        Noti.showNotification(id:id,title: 'hello1', body: "body1", fln: flutterLocalNotificationsPlugin);
        if(!pick)
        Noti.showNotification(title: 'hello2', body: "body2", fln: flutterLocalNotificationsPlugin);
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FavoritePreferences.init();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );
  Workmanager().registerOneOffTask("fetchBackground", "fetchBackground");
  runApp(const MyApp());

}

sendNotification(String title,String body, fln) async{
  Noti.showNotification(title: title, body: body, fln: fln);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Palette.kToDark,
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  List<Widget> pages = const [
    HomePage(),
    MyPicksPage(),
    FavoritesPage()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: const [
                Text('N'),
                Padding(
                  padding: EdgeInsets.fromLTRB(0,3,0,0),
                  child: Icon(Icons.sports_basketball,color: Colors.orange,size: 16,),
                ),
                Text('tibet',style: TextStyle(letterSpacing: 2),)
              ],
            ),
            ElevatedButton(onPressed: () async {
              const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
              Random _rnd = Random();
              String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
                  length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
              sendNotification(getRandomString(5),'kseplen',flutterLocalNotificationsPlugin);
            }, child: Text('hi',style: TextStyle(color: Colors.white),))
          ],
        ),
      ),
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.note), label: 'My Picks'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favorites'),
        ],
        onDestinationSelected: (int index){
          setState((){
            currentPage = index;
          });
        },
        selectedIndex: currentPage,
      ),
    );
  }
}
