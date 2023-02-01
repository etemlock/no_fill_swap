import 'package:flutter/material.dart';
import 'package:no_fill_swaps/web3Connect.dart';
import 'package:provider/provider.dart';
import 'buyForm.dart';
import 'sellForm.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => Web3Connect(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final Web3Connect myWeb3Connect = Web3Connect();

  final ValueNotifier<String> _currForm = ValueNotifier("Buy");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Text("NoFillSwap")),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _currForm.value = "Buy";
                        });
                      },
                      child: Text("Buy Tokens")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _currForm.value = "Sell";
                        });
                      },
                      child: Text("Sell Tokens"))
                ],
              ),
              _currForm.value == "Buy"
                  ? BuyForm()
                  : SellForm() // switch this between buy and sell form
            ]),
      ),
    );
  }
}
