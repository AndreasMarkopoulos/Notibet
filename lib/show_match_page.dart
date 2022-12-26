import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'add_pick_page.dart';
import 'favorite_prefs.dart';
import 'my_picks_page.dart';

class ShowMatchPage extends StatefulWidget {
  const ShowMatchPage({Key? key,required this.teams,required this.match}) : super(key: key);
  final match;
  final Object teams;

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

  @override
  void initState() {
    super.initState();
    match = widget.match;
    teams = widget.teams;
  }
  List<String>? favorites = FavoritePreferences.getFavorites();
  late Map<String, dynamic> team1Data;
  late Map<String, dynamic> team2Data;
  late List<dynamic> team1;
  late List<dynamic> team2;
  Future<List<dynamic>> fetchSingleMatchData() async {
    final team1Data = await APIService().get(endpoint: '/players',
        query: {"team": teams["home"]["id"].toString(), "season": "2022"});
    final team1 = team1Data["response"];
    final team2Data = await APIService().get(endpoint: '/players',
        query: {"team": teams["visitors"]["id"].toString(), "season": "2022"});
    final team2 = team2Data["response"];
    var playersByTeam = [...team1, ...team2, team1.length];
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
              Text(teams["home"]["nickname"],style: TextStyle(fontWeight: FontWeight.w300),),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(teams["home"]["logo"],height: 20,width: 20,),
              ),
            ],
          ),
          Text("vs",style: TextStyle(color: Colors.orange[100],fontWeight: FontWeight.w300),),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(teams["visitors"]["logo"],height: 20,width: 20,),
              ),
              Text(teams["visitors"]["nickname"],style: TextStyle(fontWeight: FontWeight.w300),),
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
                      onTap: (){openOptionsModal(snapshot.data[index],snapshot.data[index]["id"],snapshot.data[index]["firstname"],snapshot.data[index]["lastname"],index,snapshot.data[snapshot.data.length-1]);},
                      child:Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                              child: index <  snapshot.data[snapshot.data.length-1] ? Image.network(teams["home"]["logo"],height: 35,width: 35,) : Image.network(teams["visitors"]["logo"],height: 35,width: 35,),
                            ),
                            SizedBox(width: 15),
                            Text(snapshot.data[index]["firstname"]+" "+snapshot.data[index]["lastname"],style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),),
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

  void openOptionsModal(Object player,id,firstname,lastname,index,homeTeamLength){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        height: 150,
        child: Scaffold(
          body: Container(
            color: Color(0xFF737373),
            height: 250,
            child: Container(
              child: _buildPlayerOptionsModal(player,id,firstname,lastname,index,homeTeamLength),
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10)
                )
              ),
            ),
          ),
        ),
      );
    });
  }

  Column _buildPlayerOptionsModal(player,id,firstname,lastname,index,homeTeamLength){
    return Column(
      children: [
        Padding(child: Text(player["firstname"]+" "+player["lastname"],style: TextStyle(fontSize: 15,),),padding: EdgeInsets.fromLTRB(0,10,0,10),),
        ListTile(
          leading: Icon(Icons.sports_basketball,color: Colors.orange[500],),
          title: Text('Add Pick'),
          onTap: () => _selectPlayer(player,match),
        ),
        ListTile(
          leading: Icon(Icons.star_border_rounded,color: Colors.amber,),
          title: Text('Add To Favorites'),
          onTap: () {
            addToFavorites(id, firstname, lastname, index, homeTeamLength);
          }),
      ],
    );
  }

  void _selectPlayer(Object player,match){
    // debugPrint(match.toString());
    Navigator.pop(context);
    setState(() {
      Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context)
      {
        return AddPickPage(player: player, match: match);
      }));
    });
  }

  void addToFavorites(id,firstname,lastname,index,homeTeamLength){
    favorites = FavoritePreferences.getFavorites();
    List<String> nonNullFavorites = favorites ?? [];
    // if(favorites==null) favorites = [];
    if(nonNullFavorites.contains(id.toString()+"*"+firstname+"*"+lastname+"*"+teams["home"]["logo"]) || nonNullFavorites.contains(id.toString()+"*"+firstname+"*"+lastname+"*"+teams["visitors"]["logo"])){
      final alreadyAdded = SnackBar(
        backgroundColor: Color(0xaa808080),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
            bottom: 105,
            right: 20,
            left: 20),
        content: Text('${firstname+" "+lastname} is already in your favorites'),
      );
      ScaffoldMessenger.of(context).showSnackBar(alreadyAdded);
    }
    else {
      List<String> nonNullFavorites = favorites ?? [];
      if(index <  homeTeamLength){
        setState(() {
          favorites?.add(id.toString()+"*"+firstname+"*"+lastname+"*"+teams["home"]["logo"]);
          FavoritePreferences.setFavorites(nonNullFavorites);
        });
      }
      else{
        setState(() {
          favorites?.add(id.toString()+"*"+firstname+"*"+lastname+"*"+teams["visitors"]["logo"]+"*"+teams["visitors"]["id"].toString());
          FavoritePreferences.setFavorites(nonNullFavorites);
        });
      }
      FavoritePreferences.setFavorites(nonNullFavorites);
      final favoriteAdded = SnackBar(
        backgroundColor: Color(0xaa69BD8D),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
            bottom: 105,
            right: 20,
            left: 20),
        content: Text('${firstname+" "+lastname} added to your favorites'),
      );
      ScaffoldMessenger.of(context).showSnackBar(favoriteAdded);

    }
  }
}
