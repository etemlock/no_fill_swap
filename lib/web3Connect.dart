import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
//import 'package:url_launcher/url_launcher_string.dart';
import 'package:web3dart/web3dart.dart';
//import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web_socket_channel/io.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class Web3ConnState {
  late EthPrivateKey _credentials;
  late EthereumAddress _swapAddress;
  late EtherAmount
      _ethBal; // = EtherAmount.fromUnitAndValue(EtherUnit.ether, 0);
  late var _tokenBal;

  EthPrivateKey? credentials() {
    return _credentials;
  }

  EthereumAddress? swapAddress() {
    return _swapAddress;
  }

  double ethBal() {
    return _ethBal.getValueInUnit(EtherUnit.ether);
  }

  tokenBal() {
    return _tokenBal;
  }
}

class Web3Connect extends ChangeNotifier {
  bool isLoading = true;
  final String _apiUrl = "http://192.168.11.12:7545";
  //   "http://192.168.100.25:7545"; //if using SakuraMobile
  final String _wsUrl = "ws://192.168.11.12:7545";
  //   "ws://192.168.100.25:7545"; //if using SakuraMobile

  /* ideally we should be connecting to Metamask (after linking the Ganache
   account to Metamask) to fetch account details, but there are network issues
   with the MetaMask mobile app on the Android simulator that prevent http access
   ie. https required, but Ganache server (localhost) supports http */
  final String _privateKeyAccount1 =
      "537fbfc5177d20edc3235823e2073d4a4115c637679bd3852c32bad0fa926aa9";

  late Web3Client _client;
  late var _abiCodeToken;
  late var _abiCodeNFS;

  late EthereumAddress _nfsContractAddress;
  late EthereumAddress _tokenContractAddress;
  late DeployedContract _nfsContract;
  late DeployedContract _tokenContract;

  late ContractFunction _sellTokens;
  late ContractFunction _buyTokens;
  late ContractFunction _getBalance;
  late ContractFunction _approve;

  Web3ConnState _buySellState = Web3ConnState();

  //constructor
  Web3Connect() {
    initialSetup();
  }

  // initial setup - initiate the Web3Client
  Future<void> initialSetup() async {
    _client = Web3Client(_apiUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
    await getBalances();

    isLoading = false;
    notifyListeners();
  }

  //getABI
  Future<void> getAbi() async {
    //load Token abi
    String abiFileLoc =
        "build/contracts/Token.json"; //typically best set as ENV Param
    String abiFile = await rootBundle.loadString(abiFileLoc);
    var jsonAbi = jsonDecode(abiFile);
    _abiCodeToken = jsonEncode(jsonAbi["abi"]);
    _tokenContractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    print(_abiCodeToken);

    //load NFSWap abi
    abiFileLoc = "build/contracts/NFSwap.json";
    abiFile = await rootBundle.loadString(abiFileLoc);
    jsonAbi = jsonDecode(abiFile);
    _abiCodeNFS = jsonEncode(jsonAbi["abi"]);
    _nfsContractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    print(_abiCodeNFS);
  }

  Future<void> getCredentials() async {
    _buySellState._credentials = EthPrivateKey.fromHex(_privateKeyAccount1);
    _buySellState._swapAddress = await _buySellState.credentials()!.address;
    print(_buySellState._swapAddress);
  }

  Future<void> getDeployedContract() async {
    _tokenContract = DeployedContract(
        ContractAbi.fromJson(_abiCodeToken, "Token"), _tokenContractAddress);
    _nfsContract = DeployedContract(
        ContractAbi.fromJson(_abiCodeNFS, "NFSwap"), _nfsContractAddress);

    _buyTokens = _nfsContract.function('buyTokens');
    _sellTokens = _nfsContract.function('sellTokens');
    _getBalance = _tokenContract.function('balanceOf');
    _approve = _tokenContract.function("approve");
  }

  Future<void> getBalances() async {
    await getEthBalance(_buySellState);
    await getTokenBalance(_buySellState);
  }

  Future<double> getEthBalance(Web3State) async {
    try {
      EtherAmount balance = await _client.getBalance(Web3State._swapAddress);
      Web3State._ethBal = balance;
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      print("there was an exception getting the ethereum balance : $e");
    }
    return 0.0;
  }

  Future getTokenBalance(Web3State) async {
    try {
      List<dynamic> balance = await _client.call(
          contract: _tokenContract,
          function: _getBalance,
          params: [Web3State._swapAddress]);
      Web3State._tokenBal = balance[0];
      return balance[0];
    } catch (e) {
      print("there was an exception getting the token balance : $e");
    }
    return 0.0;
  }

  Future buyTokens(buyAmount) async {
    try {
      isLoading = true;
      notifyListeners();
      EtherAmount etherAmount =
          EtherAmount.fromUnitAndValue(EtherUnit.ether, buyAmount);
      await _client.sendTransaction(
          _buySellState._credentials,
          Transaction.callContract(
              contract: _nfsContract,
              function: _buyTokens,
              parameters: [],
              from: _buySellState._swapAddress,
              value: etherAmount,
              maxGas: 100000));
      await getBalances();
    } catch (e) {
      print("there was an exception buying tokens : $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future sellTokens(sellAmount) async {
    try {
      isLoading = true;
      notifyListeners();
      BigInt tokenAmount = BigInt.from(sellAmount);
      //first we got to call the approve function
      await _client.sendTransaction(
          _buySellState._credentials,
          Transaction.callContract(
              contract: _tokenContract,
              function: _approve,
              from: _buySellState._swapAddress,
              maxGas: 100000,
              parameters: [_nfsContractAddress, tokenAmount]));
      await _client.sendTransaction(
          _buySellState._credentials,
          Transaction.callContract(
              contract: _nfsContract,
              function: _sellTokens,
              from: _buySellState._swapAddress,
              maxGas: 100000,
              parameters: [tokenAmount]));
      await getBalances();
    } catch (e) {
      print("There was an exception selling tokens : $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Web3ConnState getBuySellState() {
    return _buySellState;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
