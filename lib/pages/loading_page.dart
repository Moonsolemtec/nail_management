import 'dart:async';
import 'package:flutter/material.dart';
import 'landing_page.dart'; // importa sua LandingPage

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // Aguarda 3 segundos antes de redirecionar
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LandingPage(
            onToggleTheme: () {}, // passa a função que você já usa no tema
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Título
            const Text(
              "Nail Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Barra de progresso
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
