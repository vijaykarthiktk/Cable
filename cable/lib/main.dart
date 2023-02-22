
import 'package:cable/service/storage_service.dart';
import 'package:cached_firestorage/cached_firestorage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:system_theme/system_theme.dart';
import 'package:mobile_number/mobile_number.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

main() async {
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

  late String _mobileNo;

  List<String> _cnameCable = [];
  List<String> _crfCable = [];
  List<String> _phoneCable = [];

  List<String> _nameInternet = [];
  List<String> _userIDInternt = [];
  List<String> _phoneInternt = [];


  @override
  initState() {
    // TODO: implement initState
    super.initState();
    Geolocator.requestPermission();
    Geolocator.getCurrentPosition();
    getCurrentLocation();
    MobileNumber.listenPhonePermission((isPermissionGranted) {
      if (isPermissionGranted) {
        initMobileNumberState();
      }
    });
    initMobileNumberState();
    Firebase.initializeApp().whenComplete(() {
      loadMarkersCable();
      loadMarkerInternet();
    });
  }

  initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return;
    }
    try {
      var mob = await MobileNumber.mobileNumber;
      setState(() {
        _mobileNo = mob!;
      });
    } on PlatformException catch (e) {
      setState(() {
        _mobileNo = "Not Found";
      });
    }
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
  ///Create New Record for Cable
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
    var mobile = await MobileNumber.mobileNumber ?? "";
    mobile = mobile.toString().substring(2, mobile.length);
    if(_userIDInternt.contains(userID)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Record Found")));
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
        .get(const GetOptions(source: Source.cache));
    var users = documentSnapshot.docs;
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
        XFile? image;

        final ImagePicker _picker = ImagePicker();

        void getImagePath(ImageSource source, String crf) async {
          image = await _picker.pickImage(
            source: source,
            preferredCameraDevice: CameraDevice.rear,
            requestFullMetadata: true,
            imageQuality: 90
          );
          if(image == null){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No Image Selectec")));
          } else{
            final filePath = image?.path;
            final fileName = '$crf.jpg';
            final Storage storage = Storage();
            storage.uploadFileCable(fileName, filePath!, true);
          }
        }

        try{
          var date_time = user['date_time'];
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
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
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
                                      future: CachedFirestorage.instance.getDownloadURL(mapKey: '10', filePath: 'cable/$crf.png',),
                                      builder:(_ ,snapshot){
                                        print(crf);
                                        if(snapshot.connectionState == ConnectionState.done){
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              snapshot.data!,
                                              errorBuilder: (context, error, stackTrace) {
                                                print(error);
                                                return const Icon(
                                                  Icons.no_photography_outlined,
                                                  size: 50,
                                                );
                                              },
                                            ),
                                          );
                                        } else {
                                          return Center(child: CircularProgressIndicator());
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
                                  onPressed: () {},
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
                                  onPressed: () {},
                                  icon: Column(
                                    children: const [
                                      Icon(
                                        Icons.message_outlined,
                                        size: 30,
                                      ),
                                      Text(
                                        "Text",
                                      )
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
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
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          _latController.text = lat.toString();
                                          _longController.text = long.toString();
                                          _cnameController.text = capitalize(cname);
                                          _phoneCableController.text = capitalize(mobile);
                                          return AlertDialog(
                                            title: const Text("Edit Location"),
                                            content: Column(
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
                                                    controller: _phoneCableController,
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
                                                        label: const Text("Latitude"),
                                                        suffixIcon: IconButton(
                                                            onPressed: () async {
                                                              Position data =
                                                              await Geolocator
                                                                  .getCurrentPosition();
                                                              const Duration(
                                                                  seconds: 1);
                                                              print(data.latitude);
                                                              setState(() {
                                                                _latController.text =
                                                                    data.latitude
                                                                        .toString();
                                                              });
                                                            },
                                                            icon: const Icon(Icons
                                                                .add_location_alt_outlined))),
                                                    keyboardType:
                                                    TextInputType.number,
                                                    controller: _latController,
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
                                                              await Geolocator
                                                                  .getCurrentPosition();
                                                              const Duration(
                                                                  seconds: 1);
                                                              print(data.longitude);
                                                              setState(() {
                                                                _longController.text =
                                                                    data.longitude
                                                                        .toString();
                                                              });
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
                                                      int.parse(
                                                          _phoneCableController.text));
                                                },
                                                child: const Text("Save"),
                                              ),
                                            ],
                                          );
                                        });
                                  },
                                  icon: Column(
                                    children: const [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 30,
                                      ),
                                      Text(
                                        "Edit",
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
                        ));
                  },
                );
              },
            ),
          );
        }
        catch(e){
          return Marker(markerId: MarkerId(user['crf']));

        }

      }).toList();
    });
  }
  ///Create InfoWindow For Internet Data
  loadMarkerInternet() async {
    // final String response = await rootBundle.loadString('assets/internet.json');
    // final users = await json.decode(response);

    final documentSnapshot = await FirebaseFirestore.instance
        .collection('internet')
        .get(GetOptions(source: Source.cache));
    var users = documentSnapshot.docs;
    setState(() {
      _makerInternet = users.map((user) {
        String user_id = user['user_id'];
        String name = user['name'];
        int phone = user['mobile'];
        String status = user['status'];
        String isp = user['isp'];
        _nameInternet.add(name);
        _phoneInternt.add(phone.toString());
        _userIDInternt.add(user_id);

        XFile? image;
        final ImagePicker _picker = ImagePicker();

        void getImagePath(ImageSource source, String crf) async {
          image = await _picker.pickImage(
              source: source,
              preferredCameraDevice: CameraDevice.rear,
              requestFullMetadata: true,
              imageQuality: 90
          );
          if(image == null){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No Image Selectec")));
          } else{
            final filePath = image?.path;
            final fileName = '$crf.jpg';
            final Storage storage = Storage();
            storage.uploadFileCable(fileName, filePath!, false).then((value){
              print(value);
            });
          }
        }

        try{
          String date_time = user['date_time'];
          String mac = user['mac']??"";
          GeoPoint location = user['cords'];
          return Marker(
              markerId: MarkerId(user_id),
              position: LatLng(location.longitude, location.latitude),
              infoWindow: InfoWindow(
                  title: name.toString(),
                  snippet: phone.toString(),
                  onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
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
                                          future: CachedFirestorage.instance.getDownloadURL(mapKey: '10', filePath: 'internet/$crf.png',),
                                          builder:(_ ,snapshot){
                                            print(crf);
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
                                              return Center(child: CircularProgressIndicator());
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
                                capitalize(name),
                                style: const TextStyle(fontSize: 25),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () {},
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
                                    onPressed: () {},
                                    icon: Column(
                                      children: const [
                                        Icon(
                                          Icons.message_outlined,
                                          size: 30,
                                        ),
                                        Text(
                                          "Text",
                                        )
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
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
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            _latController.text = lat.toString();
                                            _longController.text = long.toString();
                                            _cnameController.text = capitalize(name);
                                            _phoneCableController.text = capitalize(phone.toString());
                                            return AlertDialog(
                                              title: const Text("Edit Location"),
                                              content: Column(
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
                                                      controller: _phoneCableController,
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
                                                          label: const Text("Latitude"),
                                                          suffixIcon: IconButton(
                                                              onPressed: () async {
                                                                Position data =
                                                                await Geolocator
                                                                    .getCurrentPosition();
                                                                const Duration(
                                                                    seconds: 1);
                                                                print(data.latitude);
                                                                setState(() {
                                                                  _latController.text =
                                                                      data.latitude
                                                                          .toString();
                                                                });
                                                              },
                                                              icon: const Icon(Icons
                                                                  .add_location_alt_outlined))),
                                                      keyboardType:
                                                      TextInputType.number,
                                                      controller: _latController,
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
                                                                await Geolocator
                                                                    .getCurrentPosition();
                                                                const Duration(
                                                                    seconds: 1);
                                                                print(data.longitude);
                                                                setState(() {
                                                                  _longController.text =
                                                                      data.longitude
                                                                          .toString();
                                                                });
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
                                                        int.parse(
                                                            _phoneCableController.text));
                                                  },
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    icon: Column(
                                      children: const [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 30,
                                        ),
                                        Text(
                                          "Edit",
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
                                            title: Text(phone.toString()),
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
                          ));
                    },
                  );
                },

              )
          );
        }catch(e){
          return Marker(
              markerId: MarkerId(user_id),
              position: LatLng(11.1728978, 75.9205007),
              infoWindow:
              InfoWindow(title: name.toString(), snippet: phone.toString()));
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
        title: Text("Search"),
        actions: [
          IconButton(
              onPressed: (){
                if(_pageIndex == 0){
                  showSearch(context: context, delegate: DataSearchCable());
                } else{
                  showSearch(context: context, delegate: DataSearchInternet());
                }
                },
              icon: Icon(Icons.search_rounded)
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
          print(_pageIndex);
        },
      ),
      resizeToAvoidBottomInset: false,
      body: <Widget>[
        GoogleMap(
              onMapCreated: _onMapCreated,
              minMaxZoomPreference: MinMaxZoomPreference(14,20),
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
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
          cameraTargetBounds: CameraTargetBounds(LatLngBounds(
              northeast: const LatLng(11.199369, 75.934386),
              southwest: const LatLng(11.154130, 75.903564))),
          minMaxZoomPreference: MinMaxZoomPreference(14,20),
          liteModeEnabled: true,
          mapToolbarEnabled: false,
          myLocationEnabled: true,
          onMapCreated: _onMapCreated,
          compassEnabled: true,
          myLocationButtonEnabled: true,
          markers: Set.of(_makerInternet),
          // markers: {
          //   Marker(
          //       markerId: MarkerId("my_location"), position: LatLng(lat, long)),
          // },
          trafficEnabled: true,
          initialCameraPosition: CameraPosition(
            target: currentPosition,
            zoom: 13.0,
          ),
        ),
      ][_pageIndex],
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
        ),
        onPressed: () {
          // loadMarkerInternet();
          // uploadingData("Name","200",true, "SA", 99948, GeoPoint(1, 2));
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
                      title: const Text("Edit Location"),
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
                                int.parse(
                                    _phoneCableController.text));
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
                    title: const Text("Edit Location"),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please Wait")));
          }
        },
      ),
    );
  }
}

