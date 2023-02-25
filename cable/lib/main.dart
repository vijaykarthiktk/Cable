
import 'package:cable/service/storage_service.dart';
import 'package:cached_firestorage/cached_firestorage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:system_theme/system_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

main() async {
  ErrorWidget.builder = (FlutterErrorDetails details){
    return Center(
      child: Text("${details.exception}"),
    );
  };
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
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorSchemeSeed: accentColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: accentColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
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
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  final TextEditingController _crfController = TextEditingController();
  final TextEditingController _cnameController = TextEditingController();
  final TextEditingController _chipIdController = TextEditingController();
  final TextEditingController _phoneCableController = TextEditingController();

  final TextEditingController _ispController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _phoneInternetController = TextEditingController();

  int _pageIndex = 0;

  List<Marker> _markersCable = [];
  List<Marker> _makerInternet = [];

  String crf = 'K10E0180013';


  LatLng currentPosition = const LatLng(11.1795878, 75.9271907);

  final List<String> _cnameCable = [];
  final List<String> _crfCable = [];
  final List<String> _phoneCable = [];

  final List<String> _nameInternet = [];
  final List<String> _userIDInternt = [];
  final List<String> _phoneInternt = [];


  @override
  initState() {
    super.initState();
    Geolocator.requestPermission();
    Geolocator.getCurrentPosition();
    getCurrentLocation();
    Firebase.initializeApp().whenComplete(() {
      loadMarkersCable();
      loadMarkerInternet();
    });
  }

  makeCall(String number){
    FlutterPhoneDirectCaller.callNumber(number);
  }
  openWhatapp(String number){
    String url = "whatsapp://send?phone=+91$number";
    launch(url);
  }
  static void navigateTo(double lat, double lng) async {
    var uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch ${uri.toString()}';
    }
  }
  updateStatus() async {

        await FirebaseFirestore.instance
            .collection('internet')
            .where('status', isEqualTo: 'STATUS')
            .get()
            .then((querySnapshot) {
          for (var element in querySnapshot.docs) {
            element.reference.update({
              'name': element['name'],
              'mobile': element['mobile'],
              'isp': element['isp'],
              'status': 'ACTIVE'
              // "date_time":DateFormat.jm().format(DateTime.now())
            })
            .whenComplete(() {
            });
          }
        });
    }

  getCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true);
    setState(() {
      lat = location.latitude;
      long = location.longitude;
    });
  }
  _onMapCreated(GoogleMapController controller) {
    getCurrentLocation();
  }

  createDataCable(String crf, String chipID, bool status, cname, int mobile, GeoPoint cords) async {
    await FirebaseFirestore.instance.collection("marker").doc("crf").set({
      'chipid': chipID,
      'status': status,
      'cname': cname,
      'mobile': mobile,
      "cords": cords,
    });
  }
  createDataInternet(String userID, String name, int phone, String isp, String mac, GeoPoint location) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    var mobile = androidInfo.model;
    if(_userIDInternt.contains(userID)){
        Get.snackbar("User Record Found", "");
    }else{
      await FirebaseFirestore.instance.collection("internet").add({
        'user_id': userID,
        'name': capitalize(name),
        'mobile': phone,
        'isp': isp.toUpperCase(),
        'mac':mac,
        'cords': location,
        'updated_by': mobile,
        'date_time': "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour % 12}:${DateTime.now().minute}"
      });
    }
  }

  loadMarkersCable() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('marker')
        .get(const GetOptions(source: Source.serverAndCache));
    var users = documentSnapshot.docs;
    XFile? image;

    final ImagePicker picker = ImagePicker();

    void getImagePath(ImageSource source, String crf) async {
      image = await picker.pickImage(
          source: source,
          preferredCameraDevice: CameraDevice.rear,
          requestFullMetadata: true,
          imageQuality: 85
      );
      if(image == null){
        Get.snackbar("No Image Selected", "");
      } else{
        final filePath = image?.path;
        final fileName = '$crf.jpg';
        final Storage storage = Storage();
        storage.uploadFileCable(fileName, filePath!, true).then((value){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded")));
        });
      }
    }

    setState(() {
      _markersCable = users.map((user) {
        double lat = (user['cords'] as GeoPoint).latitude;
        double long = (user['cords'] as GeoPoint).longitude;
        String crf = user['crf'].toString();
        String cname = user['cname'];
        bool status = user['status'];
        String mobile = user['mobile'].toString();
        _cnameCable.add(capitalize(cname));
        _crfCable.add(crf);
        _phoneCable.add(mobile);
        if(user.data().containsKey('date_time')){
          return Marker(
            markerId: MarkerId(crf),
            position: LatLng(lat, long),
            icon: status
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: capitalize(cname),
              snippet: crf,
              onTap: () {
                showGeneralDialog(
                  context: context,
                  pageBuilder: (ctx, a1, a2) {
                    return Container();
                  },
                  transitionBuilder: (BuildContext context, a1, a2, child) {
                    var curve = Curves.easeInOut.transform(a1.value);
                    return Transform.scale(
                      scale: curve,
                      child: Dialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                  width: 120,
                                  height: 160,
                                  child: GestureDetector(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: FutureBuilder(
                                        future: CachedFirestorage.instance.getDownloadURL(mapKey: crf, filePath: 'cable/$crf.jpg',),
                                        builder:(_ ,snapshot){
                                          if(snapshot.connectionState == ConnectionState.done){
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                snapshot.data!,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.no_photography_outlined,
                                                    size: 50,
                                                  );
                                                },
                                              ),
                                            );
                                          } else {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                        }
                                      ),
                                    ),
                                    onTap: () {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return SizedBox(
                                              height: 200,
                                              child: Padding(
                                                  padding: const EdgeInsets.all(18.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.spaceAround,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          getImagePath(
                                                              ImageSource.camera, crf);
                                                        },
                                                        icon: Column(
                                                          mainAxisSize:
                                                          MainAxisSize.min,
                                                          children: const [
                                                            Icon(
                                                              Icons.camera_alt_outlined,
                                                              size: 60,
                                                            ),
                                                            Text("Camera")
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          getImagePath(
                                                              ImageSource.gallery, crf);
                                                        },
                                                        icon: Column(
                                                          mainAxisSize:
                                                          MainAxisSize.min,
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .photo_library_outlined,
                                                              size: 60,
                                                            ),
                                                            Text("Gallary")
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  )),
                                            );
                                          });
                                    },
                                  )
                              ),
                              Text(
                                capitalize(cname),
                                style: const TextStyle(fontSize: 25),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      makeCall(mobile);
                                    },
                                    icon: Column(
                                      children: const [
                                        Icon(
                                          Icons.call_outlined,
                                          size: 30,
                                        ),
                                        Text(
                                          "Call",
                                        )
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      openWhatapp(mobile);
                                    },
                                    icon: Column(
                                      children: const [
                                        FaIcon(FontAwesomeIcons.whatsapp,size: 30,),
                                        Text(
                                          "WhatsApp",
                                        )
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      navigateTo(lat, long);
                                    },
                                    icon: Column(
                                      children: const [
                                        Icon(
                                          Icons.directions_outlined,
                                          size: 30,
                                        ),
                                        Text(
                                          "Direction",
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  SizedBox(
                                    width: 290,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      elevation: 0,
                                      color:
                                      Theme.of(context).colorScheme.surfaceVariant,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(
                                                left: 15, top: 15),
                                            child: const Text(
                                              "Customer Info",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.person_outline),
                                            title: Text(crf),
                                            onTap: () {},
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.call_outlined),
                                            title: Text(mobile),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                    onPressed: () {},
                                                    icon: const Icon(
                                                        Icons.message_outlined))
                                              ],
                                            ),
                                            onTap: () {},
                                          ),
                                          ListTile(
                                            leading:
                                            const Icon(Icons.location_on_outlined),
                                            title: Text(
                                              "${lat.toString()},${long.toString()}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: const Text("Home"),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                    onPressed: () {},
                                                    icon: const Icon(
                                                        Icons.directions_outlined))
                                              ],
                                            ),
                                            onTap: () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              )
                            ],
                          )
                      ),
                    );
                  },
                );
              },
            ),
          );
        }
        else{
          return Marker(markerId: MarkerId(user['crf']));

        }
      }).toList();
    });
  }
  loadMarkerInternet() async {
    // final String response = await rootBundle.loadString('assets/internet.json');
    // final users = await json.decode(response);

    final documentSnapshot = await FirebaseFirestore.instance.collection('internet').get(const GetOptions(source: Source.serverAndCache));
    var users = documentSnapshot.docs;
    setState(() {
      _makerInternet = users.map((user) {
        String userId = user['user_id'];
        String name = user['name'];
        int phone = user['mobile'];
        String status = user['status'];
        String isp = user['isp'];
        _nameInternet.add(name);
        _phoneInternt.add(phone.toString());
        _userIDInternt.add(userId);
        XFile? image;
        final ImagePicker picker = ImagePicker();

        void getImagePath(ImageSource source, String userId) async {
          image = await picker.pickImage(
              source: source,
              preferredCameraDevice: CameraDevice.rear,
              requestFullMetadata: true,
              imageQuality: 85
          );
          if(image == null){
            Get.snackbar("No Image Selected", "");
          } else{
            final filePath = image?.path;
            final fileName = '$userId.jpg';
            final Storage storage = Storage();
            storage.uploadFileCable(fileName, filePath!, false).then((value){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded")));
            });
          }
        }
        if(user.data().containsKey('cords')){
          GeoPoint location  = user['cords'];
          String mac  = user['mac'];
          return Marker(
              markerId: MarkerId(userId),
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                title: name.toString(),
                snippet: phone.toString(),
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    pageBuilder: (BuildContext context, a1, a2) {
                      return Container();
                    },
                    transitionBuilder: (ctx, a1, a2, child){
                      var curve = Curves.easeInOut.transform(a1.value);
                      return Transform.scale(
                        scale: curve,
                        child: Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                    width: 120,
                                    height: 160,
                                    child: GestureDetector(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: FutureBuilder(
                                            future: CachedFirestorage.instance.getDownloadURL(mapKey: userId, filePath: 'internet/$userId.jpg',),
                                            builder:(_ ,snapshot){
                                              if(snapshot.connectionState == ConnectionState.done){
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(
                                                    snapshot.data!,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.no_photography_outlined,
                                                        size: 50,
                                                      );
                                                    },
                                                  ),
                                                );
                                              } else {
                                                return const Center(child: CircularProgressIndicator());
                                              }
                                            }
                                        ),
                                      ),
                                      onTap: () {
                                        showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SizedBox(
                                                height: 200,
                                                child: Padding(
                                                    padding: const EdgeInsets.all(18.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.spaceAround,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            getImagePath(ImageSource.camera, userId,);
                                                          },
                                                          icon: Column(
                                                            mainAxisSize:
                                                            MainAxisSize.min,
                                                            children: const [
                                                              Icon(
                                                                Icons.camera_alt_outlined,
                                                                size: 60,
                                                              ),
                                                              Text("Camera")
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            getImagePath(
                                                                ImageSource.gallery, userId);
                                                          },
                                                          icon: Column(
                                                            mainAxisSize:
                                                            MainAxisSize.min,
                                                            children: const [
                                                              Icon(
                                                                Icons
                                                                    .photo_library_outlined,
                                                                size: 60,
                                                              ),
                                                              Text("Gallary")
                                                            ],
                                                          ),
                                                        )
                                                      ],
                                                    )),
                                              );
                                            });
                                      },
                                    )
                                ),
                                Text(
                                  capitalize(name),
                                  style: const TextStyle(fontSize: 25),
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        makeCall(phone.toString());
                                      },
                                      icon: Column(
                                        children: const [
                                          Icon(
                                            Icons.call_outlined,
                                            size: 30,
                                          ),
                                          Text(
                                            "Call",
                                          )
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        openWhatapp(phone.toString());
                                      },
                                      icon: Column(
                                        children: const [
                                          FaIcon(
                                            FontAwesomeIcons.whatsapp,
                                            size: 30,
                                          ),
                                          Text(
                                            "Text",
                                          )
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        navigateTo(location.latitude, location.longitude);
                                      },
                                      icon: Column(
                                        children: const [
                                          Icon(
                                            Icons.directions_outlined,
                                            size: 30,
                                          ),
                                          Text(
                                            "Direction",
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      width: 290,
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        elevation: 0,
                                        color:
                                        Theme.of(context).colorScheme.surfaceVariant,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.only(
                                                  left: 15, top: 15),
                                              child: const Text(
                                                "Customer Info",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            ListTile(
                                              leading:
                                              const Icon(Icons.wifi_password),
                                              title: Text(
                                                mac,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {},
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.person_outline),
                                              title: Text(userId),
                                              onTap: () {},
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.call_outlined),
                                              title: Text(phone.toString()),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                      onPressed: () {},
                                                      icon: const Icon(Icons.message_outlined))
                                                ],
                                              ),
                                              onTap: () {},
                                            ),
                                            ListTile(
                                              leading:
                                              const Icon(Icons.location_on_outlined),
                                              title: Text(
                                                "${location.latitude},${location.longitude}",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                      onPressed: () {},
                                                      icon: const Icon(Icons.directions_outlined))
                                                ],
                                              ),
                                              onTap: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            )
                        )
                      );
                    }
                  );
                },
              )
          );
        } else {
          return Marker(
            markerId:  MarkerId(userId)
          );
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Search"),
        actions: [
          IconButton(
              onPressed: (){
                if(_pageIndex == 0){
                  showSearch(context: context, delegate: DataSearchCable());
                } else{
                  showSearch(context: context, delegate: DataSearchInternet());}
                },
              icon: const Icon(Icons.search_rounded)
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            label: "Cable",
            selectedIcon: Icon(Icons.tv),
          ),
          NavigationDestination(
            icon: Icon(Icons.network_wifi_1_bar),
            label: "Internet",
            selectedIcon: Icon(Icons.network_wifi_rounded),
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
      resizeToAvoidBottomInset: false,
      body: <Widget>[
        GoogleMap(
              onMapCreated: _onMapCreated,
              mapToolbarEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(14,20),
              compassEnabled: true,
              cameraTargetBounds: CameraTargetBounds(LatLngBounds(
                  northeast: const LatLng(11.199369, 75.934386),
                  southwest: const LatLng(11.154130, 75.903564))),
              initialCameraPosition: CameraPosition(
                target: currentPosition,
                zoom: 13.0,
              ),
              markers: Set.of(_markersCable),
            ),
        GoogleMap(
          mapToolbarEnabled: false,
          cameraTargetBounds: CameraTargetBounds(LatLngBounds(
              northeast: const LatLng(11.199369, 75.934386),
              southwest: const LatLng(11.154130, 75.903564))),
          minMaxZoomPreference: const MinMaxZoomPreference(14,20),
          compassEnabled: true,
          markers: Set.of(_makerInternet),
          initialCameraPosition: CameraPosition(
            target: currentPosition,
            zoom: 13.0,
          ),
        ),
      ][_pageIndex],
      floatingActionButton: GestureDetector(
        onLongPress: (){
          if(_pageIndex ==0){
            loadMarkersCable();
          } else{
            loadMarkerInternet();
          }
        },
        child: FloatingActionButton(
          child: const Icon(
            Icons.add,
          ),
          onPressed: () {
            if(_pageIndex == 0 ){
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      _latController.text = lat.toString();
                      _longController.text = long.toString();
                      _cnameController.text = "";
                      _phoneCableController.text = "";
                      _crfController.text = "";
                      _chipIdController.text = "";
                      return AlertDialog(
                        title: const Text("New Form"),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            children: [
                              SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("CRF"),
                                    prefixIcon: const Icon(
                                      Icons.dns_outlined,)),
                                keyboardType: TextInputType.name,
                                controller: _crfController,
                              ),
                            ),
                              const SizedBox(
                                height: 10,),
                              SizedBox(
                                child: TextField(
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      label: const Text("Chip ID"),
                                      prefixIcon: const Icon(
                                        Icons.manage_accounts_outlined,)),
                                  keyboardType: TextInputType.name,
                                  controller: _chipIdController,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                child: TextField(
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      label: const Text("Name"),
                                      prefixIcon: const Icon(
                                          Icons.person_outline)),
                                  keyboardType: TextInputType.name,
                                  controller: _cnameController,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                child: TextField(
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      label: const Text("Phone"),
                                      prefixIcon: const Icon(
                                          Icons.phone_outlined)),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(10),
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  controller: _phoneCableController,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                child: TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      label: const Text("Latitude"),
                                  ),
                                  keyboardType:
                                  TextInputType.number,
                                  controller: _latController,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                child: TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            20),
                                      ),
                                      label:
                                      const Text("Longitude"),),
                                  keyboardType: TextInputType.number,
                                  controller: _longController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            onPressed: () {
                              updateDataCable(
                                  GeoPoint(
                                      double.parse(
                                          _latController.text),
                                      double.parse(
                                          _longController.text)),
                                  crf,
                                  _cnameController.text,
                                  int.parse(_phoneCableController.text));
                              Navigator.of(context).pop;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved")));
                            },
                            child: const Text("Save"),
                          ),
                        ],
                      );
                    });
            }
            else if(_pageIndex ==1){
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    _latController.text = lat.toString();
                    _longController.text = long.toString();
                    _nameController.text = "";
                    _phoneInternetController.text = "";
                    _userIDController.text = "";
                    _ispController.text = "";
                    _macController.text = "";
                    return AlertDialog(
                      title: const Text("New Form"),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                          MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("User ID"),
                                    prefixIcon: const Icon(
                                      Icons.manage_accounts_outlined,)),
                                keyboardType: TextInputType.name,
                                controller: _userIDController,
                              ),
                            ),//User ID
                            const SizedBox(
                              height: 10,),
                            SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("Name"),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,)),
                                keyboardType: TextInputType.name,
                                controller: _chipIdController,
                              ),
                            ),//Name
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("Phone"),
                                    prefixIcon: const Icon(
                                        Icons.phone_outlined)),
                                keyboardType: TextInputType.phone,
                                controller: _phoneInternetController,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                              ),
                            ),//Phone
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("ISP"),
                                    prefixIcon: const Icon(
                                        Icons.dns_outlined)),
                                keyboardType: TextInputType.name,
                                controller: _cnameController,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                              ),
                            ),//ISP
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              child: TextField(
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    label: const Text("MAC"),
                                    prefixIcon: const Icon(
                                        Icons.wifi_password_outlined)),
                                textCapitalization:TextCapitalization.characters,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(12),
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-F]'))
                                ],
                                controller: _macController,
                              ),
                            ),//MAC
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              child: TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                  ),
                                  label: const Text("Latitude"),
                                ),
                                keyboardType:
                                TextInputType.number,
                                controller: _latController,
                              ),
                            ),//Latitude
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              child: TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                  ),
                                  label:
                                  const Text("Longitude"),),
                                keyboardType: TextInputType.number,
                                controller: _longController,
                              ),
                            ),//Longitude
                          ],
                        ),
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Cancel"),
                        ),
                        FilledButton(
                          onPressed: () {
                            // createDataInternet(_userIDController.text, _nameController.text, _phoneInternetController.text.toString(), isp, mac, location);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  });
            }
            else{
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Wait")));
            }
          },
        ),
      ),
    );
  }
}

