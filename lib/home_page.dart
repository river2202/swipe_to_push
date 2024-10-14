import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swipe_to_push/second_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Home Page Body',
            ),
            TextButton(
                onPressed: _gotoSecondPage,
                child: const Text('Go to Second Page'))
          ],
        ),
      ),
    );
  }

  void _gotoSecondPage() {
    Navigator.push(context,
        CupertinoPageRoute(builder: ((context) => const SecondPage())));
  }
}
