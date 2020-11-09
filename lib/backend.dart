import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MinTXBackend extends ChangeNotifier {
  LatLng _on;
  LatLng _to;

  bool _computing = false;

  bool _computed = false;

  set on(LatLng on) {
    _on = on;
    reset();
    notifyListeners();
  }

  set to(LatLng to) {
    _to = to;
    reset();
    notifyListeners();
  }

  LatLng get on => _on;
  LatLng get to => _to;

  void compute() {
    _computing = true;
    notifyListeners();
  }

  Map<String, dynamic> yaResponse;
  Map<String, dynamic> uberResponse;

  processing() async {
    final ya = YandexAPI(on: on, to: to);
    print('[YA]: Doing...');
    final resYA = await ya.request();
    yaResponse = jsonDecode(resYA.body);
    print('[YA]: Done');

    final uber = UberAPI(on: on, to: to);
    print('[Uber]: Doing...');
    final resUber = await uber.request();
    print(resUber.body);
    uberResponse = jsonDecode(resUber.body);
    print('[Uber]: Done');
    _computed = true;
    notifyListeners();
  }

  Widget renderTaxes() {
    List<Widget> result = [];
    // YA
    final yaSerialise = {
      'currency': yaResponse['currency'],
      'currencyValue': yaResponse['options'][0]['price'],
      'currencyVerbose': yaResponse['options'][0]['price_text'],
    };
    result.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Yandex (econom)'),
                  Text('${yaSerialise['currencyValue'].toString()} ${yaSerialise['currency'].toString()}')
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {},
            )
          ],
        ),
      )
    );
    // end YA

    // Uber
    // end Uber

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result,
    );
  }

  void reset() {
    _computing = false;
    _computed = false;
    notifyListeners();
  }

  bool get computing => _computing;

  bool get canCompute => _on != null && _to != null;

  String get computeMsg {
    if (canCompute) return 'Посчитать';
    if (_on == null && _to == null) return 'Укажите откуда и куда';
    if (_on == null) return 'Укажите откуда';
    if (_to == null) return 'Укажите куда';
    return 'come wrong';
  }

  bool get computed => _computed;
}

class TaxiAPI {
  Map<String, String> headers() => {};
  String url() => '';

  final LatLng on;
  final LatLng to;

  TaxiAPI({this.on, this.to});

  Future<http.Response> request() {
    return http.get(url(), headers: headers());
  }
}

class YandexAPI extends TaxiAPI {
  @override
  headers() => {
    'Accept': 'application/json'
  };

  YandexAPI({LatLng on, LatLng to}): super(on: on, to: to);

  @override
  String url() {
    const clid = 'ak1493';
    const apikey = '3c93859d24c4489d81903ad450013ef6';
    final rll = '${on.longitude},${on.latitude}~${to.longitude},${to.latitude}';
    return 'https://taxi-routeinfo.taxi.yandex.net/taxi_info?'
        'clid=$clid&'
        'apikey=$apikey&'
        'rll=$rll&';
  }
}

class UberAPI extends TaxiAPI {
  static const key = 'JA.VUNmGAAAAAAAEgASAAAABwAIAAwAAAAAAAAAEgAAAAAAAAH4AAAAFAAAAAAADgAQAAQAAAAIAAwAAAAOAAAAzAAAABwAAAAEAAAAEAAAAM7kuw5a5QUMlSe4K2lczwKnAAAA-CIGYZ0-uxwcbt5IbMMo1zseNjMKdpMiL7llrKDKLSc5Ewae_bNU6qeLWa1xy570oCsLD4n_5-x0IaLRNglZtYTurhzZYGVgG7J-uDywaRQLGHXGiIAFKYkHVXih5tc9m8nWTiwXFuYu5fDrWGTAqLMFPNjMN1ThG2U7FF3FGSYNjKsYPhLDgmcVZ9G47KDy9UhkcBAl-6l9_MSGnFoGqAKygr1zgFoADAAAABSySmY6bZkT1enNoCQAAABiMGQ4NTgwMy0zOGEwLTQyYjMtODA2ZS03YTRjZjhlMTk2ZWU';
  // static const key = '589w-7Z_2KPiuFyBDcR9Giz-MLn_97oJm7cH0RVE';

  UberAPI({LatLng on, LatLng to}): super(on: on, to: to);

  @override
  headers() => {
    'Authorization': 'Bearer $key',
    'Accept-Language': 'en_US',
    'Content-Type': 'application/json',
  };

  @override
  url() => 'https://api.uber.com/v1.2/estimates/price?'
      'start_latitude=${on.latitude}&'
      'start_longitude=${on.longitude}&'
      'end_latitude=${to.latitude}'
      'end_longitude=${to.longitude}';
}