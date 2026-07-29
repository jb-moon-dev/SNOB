import 'package:flutter/material.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('기록'),
      ),

      body: const Center(
        child: Text(
          '여행 기록 화면',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),

    );
  }
}