import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:due_kasir/routes/router.dart';
import 'package:due_kasir/pages/bills.dart';
import 'package:due_kasir/pages/profit.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:signals/signals_flutter.dart';

final isDeviceConnected = signal(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  runApp(const MyApp());
}

final _router = GoRouter(routes: [
  ...$appRoutes,
  GoRoute(path: '/bills', builder: (context, state) => const Bills()),
  GoRoute(path: '/profit', builder: (context, state) => const Profit()),
]);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> subscription;
  @override
  void initState() {
    super.initState();

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      isDeviceConnected.value = await InternetConnectionChecker().hasConnection;
      log("Internet status ====== $isDeviceConnected");
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Wajahat POS',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
