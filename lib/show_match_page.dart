import 'dart:convert';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'package:http/http.dart';
import 'package:transparent_image/transparent_image.dart';
import 'add_pick_page.dart';
import 'favorite_prefs.dart';
import 'my_picks_page.dart';

Future fetchStandings() async {
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
  final response = await http.get(
      Uri.parse('https://stats.nba.com/stats/leaguestandings?LeagueID=00&Season=2022-23&SeasonType=Regular+Season&SeasonYear='), headers:headers);

  debugPrint('fetched');

  if (response.statusCode == 200) {
    debugPrint(response.body);
    return jsonDecode(response.body);
  } else {
    debugPrint('Failed to fetch common team roster: ${response.statusCode}');
  }
}


Future fetchCommonTeamRoster(String teamId) async {
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
  final response = await http.get(
      Uri.parse('https://stats.nba.com/stats/commonteamroster?LeagueID=00&Season=2022-23&TeamID=${teamId}'), headers:headers);

  if (response.statusCode == 200) {
    // debugPrint(response.body);
    return jsonDecode(response.body);
  } else {
    debugPrint('Failed to fetch common team roster: ${response.statusCode}');
  }
}

class ShowMatchPage extends StatefulWidget {
  const ShowMatchPage({Key? key,required this.match}) : super(key: key);
  final match;
  // final Object teams;

  @override
  State<ShowMatchPage> createState() => _ShowMatchPageState();
}

class _ShowMatchPageState extends State<ShowMatchPage> {
  var teams;
  var match;
  var matchId;

  getMatchId(){
    matchId = match['id'].toString();
  }
  bool canVibrate = false;

