import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/favorite_prefs.dart';
import 'package:flutter_project/notification.dart';
import 'package:flutter_project/picks_prefs.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:numberpicker/numberpicker.dart';

class AddPickPage extends StatefulWidget {
  const AddPickPage({Key? key,required this.player, required this.match}) : super(key: key);
  final match;
  final player;

  @override
  State<AddPickPage> createState() => _AddPickPageState();
}

enum overUnder { over , under }

class _AddPickPageState extends State<AddPickPage> {
  var _dbSelection = 'Points';
  final _dbOptions = ['Points', 'Rebounds', 'Assists', 'Three Pointers'];
  var _lineSelection = 10;

  overUnder? _ouSelection = overUnder.over;

  var match;
  var player;
  bool canVibrate = false;

  @override
  void initState() {
    super.initState();
    match = widget.match;
    player = widget.player;
    _checkIfVibrate();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add a pick for ' + player[3]),),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
          child: ListView(
            children: [
              Container(height: 30,),
              Container(height: 1, color: Colors.grey[300],),
              Container(height: 30,),
              Text('Select a statistic:',
                style: TextStyle(fontWeight: FontWeight.w500),),
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
              Container(height: 1, color: Colors.grey[300],),
              Container(height: 30,),
              Text('Select over/under:',
                style: TextStyle(fontWeight: FontWeight.w500),),
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
              Container(height: 1, color: Colors.grey[300],),
              Container(height: 30,),
              Text(
                'Select line:', style: TextStyle(fontWeight: FontWeight.w500),),
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
                    onChanged: (int? value) {
                      setState(() {
                        _lineSelection = value!;
                      });
                    }),
              ),
              Container(height: 30,),
              Container(height: 1, color: Colors.grey[300],),
              Container(height: 30,),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  elevation: 3,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            children: [
                              Row(
                                  children: [
                                    Text(player[3], style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),),
                                  ]
                              ),
                              Container(height: 15,),
                              Row(
                                  children: [
                                    Text(_dbSelection + ":  "),
                                    _ouSelection == overUnder.over ? Text(
                                        'Over' + " " +
                                            _lineSelection.toString()) : Text(
                                        'Under' + " " +
                                            _lineSelection.toString()),
                                  ]
                              ),
                            ]),
                        Column(
                          children: [ElevatedButton(onPressed: () {
                            addPick(match, player);
                            // Vibration.vibrate();
                            _getVibration(FeedbackType.success);
                          },
                              child: Icon(Icons.add,))
                          ],
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

  void addPick(match, player) async {
    String headshot = ('https://cdn.nba.com/headshots/nba/latest/1040x760/${player[14]
        .toString()}.png');
    addToList(Pick(
        match["gameId"],
        '',
        '',
        false,
        '',
        match["gameTimeUTC"],
        0,
        player[14].toString(),
        player[3],
        headshot,
        'https://cdn.nba.com/logos/nba/${match["homeTeam"]["teamId"]
            .toString()}/global/L/logo.svg',
        'https://cdn.nba.com/logos/nba/${match["awayTeam"]["teamId"]
            .toString()}/global/L/logo.svg',
        false,
        false,
        Goal(_dbSelection, _ouSelection.toString().split('.')[1],
            _lineSelection.toString(), 0.toString())));
    // debugPrintAllPicks();
    // var list = await getList();
    // debugPrintAllPicks();
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