double lat = 0;
double long = 0;

updateDataCable(GeoPoint cords, String crf, String name, int phone) async {
  var mobile = await MobileNumber.mobileNumber ?? "";
  mobile = mobile.toString().substring(2, mobile.length);
  await FirebaseFirestore.instance
      .collection('marker')
      .where('crf', isEqualTo: crf)
      .get()
      .then((querySnapshot) {
    querySnapshot.docs.forEach((element) {
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
    });
  });
}

updateDateInternet(GeoPoint cords, String userID, String name, int phone, String isp, String mac) async {
  var mobile = await MobileNumber.mobileNumber ?? "";
  mobile = mobile.toString().substring(2, mobile.length);
  await FirebaseFirestore.instance
      .collection('internet')
      .where('user_id', isEqualTo: userID)
      .get()
      .then((querySnapshot) {
    querySnapshot.docs.forEach((element) {
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
    });
  });
}

String getImage(String crf){
  return "http://spbhss.live/CableCard/cable/$crf.jpg";
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

class DataSearchCable extends SearchDelegate<String>{
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
          icon: Icon(Icons.clear))
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
        future:  FirebaseFirestore.instance.collection('marker').get(const GetOptions(source: Source.cache)),
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
              return ListTile(title: Text("No Data Found"),);
            }
          } else{
            return Center(child: CircularProgressIndicator(),);
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
                  return Center(child: CircularProgressIndicator());
                }
              }
          ),
        ),
        subtitle: Text('${users[index]['crf']}\n${users[index]['mobile']}', style: TextStyle(fontWeight: FontWeight.w100),),
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

                    SizedBox(height: 10,),
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
                        int.parse(
                            _phoneController.text));
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          });
        },
      );
    } else{
      return SizedBox(height: 0,);
    }
  }

}

