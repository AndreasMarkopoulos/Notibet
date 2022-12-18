import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

int picksCount = 4;
int thisPicksCount = 3;

class Pick {
  String gameId;
  String gameStatus;
  String player;
  String homeLogo;
  String visitorLogo;
  Goal goals;

  Pick(this.gameId,this.gameStatus,this.player,this.homeLogo,this.visitorLogo,this.goals);

  int get pickStatus {
    int status = gameStatus!='Finished' ? 0 : (goals.percentage<1 ? -1 : 1);
    return status;
  }
}

class Goal {
  String stat;
  String overUnder;
  String line;
  String current='0';

  Goal(this.stat,this.line,this.overUnder,this.current);

  double get percentage {
    // debugPrint(line+current);
    return int.parse(current)/(int.parse(line)+1);
  }
}

class APIService {
  // API key
  // static const _api_key = "90555505ebmshf5c58df86118d82p108901jsn95f1d833ea58";
  // Base API url
  static const String _baseUrl = "api-nba-v1.p.rapidapi.com";
  // Base headers for Response url
  static const Map<String, String> _headers = {
    'X-RapidAPI-Key': '90555505ebmshf5c58df86118d82p108901jsn95f1d833ea58',
    'X-RapidAPI-Host': 'api-nba-v1.p.rapidapi.com'
  };

  Future<dynamic> get({
    required String endpoint,
    required Map<String, String> query,
  }) async {
    Uri uri = Uri.https(_baseUrl, endpoint, query);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return json.decode(response.body);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load json data');
    }
  }
}

class MyPicksPage extends StatefulWidget {
  const MyPicksPage({Key? key}) : super(key: key);

  @override
  State<MyPicksPage> createState() => _MyPicksPageState();
}

class _MyPicksPageState extends State<MyPicksPage> {
  late Map<String, dynamic> pickData;
  late Map<String, dynamic> gameData;
  late List<dynamic> players;
  late List<dynamic> playerData;
  late List<dynamic> game;
  var picks =FavoritePreferences.getPicks();
  late List<Pick> picksList = [];
  var livePickedGames = [];
  var liveGamePlayers = [];
  List<String> liveGamePlayerPick = [];
  // axios.get(player/statistics/gameId
  createData(){
    if(picks==null || picks.length==0) return;
    livePickedGames = [];
    liveGamePlayers = [];
    liveGamePlayerPick = [];
    debugPrint(FavoritePreferences.getPicks()[0]);
    picks.forEach((item){
      var fields=item.split("*");
      var pickFields = fields[4].split("#");
      if(DateTime.parse(fields[1]).toLocal().isBefore(DateTime.now())){
        livePickedGames.add(fields[0]);
      }
      for(int i=0;i<pickFields.length;i++){
        if(DateTime.parse(fields[1]).toLocal().isBefore(DateTime.now())){
          liveGamePlayers.add(pickFields[i].split(',')[0]+"^"+pickFields[i].split('&')[1]);
        }
        picksList.add(Pick(fields[0],'?',pickFields[i].split('&')[0],fields[2],fields[3],Goal(pickFields[i].split('&')[1],pickFields[i].split('&')[3],pickFields[i].split('&')[2].split(".")[1],0.toString())));
      }
    });
    return picksList;
  }

