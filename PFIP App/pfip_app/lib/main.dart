import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pfip_app/colors.dart';
import 'package:pfip_app/firebase_options.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ilaw App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: primary,
      ),
      home: const MyHomePage(title: 'Ilaw App'),
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
  int currentIndex = 0;
  int voltReading = 0;
  double energyReading = 0;
  double currentReading = 0;
  double powerReading = 0;
  int tempReading = 0;
  FirebaseDatabase database = FirebaseDatabase.instance;

  bool buttonToggle = false;

  @override
  void initState() {
    super.initState();
    DatabaseReference liveData = database.ref('/device-live');

    liveData.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data != null && data is Map<Object?, Object?>) {
        final Map<String, dynamic> typedData = data.cast<String, dynamic>();
        final temp =
            data['temp-reading'] is int ? data['temp-reading'] as int : 0;
        final volt =
            data['vol-reading'] is int ? data['vol-reading'] as int : 0;
        final power =
            data['pow-reading'] is double ? data['pow-reading'] as double : 0.0;
        final current = data['curr-reading'] is double
            ? data['curr-reading'] as double
            : 0.0;
        final ener = data['ener-reading'] is double
            ? data['ener-reading'] as double
            : 0.0;

        setState(() {
          tempReading = temp;
          voltReading = volt;
          powerReading = power;
          currentReading = current;
          energyReading = ener;
        });
      }
    });
  }

  readingsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: 150,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('ENERGY',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                  ]),
                  Text('${energyReading} kWh',
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 20))
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              alignment: Alignment.center,
              width: 150,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('CURRENT',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                  ]),
                  Text('${currentReading} A',
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 25))
                ],
              ),
            )
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: 150,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('POWER',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                  ]),
                  Text('${powerReading} W',
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 25))
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              alignment: Alignment.center,
              width: 150,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('TEMPERATURE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                  ]),
                  Text('${tempReading.toInt()} °C',
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 25))
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  homePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 30),
          Container(
            height: 250,
            child: SfRadialGauge(
                title: GaugeTitle(
                    text: 'VOLTAGE',
                    textStyle: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
                axes: <RadialAxis>[
                  RadialAxis(
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          '${voltReading} V',
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 25),
                        ),
                      )
                    ],
                    minimum: 0,
                    maximum: 240,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      cornerStyle: CornerStyle.bothCurve,
                      color: Color.fromARGB(30, 0, 169, 181),
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: voltReading.toDouble(),
                        cornerStyle: CornerStyle.bothCurve,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                      )
                    ],
                  )
                ]),
          ),
          SizedBox(height: 30),
          readingsWidget(),
        ],
      ),
    );
  }

  graphPage() {
    return Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: []));
  }

  setPage() {
    return Center(
        child: Container(
      padding: EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: (buttonToggle == true)
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ))
                  : ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      )),
              child: (buttonToggle == true)
                  ? Text("Turn Off Power",
                      style: TextStyle(color: Colors.white, fontSize: 16))
                  : const Text("Turn On Power",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () {
                setState(() {
                  buttonToggle = !buttonToggle;
                });
                database.ref('device-params/').update({'set-switch' : buttonToggle});
              },
            )),
      ]),
    ));
  }

  homepageSelect() {
    if (currentIndex == 0) {
      return homePage();
    } else if (currentIndex == 1) {
      return graphPage();
    } else {
      return setPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: homepageSelect(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey.withOpacity(0.5),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            label: '',
            icon: Icon(Icons.home_rounded),
          ),
          BottomNavigationBarItem(
            label: '',
            icon: Icon(Icons.line_axis_rounded),
          ),
          BottomNavigationBarItem(
            label: '',
            icon: Icon(Icons.settings_rounded),
          )
        ],
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
