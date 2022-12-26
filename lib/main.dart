import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_project/favorites.dart';
import 'package:flutter_project/home_page.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/palette.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'package:workmanager/workmanager.dart';
import 'notification.dart';
import 'package:flutter_project/my_picks_page.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =  FlutterLocalNotificationsPlugin();
//
// const fetchBackground = "fetchBackground";
// void callbackDispatcher() {
//   Workmanager().executeTask((fetchBackground, inputData) async {
//     switch (fetchBackground) {
//       case 'fetchBackground':
//         const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
//         Random _rnd = Random();
//         String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
//             length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
//         var initializationSettings = InitializationSettings();
//         await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//         AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
//           'example',
//           'channel_name',
//           playSound: true,
//           importance: Importance.max,
//           priority: Priority.high,
//         );
//
//         var not = NotificationDetails(android: androidPlatformChannelSpecifics);
//         await flutterLocalNotificationsPlugin.show(0,getRandomString(5),getRandomString(5),not);    }
//     return Future.value(true);
//   });
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FavoritePreferences.init();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "flutter_background example app",
    notificationText: "Background notification for keeping the example app running in the background",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
  bool running = await FlutterBackground.enableBackgroundExecution();
  if(running){
    Timer timer = Timer.periodic(Duration(seconds: 15), (Timer t) =>  checkPicks()
    );
  }
  runApp(const MyApp());

}

late Map<String, dynamic> pickData;
late Map<String, dynamic> gameData;
late List<dynamic> players;
late List<dynamic> playerData;
late List<dynamic> game;
late List<Pick> picksList = [];
var livePickedGames = [];
var liveGamePlayers = [];
List<String> liveGamePlayerPick = [];
// axios.get(player/statistics/gameId
createData() async {
  var picks = await getList();
  if (picks == null || picks.length == 0) return;
  livePickedGames = [];
  liveGamePlayers = [];

  picks.forEach((item) {
    if (DateTime.parse(item.startDate).toLocal().isBefore(DateTime.now())) {
      if (!livePickedGames.contains(item.gameId)) {
        livePickedGames.add(item.gameId);
      }
      liveGamePlayers.add(item.playerId + '^' + item.goals.stat);
    }
  });
  picksList = picks;
  return picks;
}

Future<List<dynamic>> fetchData() async {
  await createData();
  debugPrint(livePickedGames.length.toString());
  debugPrint('FROM MAIN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
  debugPrintAllPicks();
  for (int i = 0; i < livePickedGames.length; i++) {
    final pickData = await APIService().get(
        endpoint: '/players/statistics', query: {"game": livePickedGames[i]});
    final playerData = pickData["response"];
    final gameData = await APIService()
        .get(endpoint: '/games', query: {"id": livePickedGames[i]});
    final game = gameData["response"][0];
    for (int d = 0; d < picksList.length; d++) {
      if (picksList[d].gameId == game['id'].toString()) {
        picksList[d].gameStatus = game['status']['long'];
        picksList[d].period = game['periods']['current'] == null
            ? 0.toString()
            : game['periods']['current'].toString();
        picksList[d].isPeriodActive = game['periods']['endOfPeriod'] == null
            ? 0.toString()
            : game['periods']['endOfPeriod'];
        picksList[d].clock = game['status']['clock'] == null
            ? 0.toString()
            : game['status']['clock'];
      }
    }

    // debugPrint(picksList[i].gameStatus);
    int pickIndex;
    debugPrint(liveGamePlayers.toString());
    for (int k = 0; k < playerData.length; k++) {
      for (int m = 0; m < liveGamePlayers.length; m++) {
        if (picksList[m].playerId == playerData[k]["player"]["id"].toString() && picksList[m].goals.stat == 'Points') {
          picksList[m].goals.current = playerData[k]["points"].toString();
          debugPrint('UPDATED!!!');
          debugPrint(playerData[k]["points"].toString());
        }
        if (picksList[m].playerId == playerData[k]["player"]["id"].toString() && picksList[m].goals.stat == 'Assists') {
          picksList[m].goals.current = playerData[k]["assists"].toString();
        }
        if (picksList[m].playerId == playerData[k]["player"]["id"].toString() && picksList[m].goals.stat == 'Rebounds') {
          picksList[m].goals.current = playerData[k]["totReb"].toString();
        }
        if (picksList[m].playerId == playerData[k]["player"]["id"].toString() && picksList[m].goals.stat == 'Three Pointers') {
          picksList[m].goals.current = playerData[k]["tpm"].toString();
        }
      }
    }
    saveList(picksList);
  }

  final players = picksList;
  return players;
}

checkPicks() async {
  await createData;
  await fetchData();
  var picks = await getList();
  for(int i=0; i<picks.length;i++){
    debugPrint(picks[i].goals.current+'/'+picks[i].goals.line);
    if(picks[i].isNotificationEnabled && picks[i].pickStatus==1){
      sendNotification('✅ Pick successful!', '${picks[i].firstname} ${picks[i].firstname} reached ${(int.parse(picks[i].goals.line)+1).toString()} ${picks[i].goals.stat}!', flutterLocalNotificationsPlugin);
      picks[i].isNotificationEnabled=false;
    }
  }
  saveList(picks);
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
              // Workmanager().registerOneOffTask("fetchBackground", "fetchBackground");
              Workmanager().registerPeriodicTask("fetchBackground", "fetchBackground",frequency: Duration(seconds: 5));
              // const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
              // Random _rnd = Random();
              // String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
              //     length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
              // sendNotification(getRandomString(5),'kseplen',flutterLocalNotificationsPlugin);
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


class DataFetch extends StatefulWidget {
  const DataFetch({Key? key}) : super(key: key);

  @override
  State<DataFetch> createState() => _DataFetchState();
}

class _DataFetchState extends State<DataFetch> {

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
