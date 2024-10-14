import 'package:flutter/material.dart';

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Third Page',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(onPressed: _onTap, child: const Text('Back'))
          ],
        ),
      ),
    );
  }

  void _onTap() {
    Navigator.of(context).maybePop();
  }
}
