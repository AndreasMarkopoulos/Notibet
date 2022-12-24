import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class Pick {
  String gameId;
  String gameStatus;
  String period;
  bool isPeriodActive;
  String clock;
  String startDate;
  String playerId;
  String firstname;
  String lastname;
  String headshot;
  String homeLogo;
  String visitorLogo;
  bool isNotificationEnabled;
  bool isPinned;
  Goal goals;

  Pick(this.gameId, this.gameStatus,this.period,this.isPeriodActive,this.clock, this.startDate, this.playerId, this.firstname,this.lastname,this.headshot, this.homeLogo, this.visitorLogo,this.isNotificationEnabled,this.isPinned,this.goals);

  int get pickStatus {
    int status;
    if(goals.overUnder=='over'){
      status = gameStatus != 'Finished' ? 0 : (goals.percentage < 1 ? -1 : 1);
    }
    else{
      status = goals.percentage > 1 ? -1 : (gameStatus == 'Finished' ? 1 : 0);
    }
    return status;
  }

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'gameStatus': gameStatus,
    'period': period,
    'isPeriodActive': isPeriodActive,
    'clock': clock,
    'startDate': startDate,
    'playerId': playerId,
    'firstname': firstname,
    'lastname': lastname,
    'headshot': headshot,
    'homeLogo': homeLogo,
    'visitorLogo': visitorLogo,
    'isNotificationEnabled': isNotificationEnabled,
    'isPinned': isPinned,
    'goals': goals.toJson(),
  };

  static Pick fromJson(Map<String, dynamic> json) => Pick(
    json['gameId'],
    json['gameStatus'],
    json['period'],
    json['isPeriodActive'],
    json['clock'],
    json['startDate'],
    json['playerId'],
    json['firstname'],
    json['lastname'],
    json['headshot'],
    json['homeLogo'],
    json['visitorLogo'],
    json['isNotificationEnabled'],
    json['isPinned'],
    Goal.fromJson(json['goals']),
  );
}

class Goal {
  String stat;
  String overUnder;
  String line;
  String current = '0';

  Goal(this.stat,this.overUnder, this.line, this.current);

  double get percentage {
    return int.parse(current) / (int.parse(line) + 1);
  }

  Map<String, dynamic> toJson() => {
    'stat': stat,
    'overUnder': overUnder,
    'line': line,
    'current': current,
  };

  static Goal fromJson(Map<String, dynamic> json) => Goal(
    json['stat'],
    json['overUnder'],
    json['line'],
    json['current'],
  );
}

Future<int> saveList(List<Pick> list) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Map<String, dynamic>> jsonList =
  list.map((item) => item.toJson()).toList();
  String jsonString = jsonEncode(jsonList);
  prefs.setString('my_list', jsonString);
  return 1;
}

Future<List<Pick>> getList() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('my_list');
  if (jsonString == null) {
    return [];
  }
  List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList.map((item) => Pick.fromJson(item)).toList();
}

void addToList(Pick pick) async {
  List<Pick> list = await getList();
  list.add(pick);
  saveList(list);
}

Future<void> debugPrintAllPicks() async {
  List<Pick> list = await getList();
  for (int i = 0; i < list.length; i++) {
    debugPrint('--------------------------');
    Pick pick = list[i];
    debugPrint('Pick $i:');
    debugPrint('--------------------------');
    debugPrint('gameId: ${pick.gameId}');
    debugPrint('gameStatus: ${pick.gameStatus}');
    debugPrint('startDate: ${pick.startDate}');
    debugPrint('period: ${pick.period}');
    debugPrint('isPeriodActive: ${pick.isPeriodActive.toString()}');
    debugPrint('clock: ${pick.clock}');
    debugPrint('playerId: ${pick.playerId}');
    debugPrint('firstname: ${pick.firstname}');
    debugPrint('lastname: ${pick.lastname}');
    debugPrint('headshot: ${pick.headshot}');
    debugPrint('homeLogo: ${pick.homeLogo}');
    debugPrint('visitorLogo: ${pick.visitorLogo}');
    debugPrint('isNotificationEnabled: ${pick.isNotificationEnabled.toString()}');
    debugPrint('isPinned: ${pick.isPinned.toString()}');
    debugPrint('goals: ${pick.goals}');
    debugPrint('   stat: ${pick.goals.stat}');
    debugPrint('   overUnder: ${pick.goals.overUnder}');
    debugPrint('   line: ${pick.goals.line}');
    debugPrint('--------------------------');
  }
}
