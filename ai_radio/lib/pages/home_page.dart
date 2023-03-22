import 'package:ai_radio/utils/ai_util.dart';
import 'package:alan_voice/alan_voice.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:audioplayer/audioplayer.dart'; 
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:ai_radio/model/radio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const routeName = '/homePage';
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List <MyRadio> radios;

  //below variables are required for the audio player
  late MyRadio _selectedRadio; 
  Color ? _selectedColor;
  bool _isPlaying = false;
  final sugg = [
    "Play",
    "Stop",
    "Play rock music",
    "Play 97.1 FM",
    "Play next",
    "Pause",
    "Play previous",
    "Play pop music"
  ];

  final AudioPlayer _audioPlayer = AudioPlayer(); //accessing the AudioPlayer library


  @override
  void initState() {
    super.initState();
    setupAlan();
    fetchRadios();

    _audioPlayer.onPlayerStateChanged.listen((event){
      if(event == AudioPlayerState.PLAYING){
        _isPlaying = true;
      }
      else{
        _isPlaying = false;
      }
      setState(() { });
    });
  }

  setupAlan(){
    AlanVoice.addButton(
        "9177017878aca8a497d35f1cf9e869be2e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }
  _handleCommand(Map<String,dynamic> response){
      switch (response["command"]){
        case "play":  //play call karne ke baad Alan function ko call karega.
                      //lekin first time me error ayega kyuki pehle radio set nahi hota hai.
            _playMusic(_selectedRadio.url);
          break;
        
        case "play_channel":
            final id = response["id"];
            _audioPlayer.pause();
            MyRadio newRadio = radios.firstWhere((element) => element.id == id);
            radios.remove(newRadio);  
            radios.insert(0,newRadio); 
            _playMusic(newRadio.url);
          break;

        case "stop":
            _audioPlayer.stop();
          break;
        case "next":
            final index = _selectedRadio.id;
            MyRadio newRadio;
            if(index+1>radios.length){ //agar jo play ho raha hai vo last element hoga toh
              newRadio = radios.firstWhere((element) => element.id==1);
              radios.remove(newRadio);  // ye karne se list rebuild ho jayegi aur page bhi change hoga.
              radios.insert(0,newRadio); 
            }
            else{  //agar jo play ho raha hai vo last chodkar koi bhi element hoga toh.
              newRadio = radios.firstWhere((element) => element.id==index+1);
              radios.remove(newRadio);  
              radios.insert(0,newRadio); 
            }
            _playMusic(newRadio.url);
          break;
        case "prev":
            final index = _selectedRadio.id;
            MyRadio newRadio;
            if(index - 1 <= 0){ //agar jo play ho raha hai vo last element hoga toh
              newRadio = radios.firstWhere((element) => element.id==1);
              radios.remove(newRadio);  // ye karne se list rebuild ho jayegi aur page bhi change hoga.
              radios.insert(0,newRadio); 
            }
            else{  //agar jo play ho raha hai vo last chodkar koi bhi element hoga toh.
              newRadio = radios.firstWhere((element) => element.id==index - 1);
              radios.remove(newRadio);  
              radios.insert(0,newRadio); 
            }
            _playMusic(newRadio.url);
          break;
        default:
          print("Command was ${response["command"]}");
          break;
      }
  }
  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios[0];
    _selectedColor = Color(int.parse(_selectedRadio.color));
    print(radios);
    setState(() { });
  }

  _playMusic(String url){
    _audioPlayer.play(url);
    _selectedRadio = radios.firstWhere((element) => element.url == url);
    print(_selectedRadio.name);
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:  Drawer(
        child: Container(
          color: _selectedColor?? AIColors.primaryColor2,
          child: radios != null ?
          [
            70.heightBox,
            "All Channels".text.xl.white.semiBold.make().px16(),
            20.heightBox,
            ListView(
              padding: Vx.m0,
              shrinkWrap: true,
              children: radios.map((e) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(e.icon),
                ),
                title: "${e.name} FM".text.white.make(),
                subtitle: e.tagline.text.white.make(),
              )).toList(),
            ).expand()
          ].vStack(crossAlignment: CrossAxisAlignment.start)
          :const Offstage(),
        ),

      ),
      body: Stack(fit: StackFit.expand,children:[ //Stackfit.expand centered the images
        VxAnimatedBox()
        .size(context.screenWidth, context.screenHeight)
        .withGradient(
          LinearGradient(
            colors:[
              AIColors.primaryColor2,
              _selectedColor ?? AIColors.primaryColor1,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )
        .make(),
      [
        AppBar(
        title: "AI Radio".text.xl4.bold.white.make().shimmer(
          primaryColor: Vx.purple300,
          secondaryColor: Colors.white,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          centerTitle: true,
        ).h(100.0).p16(),
        "Start with - Hey Alan".text.italic.semiBold.white.make(),
        10.heightBox,
        VxSwiper.builder(
          itemCount: sugg.length,
          height: 50.0, 
          viewportFraction: 0.35, //labels ko paas me lekar aayega
          autoPlay: true,
          autoPlayAnimationDuration: 3.seconds,
          autoPlayCurve: Curves.linear,
          enableInfiniteScroll: true,
          itemBuilder: (context, index) {
            final s = sugg[index];
            return Chip(
              label: s.text.make(),
              backgroundColor: Vx.randomColor,
              );
          },
        ) 
      ].vStack(),
      30.heightBox,
        // ignore: unnecessary_null_comparison
        radios!=null? 
          VxSwiper.builder(
          itemCount: radios.length, 
          aspectRatio: 1.0,
          enlargeCenterPage: true, //selected one gets the bigger height
          onPageChanged: (index) {
            _selectedRadio = radios[index];
            final colorHex = radios[index].color;
            _selectedColor = Color(int.parse(colorHex));
            setState(() {});
          },
          itemBuilder: (context, index) {
              final rad = radios[index];

              return VxBox(
                child: ZStack([
                  Positioned(
                    top: 0.0,
                    right: 0.0,
                    child: VxBox(  // Categories label text at the bottom right corner is placed
                      child:rad.category.text.uppercase.white.make().px16(), 
                    )
                    .height(40)
                    .black
                    .alignCenter
                    .withRounded(value: 10.0)
                    .make(),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VStack([
                      rad.name.text.xl3.white.bold.make(),
                      5.heightBox,
                      rad.tagline.text.sm.white.semiBold.make(),
                    ],
                      crossAlignment: CrossAxisAlignment.center,
                    )
                  ),
                  Align(     // alignment for creating a button
                    alignment: Alignment.center,
                    child: [ Icon(     
                      size: 50,
                      CupertinoIcons.play_circle,
                      color: Colors.white,
                    ),
                    10.heightBox,
                    "Double tap to play".text.gray300.make(),
                    ].vStack()
                  )
                ])
              )
              .clip(Clip.antiAlias)  // category label ka extra part jo border ke bahar ja raha tha vo border ki bahar ka clip ho jayega
              .bgImage(DecorationImage(
                image: NetworkImage(rad.image),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3), BlendMode.darken)
              ))
              .border(color: Colors.black,width:5.0)
              .withRounded(value: 60.0) //make rounded corners
              .make()
              .onInkDoubleTap(() {
                _playMusic(rad.url); // double click karne par dusra radio play hoga.
              })
              .p16();
              // .centered(); //padding
            },
          ).centered() 
          : const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.white,
            ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if(_isPlaying)
                "Playing Now - ${_selectedRadio.name} FM".text.white.makeCentered(),
              Icon(
                _isPlaying ? CupertinoIcons.stop_circle:CupertinoIcons.play_circle,

                color: Colors.white,
                size: 65.0,
                ).onInkTap(() {
                  if(_isPlaying){
                    _audioPlayer.stop(); // single tap par play and pause hoga
                  }else{
                    _playMusic(_selectedRadio.url);
                  }
                })
            ].vStack(),
            ).pOnly(bottom: context.percentHeight*12)
        ],
      ),
    );
  }
}