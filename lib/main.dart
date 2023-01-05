import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_project/favorites.dart';
import 'package:flutter_project/home_page.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/palette.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'notification.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =  FlutterLocalNotificationsPlugin();

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
    // Timer timer = Timer.periodic(Duration(seconds: 15), (Timer t) =>  checkPicks()
    // );
  }
  runApp(const MyApp());

}

late List<dynamic> players;
late List<dynamic> game;
late List<Pick> picksList = [];
var livePickedGames = [];
var liveGamePlayers = [];
List<String> liveGamePlayerPick = [];
// axios.get(player/statistics/gameId

createData() async {
  var scoreboard = await fetchTodaysScoreboard();
  List<dynamic> games = scoreboard["scoreboard"]["games"];
  var picks = await getList();
  if (picks == null || picks.length == 0) return;
  for(int i=0;i<games.length;i++){
    for(int j=0;j<picks.length;j++){
      if(games[i]["gameId"].toString()==picks[j].gameId && picks[j].gameStatus!=3.toString()){
        if(!livePickedGames.contains(games[i]["gameId"].toString())){
          livePickedGames.add(games[i]["gameId"].toString());
        }
        liveGamePlayers.add('${picks[j].playerId}^${picks[j].goals.stat}');
      }
    }
  }
  return picks;
}

Future<List<dynamic>> fetchData() async {
  await createData();
  var boxscore;
  var players;
  picksList = await getList();
  for(int i=0;i<livePickedGames.length;i++){
    final res = await http.get(Uri.parse('https://cdn.nba.com/static/json/liveData/boxscore/boxscore_${livePickedGames[i]}.json'));
    boxscore = json.decode(res.body)["game"];
    for(int j=0;j<picksList.length;j++){
      if(picksList[j].gameId==boxscore["gameId"].toString()){
        picksList[j].gameStatus = boxscore["gameStatus"].toString();
        picksList[j].period = boxscore["period"].toString();
        picksList[j].isPeriodActive = (boxscore["gameClock"]=="PT00M00.00S" || boxscore["gameClock"]=="") ? false : true;
        picksList[j].clock = boxscore["gameClock"];
      }
    }
    players = [...boxscore["homeTeam"]["players"],...boxscore["awayTeam"]["players"]];
    for (int k = 0; k < players.length; k++) {
      for (int m = 0; m < picksList.length; m++) {
        if (picksList[m].playerId == players[k]["personId"].toString() && picksList[m].goals.stat == 'Points') {
          picksList[m].goals.current = players[k]["statistics"]["points"].toString();
        }
        if (picksList[m].playerId == players[k]["personId"].toString() && picksList[m].goals.stat == 'Rebounds') {
          picksList[m].goals.current = players[k]["statistics"]["reboundsTotal"].toString();
        }
        if (picksList[m].playerId == players[k]["personId"].toString() && picksList[m].goals.stat == 'Assists') {
          picksList[m].goals.current = players[k]["statistics"]["assists"].toString();
        }
        if (picksList[m].playerId == players[k]["personId"].toString() && picksList[m].goals.stat == 'Three Pointers') {
          picksList[m].goals.current = players[k]["statistics"]["threePointersMade"].toString();
        }
      }
    }
  }
  saveList(picksList);
  final picks = picksList;
  return picks;
}



checkPicks() async {
  await createData;
  await fetchData();
  var picks = await getList();
  for(int i=0; i<picks.length;i++){
    if(picks[i].isNotificationEnabled && picks[i].pickStatus==1){
      sendNotification('✅ Pick successful!', '${picks[i].name} reached ${picks[i].goals.current} ${picks[i].goals.stat}!', flutterLocalNotificationsPlugin);
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