  @override
  void initState() {
    fetchStandings();
    super.initState();
    match = widget.match;
    _checkIfVibrate();

    // teams = widget.teams;
  }
  List<String>? favorites = FavoritePreferences.getFavorites();
  late Map<String, dynamic> team1Data;
  late Map<String, dynamic> team2Data;
  late List<dynamic> team1;
  late List<dynamic> team2;
  Future<List<dynamic>> fetchSingleMatchData() async {
    final team1Data = await fetchCommonTeamRoster(match["homeTeam"]["teamId"].toString());
    final team1 = team1Data["resultSets"][0]["rowSet"];
    // debugPrint(team1.toString());
    final team2Data = await fetchCommonTeamRoster(match["awayTeam"]["teamId"].toString());
    final team2 = team2Data["resultSets"][0]["rowSet"];
    // debugPrint(team2.toString());
    var playersByTeam = [...team1, ...team2, team1.length];
    // debugPrint(playersByTeam.toString());
    return playersByTeam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              // Text(teams["home"]["nickname"],style: TextStyle(fontWeight: FontWeight.w300),),
              Padding(
                padding: const EdgeInsets.all(8.0),
                // child: Image.network(teams["home"]["logo"],height: 20,width: 20,),
              ),
            ],
          ),
          // Text("vs",style: TextStyle(color: Colors.orange[100],fontWeight: FontWeight.w300),),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                // child: Image.network(teams["visitors"]["logo"],height: 20,width: 20,),
              ),
              // Text(teams["visitors"]["nickname"],style: TextStyle(fontWeight: FontWeight.w300),),
            ],
          ),
        ],
      ),),
      body: Container(
        child: FutureBuilder(
          future: fetchSingleMatchData(),
          builder: (BuildContext context, AsyncSnapshot snapshot){
            if(snapshot.data==null) {
              return Center(child: CircularProgressIndicator());
            }
            else if(snapshot.hasError) {
              return Center(child: Text('Oops,something went wrong :(',style: TextStyle(fontSize: 20),));
            }
            else {
              return Padding(
                padding: EdgeInsets.all(0.8),
                child:ListView.builder(
                  itemCount: snapshot.data.length-1,
                  itemBuilder: (BuildContext context,index){
                    return GestureDetector(
                      onTap: (){
                        String teamId = index <  snapshot.data[snapshot.data.length-1] ? match["homeTeam"]["teamId"].toString() : match["homeTeam"]["teamId"].toString();
                        openOptionsModal(snapshot.data[index],index,snapshot.data[snapshot.data.length-1]);},
                      child:Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 5, 2, 5),
                              // child:Text(snapshot.data[index][14].toString())
                              child: Container(
                                width: 40,
                                height: 45,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100.0),
                                  child: FadeInImage.memoryNetwork(
                                    height: 40,
                                    image: 'https://cdn.nba.com/headshots/nba/latest/1040x760/${snapshot.data[index][14].toString()}.png',
                                    placeholder: kTransparentImage,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:(c, o, s) => Image.asset('assets/team_pngs/fallback.png'),
                                  ),
                                ),
                              )
                              // CircleAvatar(
                              //     backgroundColor: Colors.white,
                              //     backgroundImage: NetworkImage('https://cdn.nba.com/headshots/nba/latest/1040x760/${snapshot.data[index][14].toString()}.png'))
                              // child: index <  snapshot.data[snapshot.data.length-1] ? Image.network(teams["home"]["logo"],height: 35,width: 35,) : Image.network(teams["visitors"]["logo"],height: 35,width: 35,),
                            ),
                            SizedBox(width: 15),
                            Text(snapshot.data[index][3],style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void openOptionsModal(player,index,homeTeamLength) async{
    List<Favorite> favs = await getFavorites();
    bool exists = false;
    int indexFound = -1;
     for(int i=0;i<favs.length;i++){
      if(favs[i].playerId==player[14].toString()){
        exists = true;
        indexFound=i;
        break;
      }
    }
    debugPrint(exists.toString());
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        height: 150,
        child: Scaffold(
          body: Container(
            color: Color(0xFF737373),
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10)
                )
              ),
              child: _buildPlayerOptionsModal(player,index,homeTeamLength,exists,indexFound),
            ),
          ),
        ),
      );
    });
  }

  Column _buildPlayerOptionsModal(player,index,homeTeamLength,exists,indexFound){
    return Column(
      children: [
        Padding(child: Text(player[3],style: TextStyle(fontSize: 15,),),padding: EdgeInsets.fromLTRB(0,10,0,10),),
        ListTile(
          leading: Icon(Icons.sports_basketball,color: Colors.orange[500],),
          title: Text('Add Pick'),
          onTap: () => _selectPlayer(player,match),
        ),
        ListTile(
          leading: !exists ? Icon(Icons.star_border_rounded,color: Colors.amber,) : Icon(Icons.star_rounded,color: Colors.amber,),
          title: !exists ? Text('Add To Favorites') : Text('Remove From Favorites'),
          onTap: () {
            _getVibration(FeedbackType.success);
            !exists ? addToFavorites(player, index, homeTeamLength) : removeFavorite(indexFound);
            Navigator.pop(context);
          }),
      ],
    );
  }

  void _selectPlayer( player,match){
    // debugPrint(match.toString());
    Navigator.pop(context);
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context)
      {
        return AddPickPage(player: player, match: match);
      }));
    });
  }

  void removeFavorite(index) async {
    var favs = await getFavorites();
    favs.removeAt(index);
    saveFavorites(favs);
  }

  void addToFavorites(player,index,homeTeamLength) async{
    // favorites = FavoritePreferences.getFavorites();
    // List<String> nonNullFavorites = favorites ?? [];
    String headshot;
       headshot=('https://cdn.nba.com/headshots/nba/latest/1040x760/${player[14]}.png');
    addFavorite(Favorite(player[14].toString(),player[3],headshot,player[0].toString()));
    setState(() {

    });
  }
  _checkIfVibrate() async {
    // check if device can vibrate
    canVibrate = await Vibrate.canVibrate;
  }

  _getVibration(feedbackType) async {
    if (canVibrate) {
      Vibrate.feedback(feedbackType);
      // Vibrate.vibrate();   // Try this too!
    }
  }


}
