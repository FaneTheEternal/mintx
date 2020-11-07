import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MinTXApp());
}

class MinTXApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinTX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MenuWrapper(),
    );
  }
}

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

  processing() async {
    // TODO: Все запросы API
    await new Future.delayed(Duration(seconds: 5));
    _computed = true;
    notifyListeners();
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
}

class MenuWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MinTXBackend(),),
      ],
      child: Menu(),
    );
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MinTX'),
      ),
      body: Consumer<MinTXBackend>(
        builder: (context, backend, child) {
          return Column(
            children: [
              FlatButton(
                  onPressed: () {
                    _choiceOn(context, backend.on);
                  },
                  child: Row(
                    children: [
                      Expanded(child: Text(backend.on?.toString() ?? 'Выберите начало')),
                      Icon(Icons.arrow_forward)
                    ],
                  )
              ),
              FlatButton(
                  onPressed: () {
                    _choiceTo(context, backend.to);
                  },
                  child: Row(
                    children: [
                      Expanded(child: Text(backend.to?.toString() ?? 'Выберите конец')),
                      Icon(Icons.arrow_forward)
                    ],
                  )
              ),
              Compute(),
            ],
          );
        },
      )
    );
  }

  _choiceOn(BuildContext context, LatLng initPoint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChoicePlace(
        initPoint: initPoint,
      )),
    );

    if (result != null) {
      Provider.of<MinTXBackend>(context).on = result;
    }
  }

  _choiceTo(BuildContext context, LatLng initPoint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChoicePlace(
        initPoint: initPoint,
      )),
    );

    if (result != null) {
      Provider.of<MinTXBackend>(context).to = result;
    }
  }
}

const ChuvSU = LatLng(56.1439358,47.2097616);

class ChoicePlace extends StatefulWidget {
  final LatLng initPoint;

  ChoicePlace({this.initPoint});

  @override
  _ChoicePlaceState createState() => _ChoicePlaceState();
}

class _ChoicePlaceState extends State<ChoicePlace> {
  List<Marker> myMarker = [];

  @override
  void initState() {
    super.initState();
    if (widget.initPoint != null) {
      final point = widget.initPoint;
      myMarker.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите точку'),
        actions: [
          IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                if (myMarker.length > 0) {
                  Navigator.pop(context, myMarker[0].position);
                }
              }
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: ChuvSU,
          zoom: 15,
        ),
        onTap: _handleTap,
        markers: Set.from(myMarker),
      ),
    );
  }

  _handleTap(LatLng point) {
    setState(() {
      myMarker.clear();
      myMarker.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point,
      ));
    });
  }
}

class Compute extends StatefulWidget {

  @override
  _ComputeState createState() => _ComputeState();
}

class _ComputeState extends State<Compute> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Center(
          child: Consumer<MinTXBackend>(
            builder: (context, backend, child) {
              return backend._computed ? Text('List of Tax')
                  : backend.computing
                    ? CircularProgressIndicator()
                    : FlatButton(
                        onPressed: backend.canCompute
                            ? () async {
                                setState(() {backend.compute();});
                                await backend.processing();
                                setState(() {
                                  // update
                                });
                              }
                            : null,
                        child: Text(backend.computeMsg)
                      );
            },
          ),
        )
    );
  }
}