class DataSearchInternet extends SearchDelegate<String>{
  bool _isUdyami = false;

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  final TextEditingController _ispController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _phoneInternetController = TextEditingController();
  final ValueNotifier<bool> _checkboxValueNotifier = ValueNotifier<bool>(false);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return[
      IconButton(
          onPressed: (){
            query = "";
          },
          icon: Icon(Icons.clear))
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
        future:  FirebaseFirestore.instance.collection('internet').get(const GetOptions(source: Source.cache)),
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
              return ListTile(title: Text("No Data Found"),);
            }
          } else{
            return Center(child: CircularProgressIndicator(),);
          }
        }));
  }
  Widget _buildListView(context, users, index){
    if(users[index]['name'].toString().toLowerCase().contains(query.toLowerCase())){
      return ValueListenableBuilder<bool>(
        valueListenable:_checkboxValueNotifier,
        builder: (context, isChecked, child) {
          print(isChecked);
          return AnimatedSwitcher(
            duration: Duration(seconds: 1),
            child: ListTile(
              title: Text(capitalize(users[index]['name'])),
              leading: Icon(Icons.person, size: 50,),
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
                String user_id = users[index]['user_id'].toString();
                String name = users[index]['name'];
                String mobile = users[index]['mobile'].toString();
                String isp = users[index]['isp'];
                Navigator.of(context).pop();
                showDialog(context: context, builder: (BuildContext context){
                  _nameController.text = capitalize(name);
                  _phoneInternetController.text = capitalize(mobile);
                  _ispController.text = isp;
                  _userIDController.text = user_id;
                  _macController.text="";
                  return AlertDialog(
                    title: const Text("Edit Form"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment:
                        MainAxisAlignment.start,
                        children: [

                          SizedBox(height: 10,),
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
                                child: Checkbox(
                                    value: isChecked,
                                    onChanged: (newValue){
                                      _checkboxValueNotifier.value = true;
                                      print(_checkboxValueNotifier.value);

                                    }),
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
                                    icon: Icon(Icons.camera_alt_outlined),
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
                              user_id,
                              _nameController.text,
                              int.parse(_phoneInternetController.text),
                              _ispController.text,
                              _macController.text
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  );
                });
              },
            ),
          );
        },
      );

    } else{
      return SizedBox(height: 0,);
    }
  }
}