double lat = 0;
double long = 0;

updateDataCable(GeoPoint cords, String crf, String name, int phone) async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  var mobile = androidInfo.model;
  await FirebaseFirestore.instance
      .collection('marker')
      .where('crf', isEqualTo: crf)
      .get()
      .then((querySnapshot) {
    for (var element in querySnapshot.docs) {
      element.reference.update({
        'cords': cords,
        'cname': name.trim(),
        'mobile': phone,
        'date_time': "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour % 12}:${DateTime.now().minute}",
        'updated_by': mobile
        // "date_time":DateFormat.jm().format(DateTime.now())
      }).whenComplete(() {
        // print(querySnapshot.docs.asMap()['cname']);
      });
    }
  });
}

updateDateInternet(GeoPoint cords, String userID, String name, int phone, String isp, String mac, String isUdyami ) async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  var mobile = androidInfo.model;
  if(isp != 'BSNL'){
    await FirebaseFirestore.instance
        .collection('internet')
        .where('user_id', isEqualTo: userID)
        .get()
        .then((querySnapshot) {
      for (var element in querySnapshot.docs) {
        element.reference.update({
          'cords': cords,
          'name': name,
          'mobile': phone,
          'mac': mac,
          'isp': isp,
          'updated_by':mobile,
          'date_time': "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour % 12}:${DateTime.now().minute}"
          // "date_time":DateFormat.jm().format(DateTime.now())
        }).whenComplete(() {
        });
      }
    });
  } else{
    await FirebaseFirestore.instance
        .collection('internet')
        .where('user_id', isEqualTo: userID)
        .get()
        .then((querySnapshot) {
      for (var element in querySnapshot.docs) {
        element.reference.update({
          'cords': cords,
          'name': name,
          'mobile': phone,
          'mac': mac,
          'isp': isp,
          '_isUdyami':isUdyami == 'N'?false:true,
          'updated_by':mobile,
          'date_time': "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour % 12}:${DateTime.now().minute}"
          // "date_time":DateFormat.jm().format(DateTime.now())
        }).whenComplete(() {
        });
      }
    });
  }
}

