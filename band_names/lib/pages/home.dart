import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    // Band(id: '1', name: 'Metallica',           votes: 5),
    // Band(id: '2', name: 'Queen',               votes: 5),
    // Band(id: '3', name: 'Héroes del Silencio', votes: 5),
    // Band(id: '4', name: 'Bon Jovi',            votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames', style: TextStyle( color: Colors.black87 )),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online )
            ? Icon( Icons.check_circle, color: Colors.blue[300])
            : const Icon( Icons.offline_bolt, color: Colors.red)
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context,i) => _bandTile(bands[i])
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        onPressed: addNewBand,
        child: const Icon( Icons.add ),
      ),
   );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle(color: Colors.white)),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text( band.name.substring(0,2) ),
        ),
        title: Text(band.name),
        trailing: Text('${ band.votes }', style: const TextStyle( fontSize: 20 )),
        onTap: () => socketService.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if ( Platform.isAndroid ) {
      showDialog(
        context: context,
        builder: ( _ ) => AlertDialog(
          title: const Text('New band name: '),
          content: TextField( controller: textController ),
          actions: [
            MaterialButton(
              elevation: 5,
              textColor: Colors.blue,
              child: const Text('Add'),
              onPressed: () => addBandToList(textController.text)
            )
          ],
        )
      );
    }
    showCupertinoDialog(
      context: context,
      builder: ( _ ) => CupertinoAlertDialog(
        title: const Text('New band name: '),
        content: CupertinoTextField( controller: textController ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () => addBandToList(textController.text)
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context)
          )
        ],
      )
    );
  }

  void addBandToList(String name) {
    if ( name.length > 1 ) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  // Mostrar Grafica
  Widget _showGraph() {
    Map<String, double> dataMap = Map();

    bands.forEach((band){
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: PieChart(dataMap: dataMap)
    );
  }

}