import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:isolate';
// pour (compute)
// import 'package:flutter/foundation.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiThreadingDemo(),
    );
  }
}

class MultiThreadingDemo extends StatefulWidget {
  const MultiThreadingDemo({super.key});
  @override
  State<MultiThreadingDemo> createState() => _MultiThreadingDemoState();
}

class _MultiThreadingDemoState extends State<MultiThreadingDemo> {
  double _turns = 0.0;
  Timer? _timer;
  String _result = "Résultat ici...";

  @override
  void initState() {
    super.initState();
    // Lance une nouvelle rotation toutes les 2 secondes (1 tour par 2s).
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() => _turns += 1.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Petit appel asynchrone simulé
  Future<void> _smallAsyncApiCall() async {
    setState(() => _result = "Loading small task...");
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _result = "✅ Small async task finished");
  }

  // Heavy task — bloque l'UI (ne pas utiliser en production)
  void _heavyTaskBlocksUI() {
    setState(() => _result = "Running heavy task (main thread)...");
    int sum = 0;
    // Ajuste cette valeur selon la puissance de ton appareil
    for (int i = 0; i < 100000000; i++) {
      sum += i;
    }
    setState(() => _result = "⚠️ Heavy task finished (UI blocked). sum=$sum");
  }

  // Exemple 1

  // Heavy task dans un Isolate — n'empêche pas l'UI
  Future<void> _heavyTaskWithIsolate() async {
    setState(() => _result = "Running heavy task in Isolate...");
    final receivePort = ReceivePort();
    await Isolate.spawn(_heavyComputation, receivePort.sendPort);
    final result = await receivePort.first;
    setState(() => _result = "✅ Heavy task with Isolate finished. sum=$result");
  }

  // Fonction exécutée dans l'isolate
  static void _heavyComputation(SendPort sendPort) {
    int sum = 0;
    for (int i = 0; i < 100000000; i++) {
      sum += i;
    }
    sendPort.send(sum);
  }

  // Exemple 2

  // // Heavy task avec compute — UI reste fluide
  // Future<void> _heavyTaskWithCompute() async {
  //   setState(() => _result = "Running heavy task with compute...");
  //   final result = await compute(_heavyComputation, 100000000);
  //   setState(() => _result = "✅ Heavy task with compute finished. sum=$result");
  // }

  // // Fonction top-level pour compute
  // static int _heavyComputation(int max) {
  //   int sum = 0;
  //   for (int i = 0; i < max; i++) {
  //     sum += i;
  //   }
  //   return sum;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multithreading Demo")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation : AnimatedRotation (pas de with / implements)
          AnimatedRotation(
            turns: _turns,
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
            child: const Icon(Icons.sync, size: 80, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            child: Text(_result, textAlign: TextAlign.center),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _smallAsyncApiCall,
                  child: const Text("Small Async Task"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _heavyTaskBlocksUI,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Heavy Task (Blocks UI)"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _heavyTaskWithIsolate,
                  // onPressed: _heavyTaskWithCompute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Heavy Task (With Isolate)"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