String capitalize(String s) {
  List<String> names = s.replaceAll(".", " ").split(" ");
  String returnName = "";
  for (String name in names) {
    if (name.length > 1) {
      returnName =
          "$returnName${name[0].toUpperCase()}${name.substring(1).toLowerCase()} ";
    } else {
      returnName = "$returnName$name ";
    }
  }
  return returnName.trim();
}

class DataSearchCable extends SearchDelegate<String> {
  final TextEditingController _crfController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  final TextEditingController _cnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return[
      IconButton(
          onPressed: (){
            query = "";
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: (){
          close(context, "null");
        },
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        )
    );
  }

  @override
  Widget buildResults(BuildContext buildcontext) {
    return Builder(builder: (context) {
      Navigator.of(buildcontext).pop();
      return Visibility(visible: false,child: Text("Result"));
  
    });
  }

  @override
  Widget buildSuggestions(BuildContext buildContext) {
    return FutureBuilder(
        future:  FirebaseFirestore.instance.collection('marker').get(const GetOptions(source: Source.serverAndCache)),
        builder: ((context, snapshot){
          var users = snapshot.data?.docs;
          if(snapshot.connectionState == ConnectionState.done){
            if(snapshot.hasData){
              return ListView.builder(
                  itemCount: users?.length,
                  itemBuilder: (context, index){
                    return _buildListView(buildContext, users, index);
                  });
            } else{
              return const ListTile(title: Text("No Data Found"),);
            }
          } else{
            return const Center(child: CircularProgressIndicator(),);
          }
    }));
  }

