import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'third_page.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Second Page',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(onPressed: _onTap, child: const Text('Go to Third Page'))
          ],
        ),
      ),
    );
  }

  void _onTap() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (context) => const ThirdPage()));
  }
}
