import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_project/show_match_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Map<String, dynamic> gamesTodayData;
  late List<dynamic> matchesToday;
  late Map<String, dynamic> gamesTomorrowData;
  late List<dynamic> matchesTomorrow;
  late Map<String, dynamic> gamesYesterday;
  late List<dynamic> matchesYesterday;

  Future<List<dynamic>> fetchMatchData() async {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year,now.month,now.day);
    DateTime tomorrowDate = now.add(Duration(days:1));
    DateTime yesterdayDate = now.subtract(Duration(days:1));
    DateTime aTomorrowDate = now.add(Duration(days:2));
    String tomorrowDateString = tomorrowDate.toString().split(" ")[0];
    String aTomorrowDateString = aTomorrowDate.toString().split(" ")[0];
    String yesterdayDateString = yesterdayDate.toString().split(" ")[0];
    String dateString = date.toString().split(" ")[0];
    final gamesYesterdayData = await APIService().get(endpoint:'/games', query:{"date": yesterdayDateString});
    final gamesTodayData = await APIService().get(endpoint:'/games', query:{"date": dateString});
    final matchesToday = gamesTodayData["response"];
    final matchesYesterday = gamesYesterdayData["response"];
    matchesToday.retainWhere((x){
      return x["status"]["long"]!="Finished";
    });
    matchesYesterday.retainWhere((x){
      return x["status"]["long"]!="Finished";
    });
    final gamesTomorrowData = await APIService().get(endpoint:'/games', query:{"date": tomorrowDateString});
    final gamesATomorrowData = await APIService().get(endpoint:'/games', query:{"date": aTomorrowDateString});
    final matchesTomorrow = gamesTomorrowData["response"];
    final matchesATomorrow = gamesATomorrowData["response"];
    var matches = [...matchesYesterday,...matchesToday,...matchesTomorrow,...matchesATomorrow];
    return matches;
  }

  Future<List<dynamic>> getScoreboard() async {
    final response = await http.get(Uri.parse('https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json'));
    var scoreboard;
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      scoreboard = json.decode(response.body)['scoreboard'];
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load scoreboard');
    }
    List<Object> games = scoreboard["games"];
    return games;
  }

  Future<List<dynamic>> getSchedule() async {
    final response = await http.get(Uri.parse('https://cdn.nba.com/static/json/staticData/scheduleLeagueV2.json'));
    var schedule;
    var games =[];
    // debugPrint(DateFormat('d/m/yyyy').format(DateTime.now()).toString());
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      schedule = json.decode(response.body)['leagueSchedule']["gameDates"];
      for(int i=0;i<schedule.length;i++){
        // debugPrint(schedule[i]["gameDate"]);
        if(schedule[i]["gameDate"].split(" ")[0]==DateFormat('MM/dd/yyyy').format(DateTime.now())){
          games =[...schedule[i-1]["games"],...schedule[i]["games"],...schedule[i+1]["games"]];
          break;
        }
      }
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load scoreboard');
    }
    // debugPrint(games.toString());
    games = games.where((game) {
      return game["gameStatus"]!=3;
    }).toList();
    return games;
  }

  @override
  void initState(){
    getSchedule();
    getScoreboard();
    // fetchMatchData();
  }
  @override
  Widget build(BuildContext context) {
    final _screen =  MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Games'),
      ),
      body: Container(
          child: FutureBuilder(
            future:  getSchedule(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.data==null) {
                return Center(child: CircularProgressIndicator());
              }
              else{
                return Container(
                  margin: EdgeInsets.fromLTRB(0,20,0,0),
                  child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          margin: EdgeInsets.fromLTRB(20, 0,20,15),
                          child: GestureDetector(
                            onTap: (){
                              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context){
                                return ShowMatchPage(match: snapshot.data[index]);
                              }),);
                              },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  elevation: 3,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 10,10, 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Container(
                                              width: (_screen.width-40)*0.2,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(snapshot.data[index]["gameStatus"]=='3' ? snapshot.data[index]["gameStatusText"] : (DateTime.parse(snapshot.data[index]["gameDateTimeUTC"]).toLocal().add(const Duration(minutes: 10)).toString().split(" ")[1].substring(0,5)+"\n"+DateTime.parse(snapshot.data[index]["gameDateTimeUTC"]).toLocal().toString().split(" ")[0].substring(5,10).split('-')[1]+'-'+DateTime.parse(snapshot.data[index]['gameDateTimeUTC']).toLocal().toString().split(" ")[0].substring(5,10).split('-')[0] ),
                                                    style: TextStyle(fontWeight: FontWeight.w300,fontSize: 15,color: Colors.black54),
                                                    textAlign: TextAlign.center,)
                                                ],
                                              ),
                                            ),
                                          VerticalDivider(width: 1.0,),
                                          Container(
                                            width: (_screen.width-40)*0.7,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(5, 5,5, 5),
                                                  child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children:[
                                                        Padding(
                                                          padding: const EdgeInsets.fromLTRB(0, 0,25, 0),
                                                          child: Image.asset('assets/team_pngs/${snapshot.data[index]["homeTeam"]["teamId"]}.png',height: 25,width: 25,),
                                                          // child: Container(width: 25,height: 25, child: SvgPicture.network('https://cdn.nba.com/logos/nba/${snapshot.data[index]["homeTeam"]["teamId"].toString()}/global/L/logo.svg')),
                                                        ),
                                                        Text(snapshot.data[index]["homeTeam"]["teamCity"]+" "+snapshot.data[index]["homeTeam"]["teamName"],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
                                                      ]
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(5, 5,5, 5),
                                                  child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.fromLTRB(0, 0,25, 0),
                                                          child: Container(height: 20,child: Image.asset('assets/team_pngs/${snapshot.data[index]["awayTeam"]["teamId"]}.png')),
                                                          // child: Container(width: 25,height: 25, child: SvgPicture.network('https://cdn.nba.com/logos/nba/${snapshot.data[index]["awayTeam"]["teamId"].toString()}/global/L/logo.svg')),
                                                        ),
                                                        Text(snapshot.data[index]["awayTeam"]["teamCity"]+" "+snapshot.data[index]["awayTeam"]["teamName"],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
                                                      ]
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                    ]),
                                  ),),
                          ),
                        );
                      },
                    ),
                );
                }
            }),
      ),
    );
  }
}

