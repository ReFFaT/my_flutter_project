
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 235, 178, 13),
        ), // Отображение индикатора загрузки
      ),
    );
  }
}