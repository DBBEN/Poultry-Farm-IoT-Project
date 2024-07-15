//import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      title: 'BroilerTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: primary,
      ),
      home: const MyHomePage(title: 'BroilerTech'),
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
  int humReading = 0;
  int maxVol = 0;
  int maxTemp = 0;
  int maxHum = 0;
  int setAlarm = 0;
  TimeOfDay selectedTime = TimeOfDay.now();
  List<int> voltageDataPoints = []; //LUX
  List<double> powerDataPoints = [];
  final int maxDataPoints = 20;
  FirebaseDatabase database = FirebaseDatabase.instance;
  final formKey = GlobalKey<FormState>();

  bool button1Toggle = false;
  bool button2Toggle = false;

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

    paramsData.onValue.listen((DatabaseEvent event) {
      final price =
          double.parse(event.snapshot.child('set-price').value.toString());
      final maxv = int.parse(event.snapshot.child('max-vol').value.toString());
      final maxt = int.parse(event.snapshot.child('set-temp').value.toString());
      final maxh = int.parse(event.snapshot.child('set-hum').value.toString());
      //final time = int.parse(event.snapshot.child('set-alarm').value.toString());
      final switch1 = event.snapshot.child('set-switch-1').value as bool;
      final switch2 = event.snapshot.child('set-switch-2').value as bool;
      //print("Switch 1: $switch1, Switch 2: $switch2");

      setState(() {
        kwhPrice = price;
        energyBill = kwhPrice * energyReading;
        maxVol = maxv;
        maxTemp = maxt;
        maxHum = maxh;
        button1Toggle = switch1;
        button2Toggle = switch2;
        //setAlarm = time;
        //print({kwhPrice, energyBill, maxVol, maxHum});
      });
    });

    liveData.onValue.listen((DatabaseEvent event) {
      final temp =
          int.parse(event.snapshot.child('temp-reading').value.toString());
      final hum =
          int.parse(event.snapshot.child('hum-reading').value.toString());
      final volt =
          int.parse(event.snapshot.child('vol-reading').value.toString());
      final power =
          double.parse(event.snapshot.child('pow-reading').value.toString());
      final current =
          double.parse(event.snapshot.child('curr-reading').value.toString());
      final ener =
          double.parse(event.snapshot.child('ener-reading').value.toString());

      setState(() {
        tempReading = temp;
        humReading = hum;
        voltReading = volt;
        powerReading = power;
        currentReading = current;
        energyReading = ener;
        energyBill = kwhPrice * energyReading;
      });
    });
  }

  String formatEpochToTime(int epoch) {
    // Convert epoch timestamp to DateTime
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    // Format DateTime to a human-readable time
    String formattedTime = DateFormat('h:mm a').format(dateTime);
    return formattedTime;
  }

  int convertToEpoch(TimeOfDay time) {
    DateTime now = DateTime.now();
    DateTime dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return dateTime.millisecondsSinceEpoch ~/ 1000;
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

  void _showEditVoltageDialog(BuildContext context) {
    TextEditingController voltageController = TextEditingController();
    voltageController.text = maxVol.toString(); // Set initial value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Voltage Cutoff Limit'),
          content: TextField(
            controller: voltageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter voltage limit'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                database
                    .ref('device-params/')
                    .update({"max-vol": int.parse(voltageController.text)});
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTemperatureDialog(BuildContext context) {
    TextEditingController temperatureController = TextEditingController();
    temperatureController.text = maxTemp.toString(); // Set initial value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Temperature Threshold'),
          content: TextField(
            controller: temperatureController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: 'Edit Temperature Threshold'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                database.ref('device-params/').update(
                    {"set-temp": int.parse(temperatureController.text)});
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditHumidityDialog(BuildContext context) {
    TextEditingController humidityController = TextEditingController();
    humidityController.text = maxHum.toString(); // Set initial value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Humidity Threshold'),
          content: TextField(
            controller: humidityController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: 'Edit Temperature Threshold'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                database
                    .ref('device-params/')
                    .update({"set-hum": int.parse(humidityController.text)});
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _showEditFeedingDialog(BuildContext context) async {
  //   TimeOfDay? pickedTime = await showTimePicker(
  //     context: context,
  //     initialTime: selectedTime,
  //   );

  //   if (pickedTime != null && pickedTime != selectedTime) {
  //     setState(() {
  //       selectedTime = pickedTime;
  //     });

  //     // Convert selected time to epoch
  //     int epochTime = convertToEpoch(selectedTime);
  //     database.ref('device-params/').update({"set-alarm": epochTime});

  //     setState(() {
  //       setAlarm = epochTime;
  //     });
  //   }
  // }

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
                  Text('${tempReading.toInt()}°C',
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
        Container(
          alignment: Alignment.center,
          width: 300,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('HUMIDITY',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    )),
              ]),
              Text('${humReading} %',
                  style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 25))
            ],
          ),
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
          padding: EdgeInsets.all(15),
          child: Container(
            alignment: Alignment.center,
            //width: 300,
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
        ),
      ]),
    );
  }

  setPage() {
    return Center(
        child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  //width: 300,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Voltage Cutoff',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                )),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Open dialog for editing the price
                                _showEditVoltageDialog(context);
                              },
                              child: Text('Edit'),
                            )
                          ]),
                      Text('${maxVol.toString()} V',
                          style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 40))
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  alignment: Alignment.center,
                  //width: 300,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Temperature Threshold',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                )),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Open dialog for editing the price
                                _showEditTemperatureDialog(context);
                              },
                              child: Text('Edit'),
                            )
                          ]),
                      Text('${maxTemp.toString()}°C',
                          style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 40))
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                // Container(
                //   alignment: Alignment.center,
                //   //width: 300,
                //   decoration: BoxDecoration(
                //       border: Border.all(color: Colors.grey, width: 1),
                //       borderRadius: BorderRadius.circular(20)),
                //   padding: EdgeInsets.all(20),
                //   child: Column(
                //     children: [
                //       Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Text('Feeding Time',
                //                 style: TextStyle(
                //                   color: Colors.black,
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 20,
                //                 )),
                //             SizedBox(width: 10),
                //             ElevatedButton(
                //               onPressed: () {
                //                 // Open dialog for editing the price
                //                 _showEditFeedingDialog(context);
                //               },
                //               child: Text('Edit'),
                //             )
                //           ]),
                //       Text(formatEpochToTime(setAlarm),
                //           style: const TextStyle(
                //               color: primary,
                //               fontWeight: FontWeight.w600,
                //               fontSize: 40))
                //     ],
                //   ),
                // ),
                Container(
                  alignment: Alignment.center,
                  //width: 300,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Humidity Threshold',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                )),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Open dialog for editing the price
                                _showEditHumidityDialog(context);
                              },
                              child: Text('Edit'),
                            )
                          ]),
                      Text('${maxHum.toString()}%',
                          style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 40))
                    ],
                  ),
                ),
                // SizedBox(
                //   height: 30,
                // ),
                // SizedBox(
                //     height: 50,
                //     width: double.infinity,
                //     child: ElevatedButton(
                //       style: (button1Toggle == true)
                //           ? ElevatedButton.styleFrom(
                //               backgroundColor: Colors.red,
                //               elevation: 0,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(30),
                //               ))
                //           : ElevatedButton.styleFrom(
                //               backgroundColor: primary,
                //               elevation: 0,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(30),
                //               )),
                //       child: (button1Toggle == true)
                //           ? Text("Turn Off Fan",
                //               style:
                //                   TextStyle(color: Colors.white, fontSize: 16))
                //           : const Text("Turn On Fan",
                //               style:
                //                   TextStyle(color: Colors.white, fontSize: 16)),
                //       onPressed: () {
                //         setState(() {
                //           button1Toggle = !button1Toggle;
                //         });
                //         database
                //             .ref('device-params/')
                //             .update({'set-switch-1': button1Toggle});
                //       },
                //     )),
                // SizedBox(
                //   height: 15,
                // ),
                // SizedBox(
                //     height: 50,
                //     width: double.infinity,
                //     child: ElevatedButton(
                //       style: (button2Toggle == true)
                //           ? ElevatedButton.styleFrom(
                //               backgroundColor: Colors.red,
                //               elevation: 0,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(30),
                //               ))
                //           : ElevatedButton.styleFrom(
                //               backgroundColor: primary,
                //               elevation: 0,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(30),
                //               )),
                //       child: (button2Toggle == true)
                //           ? Text("Turn Off Bulb",
                //               style:
                //                   TextStyle(color: Colors.white, fontSize: 16))
                //           : const Text("Turn On Bulb",
                //               style:
                //                   TextStyle(color: Colors.white, fontSize: 16)),
                //       onPressed: () {
                //         setState(() {
                //           button2Toggle = !button2Toggle;
                //         });
                //         database
                //             .ref('device-params/')
                //             .update({'set-switch-2': button2Toggle});
                //       },
                //     ))
              ],
            )));
  }

  void _showAddEntryDialog(BuildContext context) {
    TextEditingController labelController = TextEditingController();
    TextEditingController startHeadsController = TextEditingController();
    TextEditingController endHeadsController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(labelText: 'Label'),
                ),
                TextField(
                  controller: startHeadsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Start Heads'),
                ),
                TextField(
                  controller: endHeadsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'End Heads'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    startDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                  },
                  child: Text('Select Start Date'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    endDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                  },
                  child: Text('Select End Date'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isNotEmpty &&
                    startHeadsController.text.isNotEmpty &&
                    endHeadsController.text.isNotEmpty &&
                    startDate != null &&
                    endDate != null) {
                  int startHeads = int.parse(startHeadsController.text);
                  int endHeads = int.parse(endHeadsController.text);
                  double fatalityPercent = double.parse(
                      (((startHeads - endHeads) / startHeads) * 100)
                          .toStringAsFixed(1));

                  // Save the data to Firestore
                  final records =
                      FirebaseFirestore.instance.collection('records').doc();
                  final data = {
                    'label': labelController.text,
                    'startHeads': startHeads,
                    'endHeads': endHeads,
                    'timeDateStart': Timestamp.fromDate(startDate!),
                    'timeDateEnd': Timestamp.fromDate(endDate!),
                    'fatalityPercent': fatalityPercent,
                  };

                  await records.set(data);

                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Card cardLayout(var i, DocumentReference snapRef) {
    Timestamp timeDateStart = i['timeDateStart'];
    Timestamp timeDateEnd = i['timeDateEnd'];
    DateTime dateStart = timeDateStart.toDate();
    DateTime dateEnd = timeDateEnd.toDate();
    String dateTimeStart = DateFormat("MMMM d, yyyy").format(dateStart);
    String dateTimeEnd = DateFormat("MMMM d, yyyy").format(dateEnd);

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Fatality Rate',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                          fontSize: 13),
                    ),
                    Text(
                      '${i['fatalityPercent']}%',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 25),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.only(bottom: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${i['label']}',
                            style: TextStyle(
                              color: primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteRecord(snapRef);
                            },
                          ),
                        ],
                      ),
                    ),
                    Text("Start of Growth Process",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.grey, size: 16),
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              dateTimeStart,
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.pets_rounded,
                              color: Colors.grey, size: 16),
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              '${i['startHeads']} Chickens Alive',
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text("End of Growth Process",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.grey, size: 16),
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              dateTimeEnd,
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.pets_rounded,
                              color: Colors.grey, size: 16),
                          Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              '${i['endHeads']} Chickens Left',
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(DocumentReference snapRef) async {
    await snapRef.delete();
  }

  chickenDataPage() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .orderBy("timeDateStart", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          else {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                      child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var data = snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                            DocumentReference snapRef =
                                snapshot.data!.docs[index].reference;
                            return cardLayout(data, snapRef);
                            // return GestureDetector(
                            //   onTap: () {
                            //     //view record
                            //     //popupDialog(data, snapRef);
                            //   },
                            //   child: cardLayout(data),
                            // );
                          }))
                ],
              ),
            );
          }
        });
  }

  homepageSelect() {
    if (energyReading < 1) {
      return const Center(
        child: CircularProgressIndicator(color: primary),
      );
    } else if (currentIndex == 0 && energyReading > 1) {
      return homePage();
    } else if (currentIndex == 1 && energyReading > 1) {
      return graphPage();
    } else if (currentIndex == 2 && energyReading > 1) {
      return chickenDataPage();
    } else {
      return setPage();
    }
  }

  void showSnackBar(context, message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: "OK",
        onPressed: () {},
        textColor: Colors.white,
      ),
    ));
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
            icon: Icon(Icons.holiday_village_rounded),
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
      floatingActionButton: currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                // Add your onPressed code here
                _showAddEntryDialog(context);
              },
              child: Icon(Icons.add),
              backgroundColor: primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
