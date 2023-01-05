import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'favorite_prefs.dart';
import 'package:flutter_project/favorite_prefs.dart';

import 'my_picks_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {


  Future fetchPlayerStatistics(String playerId,String season) async {
    final headers = {
      'Host': 'stats.nba.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:61.0) Gecko/20100101 Firefox/61.0',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.5',
      'Referer': 'https://www.nba.com',
      'Origin':'https://www.nba.com',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'x-nba-stats-origin': 'stats',
      'x-nba-stats-token': 'true'
    };
    final res = await http.get(
        Uri.parse('https://stats.nba.com/stats/playerdashboardbyyearoveryearcombined?DateFrom=&DateTo=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerID=$playerId&PlusMinus=N&Rank=N&Season=$season&SeasonSegment=&SeasonType=Regular%20Season&ShotClockRange=&VsConference=&VsDivision='), headers:headers);
    if (res.statusCode == 200) {
      // debugPrint(response.body);
      var allStats = jsonDecode(res.body)["resultSets"][0]["rowSet"][0];
      var stats = { "points": allStats[29], "rebounds":allStats[21], "assists":allStats[22], "threePointers":allStats[13], "gamesPlayed":allStats[5] };
      return stats;
    } else {
      debugPrint('Failed to fetch common team roster: ${res.statusCode}');
      return;
    }
  }

  Future<String> getId(String firstname,String lastname) async {
    String jsonString = await rootBundle.loadString('assets/playersById.json');
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // Assuming the JSON file has an array of objects with the keys "name" and "id"
    List<dynamic> objects = jsonData['objects'];

    for (var object in objects) {
      if (object['firstname'].toLowerCase() == firstname.toLowerCase() && object['lastname'].toLowerCase() == lastname.toLowerCase()) {
        return object['id'];
      }
    }
    return 'not_found';
  }
  var ids;
  late List<Favorite> favs = [];

  @override
  void initState() {
    fetchFavoriteData();
  }
  // late Map<String, dynamic> fetchedFav;
  // late List<dynamic> favs;
  Future<List<Favorite>> fetchFavoriteData() async {
    favs = await getFavorites();
    // debugPrint(favs.toString());
    return favs;
  }
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Favorite Players"),
      ),
      body: FutureBuilder(
        future:  fetchFavoriteData(),
    builder: (context, AsyncSnapshot snapshot) {
      if(snapshot.data==null){
        return Center(child: CircularProgressIndicator());
      }
          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                if(snapshot.data.length<1) {
                  return Center(
                    child: Text("No players added to favorites",
                        style: TextStyle(fontSize: 25,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey)));}
                      else {
                  return GestureDetector(
                    onTap: (){debugPrint(snapshot.data[index].playerId);_showStats(context, snapshot.data[index]);},
                    child:  Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      snapshot.data[index]
                                          .headshot),
                                  backgroundColor: Colors.white,
                                ),
                                Container(width: 20,),
                                Text(snapshot.data[index].name,style: TextStyle(fontSize: 17,fontWeight: FontWeight.w300),),
                                // Text(snapshot.data[index])

                              ],
                            ),
                            Row(
                              children: [
                                Container(),
                                GestureDetector(
                                  child: Icon(Icons.cancel_outlined,size: 18,),
                                  onTap: (){_dialogBuilder(context, snapshot.data, index);},
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  );
                }
              },);
        }
      )
    );}

  averageCalculations(String playerId) async {
    var playerStatsRequest = await APIService().get(endpoint:'/players/statistics', query:{"id": playerId, "season":"2022"});
    var playerStats = playerStatsRequest["response"];
    num avgPoints = 0;
    num avgRebounds = 0;
    num avgAssists = 0;
    num avgThreePointers = 0;
    for(int i=0;i<playerStats.length;i++){
      avgPoints+=playerStats[i]["points"];
      avgRebounds+=playerStats[i]["totReb"];
      avgAssists+=playerStats[i]["assists"];
      avgThreePointers+=playerStats[i]["tpm"];
    }
    avgPoints = avgPoints/playerStats.length;
    avgRebounds = avgRebounds/playerStats.length;
    avgAssists = avgAssists/playerStats.length;
    avgThreePointers = avgThreePointers/playerStats.length;
    return [avgPoints.toStringAsFixed(2),avgRebounds.toStringAsFixed(2),avgAssists.toStringAsFixed(2),avgThreePointers.toStringAsFixed(2)];
    // debugPrint(avgPoints.toStringAsFixed(2));
    // debugPrint(avgRebounds.toStringAsFixed(2));
    // debugPrint(avgAssists.toStringAsFixed(2));
    // debugPrint(avgThreePointers.toStringAsFixed(2));
  }

  Future<void> _showStats(BuildContext context, player) async{
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(player.name),
          content: FutureBuilder(
            future: fetchPlayerStatistics(player.playerId,'2022-23'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  width: 100,
                  height: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                          child: Text('Averages in the last ${ snapshot.data['gamesPlayed']} games:',style: TextStyle(fontWeight: FontWeight.w300),)),
                      Container(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Points:  "),
                          Text( snapshot.data['points'].toString()),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Rebounds:  "),
                          Text( snapshot.data['rebounds'].toString()),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Assists:  "),
                          Text( snapshot.data["assists"].toString()),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Three Pointers:  "),
                          Text( snapshot.data["threePointers"].toString()),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                return LinearProgressIndicator(color: Colors.orange,
                backgroundColor: Colors.grey,
                    );
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _dialogBuilder(BuildContext context,List<Favorite> data, int index) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from favorites'),
          content: Text('${data[index].name} will be removed from your favorites'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Ok'),
              onPressed: () {
                data.removeAt(index);
                saveFavorites(data);
                setState(() {

                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}



