import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
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
  double energyBill = 0;
  double kwhPrice = 0;
  int tempReading = 0;
  List<int> voltageDataPoints = []; //LUX
  List<double> powerDataPoints = [];
  final int maxDataPoints = 20;
  FirebaseDatabase database = FirebaseDatabase.instance;

  bool buttonToggle = false;

  @override
  void initState() {
    super.initState();
    DatabaseReference liveData = database.ref('/device-live');
    DatabaseReference paramsData = database.ref('/device-params');
    DatabaseReference recordsData = database.ref('/device-records');

    recordsData.onChildAdded.listen((DatabaseEvent event) {
      final vol =
          int.parse(event.snapshot.child('vol-reading').value.toString());
      final curr =
          double.parse(event.snapshot.child('pow-reading').value.toString());

      setState(() {
        voltageDataPoints.add(vol);
        powerDataPoints.add(curr);
        if (voltageDataPoints.length > maxDataPoints) {
          voltageDataPoints.removeAt(0); // Remove the oldest data point.
          powerDataPoints.removeAt(0);
        }
      });
    });

    liveData.onValue.listen((DatabaseEvent event) {
      final temp =
          int.parse(event.snapshot.child('temp-reading').value.toString());
      final volt =
          int.parse(event.snapshot.child('vol-reading').value.toString());
      final power =
          double.parse(event.snapshot.child('pow-reading').value.toString());
      final current =
          double.parse(event.snapshot.child('curr-reading').value.toString());
      final ener =
          double.parse(event.snapshot.child('ener-reading').value.toString());
      // final price =
      //     typedData['device-params/kwh-price'] is double ? typedData['device-params/kwh-price'] as double : 0.0;

      setState(() {
        tempReading = temp;
        voltReading = volt;
        powerReading = power;
        currentReading = current;
        energyReading = ener;
        energyBill = kwhPrice * energyReading;
      });
    });

    paramsData.onValue.listen((DatabaseEvent event) {
      final price =
          double.parse(event.snapshot.child('set-price').value.toString());

      setState(() {
        kwhPrice = price;
        energyBill = kwhPrice * energyReading;
      });
    });
  }

  void _showEditDialog(BuildContext context) {
    TextEditingController priceController = TextEditingController();
    priceController.text = kwhPrice.toString(); // Set initial value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Price'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter new price'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                
                database
                    .ref('device-params/')
                    .update({"set-price": double.parse(priceController.text)});
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(
          children: [
            SizedBox(width: 30),
            SizedBox(
              height: 10,
              width: 10,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.yellow[600])),
            ),
            Text(
              " Voltage   ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
            SizedBox(
              height: 10,
              width: 10,
              child:
                  DecoratedBox(decoration: BoxDecoration(color: Colors.blue)),
            ),
            Text(
              " Power  ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
        Container(
            height: 200,
            padding: EdgeInsets.all(15),
            child: LineChart(
              LineChartData(
                  maxY: 300,
                  minY: 0,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      preventCurveOverShooting: true,
                      spots: voltageDataPoints.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.yellow[600],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: powerDataPoints.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    )
                    // LineChartBarData(
                    //   spots: [
                    //     FlSpot(dataPoints.elementAt(9).time.toDouble(),
                    //         saveLux.toDouble())
                    //   ],
                    //   isCurved: false,
                    //   barWidth: 2,
                    //   color: Colors.red,
                    //   dotData: FlDotData(show: true),
                    //   belowBarData: BarAreaData(show: false),
                    // ),
                  ],
                  titlesData: FlTitlesData(
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                          // axisNameWidget: Text(
                          //   "Voltage",
                          //   style: TextStyle(
                          //       fontWeight: FontWeight.bold, fontSize: 10),
                          // ),
                          sideTitles: SideTitles(
                              getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: 9)),
                              interval: 50,
                              showTitles: true)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                        // getTitlesWidget: (value, meta) {
                        //   DateTime date =
                        //       DateTime.fromMillisecondsSinceEpoch(
                        //           value.toInt());
                        //   String formattedTime =
                        //       DateFormat("h:mm").format(date);
                        //   return Text(
                        //     formattedTime,
                        //     style: TextStyle(fontSize: 9),
                        //   );
                        // },
                        showTitles: false,
                      )))),
            )),
        SizedBox(
          height: 15,
        ),
        Container(
          alignment: Alignment.center,
          width: 300,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Est. Monthly Bill',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Open dialog for editing the price
                    _showEditDialog(context);
                  },
                  child: Text('Edit'),
                )
              ]),
              Text('₱${energyBill.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 40))
            ],
          ),
        ),
      ]),
    );
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
                database
                    .ref('device-params/')
                    .update({'set-switch': buttonToggle});
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
