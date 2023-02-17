import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:system_theme/system_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  SystemTheme.accentColor;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = SystemTheme.accentColor.accent;

    return MaterialApp(
      title: 'Cable',
      theme: ThemeData(
        colorSchemeSeed: accentColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Cable View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TextEditingController _crfContoller = TextEditingController(text: 'K10E0180013');

  String crf = 'K10E0180013';

  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.773972, -122.431297),
    zoom: 11.5,
  );

  late GoogleMapController _googleMapController;

  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    Geolocator.requestPermission();
    loadMarkers();
  }

  List<Marker> _markers = [];

  String getImage(String crf) {
    return "http://spbhss.live/CableCard/cable/$crf.jpg";
  }

  String capitalize(String s) {
    List<String> names = s.replaceAll(".", " ").split(" ");
    String returnName = "";
    for(String name in names){
      if (name.length>1){
        returnName = returnName + name[0].toUpperCase() + name.substring(1).toLowerCase()+ " ";
      }else{
        returnName = returnName + name + " ";
      }
    }
    return returnName;
  }

  LatLng currentPosition = LatLng(11.1795878, 75.9271907);

  void loadMarkers() async {
    String data = await DefaultAssetBundle.of(context).loadString("assets/location.json");
    List<dynamic> locations = json.decode(data);

    setState(() {
      _markers = locations.map((location) {

        return Marker(
          markerId: MarkerId(location['CRF'].toString()),
          position: LatLng(location['LAT'],location['LONG']),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                            width: 200,
                            height: 150,
                            child: ClipRRect(
                              child: Image.network(
                                getImage(location['CRF'].toString()),
                                errorBuilder: (context, error, stackTrace){
                                  return Icon(Icons.no_photography, size: 50,);
                                },

                              ),
                              borderRadius: BorderRadius.circular(30),
                            )),
                        Text(capitalize(location['CNAME']),style: TextStyle(fontSize: 25), ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {  },
                              icon: Column(
                                children: [
                                  Icon(Icons.call_outlined,size: 30,),
                                  Text("Call", )
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {  },
                              icon: Column(
                                children: [
                                  Icon(Icons.message_outlined,size: 30,),
                                  Text("Text", )
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {  },
                              icon: Column(
                                children: [
                                  Icon(Icons.directions_outlined,size: 30,),
                                  Text("Direction", )
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 20,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.only(left: 15, top: 15),
                                  child: Text("Costomer Info",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                                ),
                                ListTile(
                                  leading: Icon(Icons.call_outlined),
                                  title: Text(location['MOBILE'].toString()),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(onPressed: (){}, icon: Icon(Icons.message_outlined))
                                    ],
                                  ),
                                  onTap: (){},
                                ),
                                ListTile(
                                  leading: Icon(Icons.location_on_outlined),
                                  title:Container(
                                      child: Text("${location['LAT'].toString()},${location['LONG'].toString()}",
                                        overflow: TextOverflow.ellipsis,)
                                  ),
                                  subtitle: Text("Home"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(onPressed: (){}, icon: Icon(Icons.directions_outlined))
                                    ],
                                  ),
                                  onTap: (){},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                );
              },
            );
          },
        );
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,

      body:Stack(
        children:[
          GoogleMap(
            onMapCreated: _onMapCreated,
            zoomControlsEnabled: false,
            compassEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            initialCameraPosition: CameraPosition(
              target: currentPosition,
              zoom: 13.0,
            ),
            markers: Set.of(_markers),
          ),
          Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Container(
                  decoration: BoxDecoration(color: colors.surfaceVariant ,borderRadius: BorderRadius.circular(50)),
                  child: TextField(
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.search_rounded),
                      prefixIcon: Icon(Icons.person),
                      hintText: "CRF",
                      hintStyle: TextStyle(fontWeight: FontWeight.normal),
                      contentPadding: EdgeInsets.only(left: 15, top: 11),
                      border: InputBorder.none,
                    ),
                  )))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location,),
        onPressed: (){
        },
      ),
    );
  }
}
