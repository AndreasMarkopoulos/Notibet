import 'dart:async';
import 'dart:convert';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:flutter_project/confirmationModal.dart';
import 'notification.dart';

int picksCount = 4;
int thisPicksCount = 3;

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

      for (int k = 0; k < playerData.length; k++) {
        for (int m = 0; m < liveGamePlayers.length; m++) {
          if (picksList[m].playerId == playerData[k]["player"]["id"].toString() && picksList[m].goals.stat == 'Points') {
              picksList[m].goals.current = playerData[k]["points"].toString();
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

  @override
  void initState() {
    createData();
    fetchData();
    Timer timer =
        Timer.periodic(Duration(seconds: 15), (Timer t) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          child: Text(
            'My Picks',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            saveList([]);
          },
        ),
      ),
      body: picksList.length <1 ? Center(
    child: Text("No picks added", style: TextStyle(fontSize: 25,fontWeight: FontWeight.w300,color: Colors.grey),),
    ) :  FutureBuilder(
          future: fetchData(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }
            else {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    List<Pick> picks = snapshot.data;
                    return snapshot.data.length > index
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              elevation: 3,
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: Column(children: [
                                  Container(
                                    color: Color(0x11686b70),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                                          child: Row(
                                            children: [
                                              snapshot.data[index].pickStatus==0 ?
                                              GestureDetector(
                                                onTap: () {
                                                  snapshot.data[index].isNotificationEnabled = !snapshot.data[index].isNotificationEnabled;
                                                  saveList(snapshot.data);
                                                  setState(() {});
                                                },
                                                child: !snapshot.data[index]
                                                        .isNotificationEnabled
                                                    ? Icon(
                                                        Icons.notifications_none_outlined,
                                                        color: Color(0xff686b70),
                                                        size: 20,
                                                      )
                                                    : Icon(
                                                        Icons.notifications_active,
                                                        color: Color(0xfff2d03b),
                                                        size: 20,
                                                      ),
                                              )
                                                  : Container(height: 20,),

                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: (){
                                                _dialogBuilder(context,snapshot.data,index);
                                                // snapshot.data.removeAt(index);
                                                // saveList(snapshot.data);
                                                // debugPrintAllPicks();
                                                // setState(() {});
                                                // debugPrint(picksList.toString());
                                              },
                                              child: Icon(Icons.cancel_outlined,color: Color(0xff686b70),
                                                size: 17,),
                                            ),
                                            Container(width: 6,)
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Container(
                                  //   height: 1,
                                  //   color: Colors.black12,
                                  // ),
                                  Column(children: [
                                    ListTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    snapshot.data[index]
                                                        .headshot),
                                                backgroundColor: Colors.white,
                                              ),
                                              Container(
                                                width: 10,
                                              ),
                                              Text(
                                                snapshot.data[index]
                                                        .firstname +
                                                    " " +
                                                    snapshot
                                                        .data[index].lastname,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                // color: Colors.orange[50],
                                                borderRadius:
                                                    BorderRadius.all(
                                                        Radius.circular(20))),
                                            child: Row(
                                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Image.network(
                                                  snapshot
                                                      .data[index].homeLogo,
                                                  height: 25,
                                                  width: 25,
                                                ),
                                                Text(
                                                  '  vs  ',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      fontSize: 15),
                                                ),
                                                Image.network(
                                                  snapshot.data[index]
                                                      .visitorLogo,
                                                  height: 25,
                                                  width: 25,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(0, 0, 24, 5),
                                      child: snapshot
                                                  .data[index].gameStatus ==
                                              'In Play'
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(),
                                                Row(
                                                  children: [
                                                    DotsIndicator(
                                                      dotsCount: 4,
                                                      // position: double.parse(snapshot.data[index].period)+1,
                                                      position: double.parse(
                                                              snapshot
                                                                  .data[index]
                                                                  .period) -
                                                          1,
                                                      decorator:
                                                          DotsDecorator(
                                                        color: Colors
                                                            .black26, // Inactive color
                                                        activeColor: Colors
                                                            .redAccent[100],
                                                        spacing:
                                                            EdgeInsets.all(3),
                                                        size: Size.square(5),
                                                        activeSize:
                                                            Size.square(5),
                                                      ),
                                                    ),
                                                    snapshot.data[index]
                                                            .isPeriodActive
                                                        ? Text(' --',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .redAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))
                                                        : Text(
                                                            "  " +
                                                                snapshot
                                                                    .data[
                                                                        index]
                                                                    .clock
                                                                    .split(
                                                                        ":")[0] +
                                                                "'",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .redAccent,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          )
                                                  ],
                                                ),
                                              ],
                                            )
                                          : Container(),
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.black12,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 15, 10, 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            capitalize(snapshot.data[index]
                                                    .goals.overUnder) +
                                                " " +
                                                snapshot
                                                    .data[index].goals.line,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 0, 10, 5),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(snapshot
                                                .data[index].goals.stat),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 10, 15, 0),
                                              child: Row(
                                                children: [
                                                  (snapshot.data[index].goals.percentage < 1) ? Padding(padding: snapshot.data[index].pickStatus ==-1                                                              ? const EdgeInsets
                                                                      .fromLTRB(
                                                                  0, 0, 10, 0)
                                                              : const EdgeInsets
                                                                      .fromLTRB(
                                                                  0,
                                                                  0,
                                                                  27,
                                                                  0),
                                                          child: Text(
                                                            snapshot
                                                                    .data[
                                                                        index]
                                                                    .goals
                                                                    .current +
                                                                " / " +
                                                                (int.parse(snapshot
                                                                            .data[index]
                                                                            .goals
                                                                            .line) +
                                                                        1)
                                                                    .toString(),
                                                            style: snapshot
                                                                        .data[
                                                                            index]
                                                                        .gameStatus ==
                                                                    'Finished'
                                                                ? TextStyle(
                                                                    color: Colors
                                                                        .black26)
                                                                : TextStyle(),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.check_circle,
                                                          color: Color(
                                                              0xff42c256),
                                                          size: 17,
                                                        ),
                                                  snapshot.data[index]
                                                              .pickStatus ==
                                                          -1
                                                      ? Icon(
                                                          Icons.cancel,
                                                          color: Color(
                                                              0xfff0506e),
                                                          size: 17,
                                                        )
                                                      : Container(),
                                                ],
                                              ),
                                            )
                                          ]),
                                    ),
                                    SizedBox(
                                      height: 2,
                                      child: LinearProgressIndicator(
                                        value: snapshot
                                            .data[index].goals.percentage,
                                        color: snapshot.data[index].goals
                                                    .overUnder ==
                                                'over'
                                            ? (snapshot.data[index]
                                                        .pickStatus ==
                                                    -1
                                                ? Color(0xfff0506e)
                                                : Color(0x7742c256))
                                            : (snapshot.data[index]
                                                        .pickStatus ==
                                                    -1
                                                ? Color(0xfff0506e)
                                                : Color(0x77f2d700)),
                                        backgroundColor: Color(0x1142c256),
                                      ),
                                    ),
                                  ]),
                                ]),
                              ),
                            ),
                          )
                        : Container();
                  },
                ),
              );
            }
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

  List<Pick> rearrangePick(List<Pick> items, int index, String action) {
    // Make a copy of the original list
    List<Pick> newList = List.from(items);

    // Remove the item at the specified index from the list
    var item = newList.removeAt(index);

    if (action == 'pin') {
      // Insert the item at the front of the list
      newList.insert(0, item);
    } else if (action == 'unpin') {
      // Insert the item at the end of the list
      newList.add(item);
    }

    return newList;
  }


  Future<void> _dialogBuilder(BuildContext context,List<Pick> data,int index) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pick'),
          content: Text('This pick will be deleted: \n \n ${data[index].firstname+" "+data[index].lastname}\n ${capitalize(data[index].goals.overUnder)+" "+data[index].goals.line+" "+data[index].goals.stat}'),
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
                saveList(data);
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
