import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'web3Connect.dart';

class SellForm extends StatefulWidget {
  const SellForm({super.key});

  @override
  SellFormState createState() {
    return SellFormState();
  }
}

class SellFormState extends State<SellForm> {
  final TextEditingController _tokenEditingController = TextEditingController();
  final TextEditingController _ethEditingController = TextEditingController();
  final FocusNode _tokenEditingFocus = FocusNode();
  final FocusNode _ethEditingFocus = FocusNode();
  bool _tokenFocus = false;
  bool _ethFocus = false;

  @override
  void initState() {
    super.initState();

    _ethEditingFocus.addListener(() => {_ethFocus = true, _tokenFocus = false});

    _tokenEditingFocus
        .addListener(() => {_tokenFocus = true, _ethFocus = false});

    _ethEditingController.addListener(() => {
          if (_ethFocus)
            {
              _tokenEditingController.text =
                  (int.parse(_ethEditingController.text) * 100).toString()
            }
        });
    _tokenEditingController.addListener(() => {
          if (_tokenFocus)
            {
              _ethEditingController.text =
                  (int.parse(_tokenEditingController.text) / 100).toString()
            }
        });
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    //final Web3Connect myWeb3Connect = Provider.of<Web3Connect>(context);
    // Build a Form widget using the _formKey created above.
    return Provider.of<Web3Connect>(context).isLoading
        ? Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Container(
              width: MediaQuery.of(context).size.width - 80,
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Flexible(
                      flex: 3,
                      child: Text(
                          "Account no : ${Provider.of<Web3Connect>(context).getBuySellState().swapAddress().toString().substring(0, 10)}"),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)),
                    // this below can be accomplished with a list view - refactor later
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Sell",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                "Balance : ${Provider.of<Web3Connect>(context).getBuySellState().tokenBal() / BigInt.from(pow(10, 18))}"),
                          ],
                        ),
                        TextFormField(
                          controller: _tokenEditingController,
                          focusNode: _tokenEditingFocus,
                          decoration: InputDecoration(
                              icon: Image.asset("assets/punit-logo.png",
                                  height: 24, width: 24),
                              border: OutlineInputBorder(),
                              labelText: '0'),
                          validator: (String? value) {
                            if (value!.isEmpty) return 'bogus@gmail.com';
                            return null;
                          },
                        ),
                        Padding(padding: EdgeInsets.symmetric(vertical: 20)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Buy",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                "Balance : ${Provider.of<Web3Connect>(context).getBuySellState().ethBal()}"),
                          ],
                        ),
                        TextFormField(
                          controller: _ethEditingController,
                          focusNode: _ethEditingFocus,
                          decoration: InputDecoration(
                              icon: Image.asset("assets/eth-diamond-black.png",
                                  height: 24, width: 24),
                              border: OutlineInputBorder(),
                              labelText: '0'),
                          validator: (String? value) {
                            if (value!.isEmpty) return 'bogus@gmail.com';
                            return null;
                          },
                        ),
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: ElevatedButton(
                                onPressed: () => {
                                      Provider.of<Web3Connect>(context,
                                              listen: false)
                                          .sellTokens(int.parse(
                                              _tokenEditingController.text))
                                    },
                                child: Text(
                                  "SWAP NOW",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0),
                                )))
                      ],
                    ),
                  )
                ],
              ),
            ));
  }
}