  Widget _buildListView(context, users, index){
    if(users[index]['cname'].toString().toLowerCase().contains(query.toLowerCase()) ||
        users[index]['crf'].toString().toLowerCase().contains(query.toLowerCase()) ||
        users[index]['mobile'].toString().toLowerCase().contains(query.toLowerCase())){
      return ListTile(
        title: Text(capitalize(users[index]['cname'])),
        leading: SizedBox(
          width: 75,
          height: 100,
          child: FutureBuilder(
              future: CachedFirestorage.instance.getDownloadURL(mapKey: users[index]['crf'], filePath: 'cable/${users[index]['crf'].toString()}.jpg',),
              builder:(_ ,snapshot){
                if(snapshot.connectionState == ConnectionState.done){
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      snapshot.data!,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }
          ),
        ),
        subtitle: Text('${users[index]['crf']}\n${users[index]['mobile']}', style: const TextStyle(fontWeight: FontWeight.w100),),
        isThreeLine: true,
        onTap: (){
          double lat = (users[index]['cords'] as GeoPoint).latitude;
          double long = (users[index]['cords'] as GeoPoint).longitude;
          String crf = users[index]['crf'].toString();
          String cname = users[index]['cname'];
          String mobile = users[index]['mobile'].toString();
          Navigator.of(context).pop();
          showDialog(context: context, builder: (BuildContext context){
            _latController.text = lat.toString();
            _longController.text = long.toString();
            _cnameController.text = capitalize(cname);
            _phoneController.text = capitalize(mobile);
            _crfController.text = crf;
            return AlertDialog(
              title: const Text("Edit Form"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                  MainAxisAlignment.start,
                  children: [

                    const SizedBox(height: 10,),
                    SizedBox(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("CRF"),
                            prefixIcon: const Icon(
                              Icons.dns_outlined,)),
                        keyboardType: TextInputType.name,
                        controller: _crfController,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("Name"),
                            prefixIcon: const Icon(
                                Icons.person_outline)),
                        keyboardType: TextInputType.name,
                        controller: _cnameController,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("Phone"),
                            prefixIcon: const Icon(
                                Icons.phone_outlined)),
                        keyboardType: const TextInputType
                            .numberWithOptions(
                            decimal: false),
                        controller: _phoneController,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label:
                            const Text("Latitude"),
                            suffixIcon: IconButton(
                                onPressed: () async {
                                  Position data =
                                  await Geolocator.getCurrentPosition();
                                  const Duration(seconds: 1);
                                  _latController.text = data.latitude.toString();
                                  _longController.text = data.longitude.toString();
                                },
                                icon: const Icon(Icons
                                    .add_location_alt_outlined))),
                        keyboardType:
                        TextInputType.number,
                        controller:_latController
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label:
                            const Text("Longitude"),
                            suffixIcon: IconButton(
                                onPressed: () async {
                                  Position data =
                                  await Geolocator.getCurrentPosition();
                                  const Duration(seconds: 1);
                                  _longController.text = data.longitude.toString();
                                  _latController.text = data.latitude.toString();
                                },
                                icon: const Icon(Icons
                                    .add_location_alt_outlined))),
                        keyboardType:
                        TextInputType.number,
                        controller: _longController,
                      ),
                    ),

                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    updateDataCable(
                        GeoPoint(
                            double.parse(
                                _latController.text),
                            double.parse(
                                _longController.text)),
                        crf,
                        _cnameController.text,
                        int.parse(_phoneController.text));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved")));
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          });
        },
      );
    } else{
      return const SizedBox(height: 0,);
    }
  }

}

