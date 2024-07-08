// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const GetMaterialApp(
//       home: BluetoothApp(),
//     );
//   }
// }

// class BluetoothApp extends GetView<BluetoothController> {
//   const BluetoothApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Get.put(BluetoothController());
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bluetooth App'),
//       ),
//       body: Obx(() {
//         return SingleChildScrollView(
//             child: Column(
//           children: [
//             ElevatedButton(
//                 onPressed: () {
//                   controller.scanForDevices();
//                 },
//                 child: const Text('Scan')),
//             Text('Count = ${controller.list.length}'),
//             controller.connectedDevice.value == null
//                 ? Center(child: Text(controller.message.value))
//                 : ListView.builder(
//                     itemCount: controller.services.length,
//                     itemBuilder: (context, index) {
//                       return ListTile(
//                         title: Text(controller.services[index].uuid.toString()),
//                       );
//                     },
//                   ),
//             Column(
//                 children: controller.list
//                     .map((e) => GestureDetector(
//                           child: SizedBox(
//                             height: 20,
//                             child: Row(
//                               children: [
//                                 Text(e.device.id.toString()),
//                                 Text(e.device.name),
//                               ],
//                             ),
//                           ),
//                           onTap: () => {controller.connectToDevice(e.device)},
//                         ))
//                     .toList()),
//           ],
//         ));
//       }),
//     );
//   }
// }

// class BluetoothController extends GetxController {
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   static const scanTimeoutSeconds = 10;
//   RxList<ScanResult> list = <ScanResult>[].obs;
//   FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
//   RxString message = ''.obs;
//   var connectedDevice = Rx<BluetoothDevice?>(null);
//   var services = <BluetoothService>[].obs;

//   Future<bool> checkPermission() async {
//     bool result = await _requestBluetoothScanPermission();
//     return result;
//   }

//   /// Initiates scanning for Bluetooth devices.
//   void scanForDevices() async {
//     if (await checkPermission()) {
//       Get.snackbar('Thong bao', 'Da co quyen');
//       startScanning();
//     } else {
//       Get.snackbar('Thong bao', 'Chua co quyen');
//     }
//   }

//   /// Requests the user's permission to scan for Bluetooth devices.
//   Future<bool> _requestBluetoothScanPermission() async {
//     var status = await Permission.bluetoothScan.status;
//     if (!status.isGranted) {
//       status = await Permission.bluetoothScan.request();
//     }
//     return status.isGranted;
//   }

//   /// Starts scanning for Bluetooth devices.
//   void startScanning() {
//     message.value = 'Scanning for devices...';
//     list.clear();
//     flutterBlue
//         .scan(timeout: const Duration(seconds: scanTimeoutSeconds))
//         .listen(
//       (scanResult) {
//         var a = scanResult;
//         // if (scanResult.device.type != BluetoothDeviceType.unknown) {
//           list.add(scanResult);
//         // }
//       },
//       onError: (err) {
//         message.value = "Error scanning for devices: $err";
//       },
//       onDone: () {
//         message.value = 'Done';
//       },
//     );
//   }

//   /// Connects to a specified Bluetooth device.
//   void connectToDevice(BluetoothDevice device) async {
//     try {
//       await device.connect();
//       connectedDevice.value = device;
//       discoverServices();
//       Get.snackbar('Message', 'Connect success');
//     } catch (e) {
//       Get.snackbar('Message', 'Connect fail');
//     }
//   }

//   /// Discovers services offered by the connected Bluetooth device.
//   void discoverServices() async {
//     if (connectedDevice.value == null) return;
//     try {
//       var servicesList = await connectedDevice.value!.discoverServices();
//       services.assignAll(servicesList);
//     } catch (e) {
//       Get.snackbar('Message', 'Failed to discover services: $e');
//     }
//   }
// }


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'screens/bluetooth_off_screen.dart';
import 'screens/scan_screen.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const FlutterBlueApp());
}

//
// This widget shows BluetoothOffScreen or
// ScanScreen depending on the adapter state
//
class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const ScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState);

    return MaterialApp(
      color: Colors.lightBlue,
      home: screen,
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}