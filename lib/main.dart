import 'package:flutter/material.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var uri = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: uri,
            ),
            SizedBox(height: 40.0),
            PlayerWidget(audioUrl: uri.value.text,),
          ],
        ),
      ),
    );
  }
}

// TODO player widget has a play button that changes to stop button
// TODO progress bar for seeking through
class PlayerWidget extends StatefulWidget {
  String audioUrl;
  PlayerWidget({Key key, String audioUrl}) : super(key: key);

  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  AudioPlayer _player;
  Duration audioLength;
  Duration progress;
  double seekPercent;

  @override
  initState() {
    super.initState();
    seekPercent = 0.0;
  }

  // Playhead slider
  Widget seekSliderWidget({AudioPlayer player}){
    return AudioComponent(
      updateMe: [
        WatchableAudioProperties.audioPlayhead,
        WatchableAudioProperties.audioLength,
        WatchableAudioProperties.audioPlayhead,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        var curValue = player.position == null || player.audioLength == null ? 0.0 : player.position.inMilliseconds.toDouble();
        // TODO this slider only tracks song position
        // TODO implement seeking functionality
        return new Slider(
          // value: player.position == null || player.audioLength == null ? 0.0 : player.position.inMilliseconds.toDouble(),
          value: curValue,
          max: player.position == null || player.audioLength == null ? 1.0 : player.audioLength.inMilliseconds.toDouble(),
          onChanged: (double newSeekPercent) {
            // player.stop();
            player.pause();
            // setState((){
            //   // seekPercent = (val/max)*100;
            //   seekPercent = newSeekPercent;
            //   curValue = newSeekPercent;
            // });
            // final seekMillis = (player.audioLength.inMilliseconds * newSeekPercent).round();
            // print("#### SEEKMILLIS ${seekMillis}");
            // player.seek(new Duration(milliseconds: seekMillis));
            // player.play();
          },
        );
      },
    );
  }


  Widget buildSimplePlayWidget({AudioPlayer player}){
      // while loading
    Icon icon = Icon(Icons.watch_later, color: Colors.grey, size: 50.0);
    Function onPressed;

    // set player state 
    if (player.state == AudioPlayerState.playing) {
      icon = Icon(Icons.pause_circle_outline, color: Colors.deepOrangeAccent,size: 50.0);
      onPressed = player.pause;
    } else if (player.state == AudioPlayerState.paused) {
      icon = Icon(Icons.play_circle_outline, color: Colors.deepOrangeAccent, size: 50.0);
      onPressed = player.play;
    }


    return IconButton(
      icon: icon,
      onPressed: onPressed,
    );
  }

  // https://stackoverflow.com/questions/54775097/formatting-a-duration-like-hhmmss
  String _printDuration(Duration duration) {
        String twoDigits(int n) {
          if (n >= 10) return "$n";
          return "0$n";
        }

        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
        // return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
        return "$twoDigitMinutes:$twoDigitSeconds";
      }

  Widget buildTimer(){
    if(progress != null){
      return Text(_printDuration(progress));
    }
    return SizedBox(width: 50.0,child: LinearProgressIndicator());
  }

  // fast forward 10 seconds
  Widget buildForwardSeekWidget({AudioPlayer player}){
    Icon icon = Icon(Icons.fast_forward, color: Colors.deepOrangeAccent, size: 50.0);

    return IconButton(
      icon: icon,
      onPressed : (){
        var next = player.position + Duration(seconds: 10);
        player.seek(next);
      }
    );
  }

  Widget buildBackwardSeekWidget({AudioPlayer player}){
    Icon icon = Icon(Icons.fast_rewind, color: Colors.deepOrangeAccent, size: 50.0);
    var s = Duration(seconds: 10);

    return IconButton(
      icon: icon,
      onPressed : (){
        if(player.position - Duration(seconds: 10) > s){
          var next = player.position - Duration(seconds: 10);
          player.seek(next);
        }
      }
    );
  }

  // TODO keep track of song while ui is in background
  // https://api.flutter.dev/flutter/dart-ui/AppLifecycleState-class.html
  Widget buildSimplePlayer({String url}){
   return new Audio(
       audioUrl: 'https://api.soundcloud.com/tracks/405630381/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P',
      //  audioUrl: 'https://api.soundcloud.com/tracks/9540352/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P',
      playbackState: PlaybackState.paused, // initial playback state
      buildMe: [
        WatchableAudioProperties.audioSeeking,
        WatchableAudioProperties.audioLength,
        WatchableAudioProperties.audioPlayerState,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        // player.position = new Duration();
        double playbackProgress = 0.0;
        if (player.audioLength != null && player.position != null) {
          playbackProgress = player.position.inMilliseconds / player.audioLength.inMilliseconds;
        }

        seekPercent = player.isSeeking ? seekPercent : null;

        player.addListener(AudioPlayerListener(
          onAudioLengthChanged: (Duration audioLength) {
              setState(() {
                this.audioLength = audioLength;
                print("#### AUDIO LENGTH ${this.audioLength}");
              });
            }, 
          onPlayerPositionChanged: (Duration position) {
            setState(() {
              this.progress = position;
              var val = player.position.inMilliseconds.toDouble();
              var max = player.audioLength.inMilliseconds.toDouble();
              // print("#### VAL $val");
              // print("#### MAX $max");
              print("#### POSITION ${this.progress}");
              // print("#### SLIDER ${sliderValue}");
              print("#### SEEK PERCENT ${seekPercent}");
            });
          }));
      return Column(
        children: <Widget>[
          Row(children: <Widget>[
            buildBackwardSeekWidget(player: player),
            buildSimplePlayWidget(player: player),
            buildForwardSeekWidget(player: player),
          ]),
          Row(children: <Widget>[
            seekSliderWidget(player: player),
            buildTimer(),
          ]),
        ],
      );

     }
   );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Center(
       child: Column(
         children: <Widget>[
           Text("Song title"),
           buildSimplePlayer(),
         ],
       ),
    );
  }
}