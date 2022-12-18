import 'package:flutter/material.dart';
import 'package:flutter_project/favorites.dart';
import 'package:flutter_project/home_page.dart';
import 'package:flutter_project/my_picks_page.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/palette.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritePreferences.init();
  runApp(const MyApp());
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
