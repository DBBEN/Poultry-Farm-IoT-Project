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
  int voltReading = 0;
  double energyReading = 0;
  double currentReading = 0;
  double powerReading = 0;
  int tempReading = 0;
  FirebaseDatabase database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    DatabaseReference liveData = database.ref('/device-live');

    liveData.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      
      if (data != null && data is Map<Object?, Object?>) {
        final Map<String, dynamic> typedData = data.cast<String, dynamic>();
        final temp = data['temp-reading'] as int;
        final volt = data['vol-reading'] as int;
        final power = data['pow-reading'] as double;
        final current = data['curr-reading'] as double;

        setState(() {
          tempReading = temp;
          voltReading = volt;
          powerReading = power;
          currentReading = current;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
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
      ),
    );
  }
}
