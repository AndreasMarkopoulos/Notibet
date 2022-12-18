import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:numberpicker/numberpicker.dart';

class AddPickPage extends StatefulWidget {
  const AddPickPage({Key? key,required this.player, required this.match}) : super(key: key);
  final match;
  final Object player;

  @override
  State<AddPickPage> createState() => _AddPickPageState();
}

enum overUnder { over , under }

class _AddPickPageState extends State<AddPickPage> {
  var _dbSelection = 'Points';
  final _dbOptions = ['Points','Rebounds','Assists','Three Pointers'];
  var _lineSelection = 10;

  overUnder? _ouSelection = overUnder.over;

  var match;
  var player;
  @override
  void initState() {
    super.initState();
    match = widget.match;
    player = widget.player;
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add a pick for '+ player["firstname"]+" "+player["lastname"]),),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10,20,10,10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10,20,10,0),
          child: ListView(
            children: [
              Container(height: 30,),
              Container(height: 1,color: Colors.grey[300],),
              Container(height: 30,),
              Text('Select a statitic:',style: TextStyle(fontWeight: FontWeight.w500),),
              Container(height: 10,),
              Container(
                decoration: BoxDecoration(color: Colors.grey[100]),
                child: DropdownButton(
                  underline: SizedBox(),
                  isExpanded: true,
                  value: _dbSelection,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _dbOptions.map((String items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text(items),
                    );
                  }).toList(),
                  // After selecting the desired option,it will
                  // change button value to selected value
                  onChanged: (newValue) {
                    setState(() {
                      _dbSelection = newValue!;
                    });
                  },
                ),
              ),
              Container(height: 30,),
              Container(height: 1,color: Colors.grey[300],),
              Container(height: 30,),
              Text('Select over/under:',style: TextStyle(fontWeight: FontWeight.w500),),
              Container(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Over'),
                  Radio(
                    value: overUnder.over,
                    groupValue: _ouSelection,
                    onChanged: (overUnder? value) {
                      setState(() {
                        _ouSelection = value;
                      });
                    },
                  ),
                  Container(width: 40,),
                  Text('Under'),
                  Radio(
                    value: overUnder.under,
                    groupValue: _ouSelection,
                    onChanged: (overUnder? value) {
                      setState(() {
                        _ouSelection = value;
                      });
                    },
                  ),
                ],
              ),
              Container(height: 30,),
              Container(height: 1,color: Colors.grey[300],),
              Container(height: 30,),
              Text('Select line:',style: TextStyle(fontWeight: FontWeight.w500),),
              Container(height: 10,),
              Center(
                child: NumberPicker(
                    minValue: 0,
                    maxValue: 50,
                    step: 1,
                    axis: Axis.horizontal,
                    value: _lineSelection,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                    onChanged: (int? value){setState(() {
                  _lineSelection = value!;
                });}),
              ),
              Container(height: 30,),
              Container(height: 1,color: Colors.grey[300],),
              Container(height: 30,),
              Padding(
                padding: EdgeInsets.fromLTRB(10,0,10,20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  elevation: 3,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(15, 15,15, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            children: [
                            Row(
                              children:[Text(player["firstname"]+" "+player["lastname"],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 15),),]
                            ),
                            Container(height: 15,),
                            Row(
                              children:[
                                Text(_dbSelection+":  "),
                                _ouSelection==overUnder.over ? Text('Over'+" "+_lineSelection.toString()) : Text('Under'+" "+_lineSelection.toString()),]
                            ),
                        ]),
                        Column(
                          children: [ElevatedButton(onPressed: (){addPick(match,player);},
                              child:Icon(Icons.add,) )],
                        ),
                      ],
                    ),

                  ),),
              )
            ],
          ),
        ),
      ),
    );
  }
  void addPick(match,player){
    var picks = FavoritePreferences.getPicks();
    if(picks==null) picks=[];
    bool matchExists=false;
    var matchIndex;
    picks.forEach((item) {
      if(item.contains(match["id"].toString())){
        matchExists = true;
        matchIndex=picks.indexOf(item);
      }
    });
    if(matchExists==false){
      picks.add(match["id"].toString()+'*'+match["date"]["start"]+"*"+match["teams"]["home"]["logo"]+"*"+match["teams"]["visitors"]["logo"]+'*'+player["id"].toString()+','+player["firstname"]+","+player["lastname"]+'&'+_dbSelection+"&"+_ouSelection.toString()+"&"+_lineSelection.toString());
    }
    else{
      if(!picks.contains(player["id"]))
      picks[matchIndex]=picks[matchIndex]+"#"+player["id"].toString()+','+player["firstname"]+","+player["lastname"]+'&'+_dbSelection+"&"+_ouSelection.toString()+"&"+_lineSelection.toString();

    }

    FavoritePreferences.setPicks(picks);
    debugPrint("PICKS!!!!"+picks.toString());
  }
}
