import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyOverviewScreen extends StatefulWidget {
  final String dateKey;

  const DailyOverviewScreen({super.key, required this.dateKey});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen> {
  List<Map<String, dynamic>> breakfast = [];
  List<Map<String, dynamic>> lunch = [];
  List<Map<String, dynamic>> dinner = [];
  List<Map<String, dynamic>> snacks = [];

  @override
  void initState() {
    super.initState();
    loadDay();
  }

  Future<void> loadDay() async {
    final prefs = await SharedPreferences.getInstance();

    breakfast = _decode(prefs.getString("${widget.dateKey}_breakfast"));
    lunch = _decode(prefs.getString("${widget.dateKey}_lunch"));
    dinner = _decode(prefs.getString("${widget.dateKey}_dinner"));
    snacks = _decode(prefs.getString("${widget.dateKey}_snacks"));

    setState(() {});
  }

  List<Map<String, dynamic>> _decode(String? data) {
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tag: ${widget.dateKey}"),
        backgroundColor: const Color(0xFFF7F2EC),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F2EC),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _meal("Frühstück", breakfast),
          _meal("Mittagessen", lunch),
          _meal("Abendessen", dinner),
          _meal("Snacks", snacks),
        ],
      ),
    );
  }

  Widget _meal(String title, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontFamily: "NewFirst",
                fontSize: 22,
              )),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text("Keine Einträge"),
          ...items.map((e) => Text("${e["name"]} – ${e["grams"]} g")),
        ],
      ),
    );
  }
}