class DataSearchInternet extends SearchDelegate<String>{

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  final TextEditingController _ispController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _phoneInternetController = TextEditingController();
  final TextEditingController _isUdyamiController = TextEditingController(text: 'N');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return[
      IconButton(
          onPressed: (){
            query = "";
          },
          icon: const Icon(Icons.clear))
    ];
  }
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: (){
          close(context, "null");
        },
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        )
    );
  }
  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }
  @override
  Widget buildSuggestions(BuildContext buildContext) {
    return FutureBuilder(
        future:  FirebaseFirestore.instance.collection('internet').get(const GetOptions(source: Source.serverAndCache)),
        builder: ((context, snapshot){
          var users = snapshot.data?.docs;
          if(snapshot.connectionState == ConnectionState.done){
            if(snapshot.hasData){
              return ListView.builder(
                  itemCount: users?.length,
                  itemBuilder: (context, index){
                    return _buildListView(buildContext, users, index);
                  });
            } else{
              return const ListTile(title: Text("No Data Found"),);
            }
          } else{
            return const Center(child: CircularProgressIndicator(),);
          }
        }));
  }


  Widget _buildListView(context, users, index){
    if(users[index]['name'].toString().toLowerCase().contains(query.toLowerCase())||
    users[index]['mobile'].toString().contains(query.toLowerCase())){
      return ListTile(
        title: Text(capitalize(users[index]['name'])),
        leading: SizedBox(
          width: 75,
          height: 100,
          child: FutureBuilder(
              future: CachedFirestorage.instance.getDownloadURL(mapKey: users[index]['user_id'], filePath: 'internet/${users[index]['user_id'].toString()}.jpg',),
              builder:(_ ,snapshot){
                if(snapshot.connectionState == ConnectionState.done){
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      snapshot.data!,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }
          ),
        ),
        subtitle: Text("${users[index]['mobile'].toString()}\n${users[index]['user_id']}", style: const TextStyle(fontWeight: FontWeight.w100),),
        isThreeLine: true,
        onTap: (){
          try{
            lat = (users[index]['cords'] as GeoPoint).latitude;
            long = (users[index]['cords'] as GeoPoint).longitude;
            _latController.text = lat.toString();
            _longController.text = long.toString();
          } catch(e){
            _latController.text = lat.toString();
            _longController.text = long.toString();
          }
          String userId = users[index]['user_id'].toString();
          String name = users[index]['name'];
          String mobile = users[index]['mobile'].toString();
          String isp = users[index]['isp'];
          Navigator.of(context).pop();
          showDialog(context: context, builder: (BuildContext context){
            _nameController.text = capitalize(name);
            _phoneInternetController.text = capitalize(mobile);
            _ispController.text = isp;
            _userIDController.text = userId;
            _macController.text="";
            return AlertDialog(
              title: const Text("Edit Form"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                  MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,),
                    SizedBox(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("User ID"),
                            prefixIcon: const Icon(
                              Icons.dns_outlined,)),
                        keyboardType: TextInputType.name,
                        controller: _userIDController,
                      ),
                    ),//User ID
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("Name"),
                            prefixIcon: const Icon(
                                Icons.person_outline)),
                        keyboardType: TextInputType.name,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))
                        ],
                        controller: _nameController,
                      ),
                    ),//Name
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label: const Text("Phone"),
                            prefixIcon: const Icon(
                                Icons.phone_outlined)),
                        keyboardType: TextInputType.number,
                        controller: _phoneInternetController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                        ],
                      ),
                    ),//Phone
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                      20),
                                ),
                                label: const Text("ISP"),
                                prefixIcon: const Icon(
                                    Icons.dns_outlined)),
                            keyboardType: TextInputType.name,
                            controller: _ispController,
                          ),
                        ),
                        Visibility(
                            visible: _ispController.text == 'BSNL'?true:false,
                            child: const SizedBox(width: 10,)
                        ),
                        Visibility(
                          visible: _ispController.text == 'BSNL'?true:false,
                          child: SizedBox(
                            width: 80,
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: _isUdyamiController,
                              decoration: InputDecoration(
                                label: const Text('UDM'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))
                              ),
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[YN]')),
                                LengthLimitingTextInputFormatter(1)
                              ],
                            ),
                          ),
                        )
                      ],
                    ),//ISP
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            label: const Text("MAC"),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.camera_alt_outlined),
                              onPressed: () async {
                                final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode('#ff0000', 'Cancel', true, ScanMode.BARCODE);
                                if(barcodeScanRes == "-1"){
                                  _macController.text = '';
                                } else{
                                  _macController.text = barcodeScanRes;
                                }
                              },)
                        ),
                        keyboardType: TextInputType.number,
                        controller: _macController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(12),
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-F]'))
                        ],
                      ),
                    ),//MAC
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                              ),
                              label:
                              const Text("Latitude"),
                              suffixIcon: IconButton(
                                  onPressed: () async {
                                    Position data = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
                                    const Duration(seconds: 1);
                                    _latController.text = data.latitude.toString();
                                    _longController.text = data.longitude.toString();
                                  },
                                  icon: const Icon(Icons
                                      .add_location_alt_outlined))),
                          keyboardType:
                          TextInputType.number,
                          controller:_latController
                      ),
                    ),//Latitude
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  20),
                            ),
                            label:
                            const Text("Longitude"),
                            suffixIcon: IconButton(
                                onPressed: () async {
                                  Position data =
                                  await Geolocator.getCurrentPosition();
                                  const Duration(seconds: 1);
                                  _longController.text = data.longitude.toString();
                                  _latController.text = data.latitude.toString();
                                },
                                icon: const Icon(Icons
                                    .add_location_alt_outlined))),
                        keyboardType:
                        TextInputType.number,
                        controller: _longController,
                      ),
                    ),//Longitude
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    updateDateInternet(
                        GeoPoint(double.parse(_latController.text), double.parse(_longController.text)),
                        userId,
                        _nameController.text,
                        int.parse(_phoneInternetController.text),
                        _ispController.text,
                        _macController.text,
                      _isUdyamiController.text
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved")));
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          });
        },
      );
    } else{
      return const SizedBox(height: 0,);
    }
  }
}
