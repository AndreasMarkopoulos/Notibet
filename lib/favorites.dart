import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'favorite_prefs.dart';
import 'package:flutter_project/favorite_prefs.dart';

import 'my_picks_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> favorites = [];

  Future<String> getId(String firstname,String lastname) async {
    String jsonString = await rootBundle.loadString('playersById.json');
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // Assuming the JSON file has an array of objects with the keys "name" and "id"
    List<dynamic> objects = jsonData['objects'];

    for (var object in objects) {
      if (object['firstname'] == firstname && object['lastname'] == lastname) {
        return object['id'];
      }
    }
    return 'not_found';
  }
  var ids;
  // var headshots;

  @override
  void initState(){
    favorites = FavoritePreferences.getFavorites() ?? [];
  }
  late Map<String, dynamic> fetchedFav;
  late List<dynamic> headshots;
  late List<dynamic> favs = [];
  Future<List<dynamic>> fetchFavoriteData() async {
    // for(var i = 0; i<favorites.length-1;i++){
    for(int i=0; i<favorites.length;i++){
      for(int i=0; i<favorites.length;i++){
        ids[i]=getId(favorites[i].split("*")[1], favorites[i].split("*")[2]);
        headshots[i]='https://cdn.nba.com/headshots/nba/latest/1040x760/${ids[i]}.png';
        debugPrint(headshots[i]);
      }
    }
    // }
    debugPrint(favs.toString());
    return headshots;
  }
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Favorite Players"),
      ),
      body: favorites.length <1 ? Center(
        child: Text("No players added to favorites", style: TextStyle(fontSize: 25,fontWeight: FontWeight.w300,color: Colors.grey),),
      ) : FutureBuilder(
        future:  fetchFavoriteData(),
    builder: (context, AsyncSnapshot snapshot) {
          return ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (BuildContext context, int index) {
                if(snapshot.data==null){
                  return Center(child: CircularProgressIndicator());
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.network(favorites[index].split("*")[3],height: 30,width: 30,),
                            Container(width: 20,),
                            Text(favorites[index].split("*")[1]+" "),
                            Text(favorites[index].split("*")[2]),
                            Text(snapshot.data[index])
                          ],
                        ),
                        GestureDetector(
                          onTap: (){
                            setState(() {
                              favorites.removeAt(index);
                              FavoritePreferences.setFavorites(favorites);
                              },
                            );
                            },
                          child: Icon(Icons.delete,color: Colors.orange[200],),
                        ),
                      ],
                    ),
                  ),
                );
              },);
        }
      )
    );}
}



