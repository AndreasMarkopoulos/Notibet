import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:flutter_project/palette.dart';
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
  @override
  void initState(){
    fetchMatchData();
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
            future:  fetchMatchData(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.data==null)
                return Center(child: CircularProgressIndicator());
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
                                return ShowMatchPage(teams: snapshot.data[index]["teams"],match: snapshot.data[index]);
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
                                                  Text(snapshot.data[index]["status"]["long"]!="Scheduled" ? snapshot.data[index]["status"]["long"] : (DateTime.parse(snapshot.data[index]["date"]["start"]).toLocal().toString().split(" ")[1].substring(0,5)+"\n"+DateTime.parse(snapshot.data[index]["date"]["start"]).toLocal().toString().split(" ")[0].substring(5,10).split('-')[1]+'-'+DateTime.parse(snapshot.data[index]["date"]["start"]).toLocal().toString().split(" ")[0].substring(5,10).split('-')[0] ),
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
                                                          child: Image.network(snapshot.data[index]["teams"]["home"]["logo"],height:25 ,width: 25,),
                                                        ),
                                                        Text(snapshot.data[index]["teams"]["home"]["name"],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
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
                                                          child: Image.network(snapshot.data[index]["teams"]["visitors"]["logo"],height:25 ,width: 25,),
                                                        ),
                                                        Text(snapshot.data[index]["teams"]["visitors"]["name"],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
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