  Future<List<dynamic>> fetchData() async {
    for(int i=0;i<livePickedGames.length;i++){
      final pickData = await APIService().get(endpoint:'/players/statistics', query:{"game":livePickedGames[i]});
      final playerData = pickData["response"];
      final gameData = await APIService().get(endpoint:'/games', query:{"id":livePickedGames[i]});
      final game = gameData["response"][0];
      for(int d=0;d<picksList.length;d++){
        if(picksList[d].gameId==game['id'].toString()){
          picksList[d].gameStatus=game['status']['long'];
        }
      }
      // debugPrint(picksList[i].gameStatus);
      int pickIndex;
      for(int k=0;k<playerData.length;k++){
        for(int m=0;m<liveGamePlayers.length;m++){
          if(liveGamePlayers[m].split("^")[0]==playerData[k]["player"]["id"].toString() && liveGamePlayers[m].split("^")[1]=='Points'){
            pickIndex=picksList.indexWhere((pick) => pick.player.split(',')[0]==liveGamePlayers[m].split("^")[0] && liveGamePlayers[m].split("^")[1]=='Points');
            if(pickIndex>=0) {
              picksList[pickIndex].goals.current=playerData[k]["points"].toString();
            }
          }
          if(liveGamePlayers[m].split("^")[0]==playerData[k]["player"]["id"].toString() && liveGamePlayers[m].split("^")[1]=='Assists'){
            pickIndex=picksList.indexWhere((pick) => pick.player.split(',')[0]==liveGamePlayers[m].split("^")[0] && pick.goals.stat=='Assists');
            if(pickIndex>=0) {
              picksList[pickIndex].goals.current=playerData[k]["assists"].toString();
            }
          }
          if(liveGamePlayers[m].split("^")[0]==playerData[k]["player"]["id"].toString() && liveGamePlayers[m].split("^")[1]=='Rebounds'){
            pickIndex=picksList.indexWhere((pick) => pick.player.split(',')[0]==liveGamePlayers[m].split("^")[0] && pick.goals.stat=='Rebounds');
            if(pickIndex>=0) {
              picksList[pickIndex].goals.current=playerData[k]["totReb"].toString();
            }
          }
          if(liveGamePlayers[m].split("^")[0]==playerData[k]["player"]["id"].toString() && liveGamePlayers[m].split("^")[1]=='Three Pointers'){
            debugPrint('found');
            pickIndex=picksList.indexWhere((pick) => pick.player.split(',')[0]==liveGamePlayers[m].split("^")[0] && pick.goals.stat=='Three Pointers');
            if(pickIndex>=0) {
              picksList[pickIndex].goals.current=playerData[k]["tpm"].toString();
            }
          }
        }
      }
    }

    final players = picksList;
    return players;
  }
  @override
  void initState(){
    picks =FavoritePreferences.getPicks();
    createData();
    fetchData();
    Timer timer = Timer.periodic(Duration(seconds: 15), (Timer t) => setState((){}));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(child:Text('My Picks',style: TextStyle(color: Colors.white),) ,onPressed: (){FavoritePreferences.setPicks([]);},),
      ),
      body: FutureBuilder(
          future:  fetchData(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.data==null) {
              return Center(child: CircularProgressIndicator());
            }
            else{
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    List<Pick> picks = snapshot.data;
                    return Dismissible(
                      background:  Padding(
                        padding: const EdgeInsets.fromLTRB(20,0,0,0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const <Widget>[
                            Icon(Icons.delete, color: Colors.red),
                            Text('Remove Pick',style: TextStyle(color: Colors.red),),
                          ],
                        ),
                      ),
                      secondaryBackground:  Padding(
                        padding: const EdgeInsets.fromLTRB(0,0,20,0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const <Widget>[
                            Icon(Icons.delete, color: Colors.red),
                            Text('Remove Pick',style: TextStyle(color: Colors.red),),
                          ],
                        ),
                      ),
                      key: Key(''),
                      onDismissed: (direction){
                        var snapshotData = snapshot.data[index];
                        snapshot.data.removeAt(index);
                        List<String>allPicks = FavoritePreferences.getPicks();
                        String newa = '';
                        int pickIndex = allPicks.indexWhere((pick) => pick.contains(snapshotData.homeLogo));
                        debugPrint((allPicks[pickIndex].split('*')[4].split('#').contains(snapshotData.player.toString()+'&'+snapshotData.goals.stat+'&'+'overUnder.'+snapshotData.goals.overUnder+'&'+snapshotData.goals.line)).toString());
                        if(allPicks[pickIndex].split('*')[4].split('#').contains(snapshotData.player.toString()+'&'+snapshotData.goals.stat+'&'+'overUnder.'+snapshotData.goals.overUnder+'&'+snapshotData.goals.line)){
                          debugPrint('here!!');
                          if(allPicks[pickIndex].split('*')[4].split('#').length==1){
                            debugPrint('ysese');
                            allPicks.removeAt(pickIndex);
                            FavoritePreferences.setPicks(allPicks);
                          }
                          else{
                            // debugPrint(allPicks[pickIndex].toString());
                            List<String> selPick = allPicks[pickIndex].split('*')[4].split('#');
                            // debugPrint(allPicks[pickIndex].toString());
                            debugPrint('here!');
                            selPick.remove(snapshotData.player.toString()+'&'+snapshotData.goals.stat+'&'+"overUnder."+snapshotData.goals.overUnder+'&'+snapshotData.goals.line);
                            for(int i=0;i<selPick.length;i++){
                              newa = newa+selPick[i];
                              if(i<selPick.length-1)newa = newa+'#';
                            }
                            allPicks[pickIndex]=allPicks[pickIndex].split('*')[0]+'*'+allPicks[pickIndex].split('*')[1]+'*'+allPicks[pickIndex].split('*')[2]+'*'+allPicks[pickIndex].split('*')[3]+'*'+newa;
                          }
                          debugPrint(allPicks[pickIndex].toString());
                          FavoritePreferences.setPicks(allPicks);
                        }
                      },
                      child: snapshot.data.length>index ?
                      Padding(
                          padding: EdgeInsets.fromLTRB(20,0,20,20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            elevation: 3,
                              child: Container(
                                // color:(int.parse(snapshot.data[index].goals.current)/(int.parse(snapshot.data[index].goals.line)+1) >= 1) ? Color(0xffeefbf2) : ( snapshot.data[index].gameStatus=='Finished' ? Color(0xfffef1f4) : Theme.of(context).scaffoldBackgroundColor),
                                padding: const EdgeInsets.fromLTRB(0, 0,0, 0),
                                child: Column(children: [
                                  Column(children: [
                                    ListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(snapshot.data[index].player.split(',')[1]+" "+snapshot.data[index].player.split(',')[2],style: TextStyle(fontWeight: FontWeight.w300 ,),),
                                          Container(
                                            decoration: BoxDecoration(
                                              // color: Colors.orange[50],
                                              borderRadius: BorderRadius.all(Radius.circular(20)
                                              )),
                                            child: Row(
                                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Image.network(snapshot.data[index].homeLogo,height: 25,width: 25,),
                                                Text('  vs  ',style: TextStyle(fontWeight: FontWeight.w100,fontSize: 15),),
                                                Image.network(snapshot.data[index].visitorLogo,height:25,width: 25,),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(15,0,10,5),
                                      child: Row(
                                        children: [Text(snapshot.data[index].goals.stat)],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(15,0,10,5),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children:[

                                          Text(capitalize(snapshot.data[index].goals.overUnder)+" "+snapshot.data[index].goals.line,style: TextStyle(fontWeight: FontWeight.w500),),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10,10,15,0),
                                            child: Row(
                                              children: [
                                                (snapshot.data[index].goals.percentage <1) ? Padding(
                                                  padding: snapshot.data[index].pickStatus==-1 ? const EdgeInsets.fromLTRB(0,0,10,0) : const EdgeInsets.fromLTRB(0,0,27,0),
                                                  child: Text(snapshot.data[index].goals.current+" / "+(int.parse(snapshot.data[index].goals.line)+1).toString(),style: snapshot.data[index].gameStatus=='Finished' ? TextStyle(color: Colors.black26) : TextStyle(),),
                                                ) : Icon(Icons.check_circle,color: Color(0xff42c256),size: 17,),
                                                snapshot.data[index].pickStatus==-1 ? Icon(Icons.cancel,color: Color(0xfff0506e),size: 17,) : Container(),
                                              ],
                                            ),
                                          )
                                        ]
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                      child: LinearProgressIndicator(
                                        value: snapshot.data[index].goals.percentage,
                                        color: snapshot.data[index].pickStatus==-1 ? Color(0xfff0506e) : Color(0x7742c256),
                                        backgroundColor: Color(0x1142c256),
                                      ),
                                    ),
                                  ]),
                                ]),
                              ),),
                        ) : Container(),
                    );
                  },
                ),
              );}
          }),
    );
  }
  String capitalize(String value) {
    var result = value[0].toUpperCase();
    bool cap = true;
    for (int i = 1; i < value.length; i++) {
      if (value[i - 1] == " " && cap == true) {
        result = result + value[i].toUpperCase();
      } else {
        result = result + value[i];
        cap = false;
      }
    }
    return result;
  }
}
