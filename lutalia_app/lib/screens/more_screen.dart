import 'package:flutter/material.dart';
import '../theme/theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LutaliaTheme.creme,
      appBar: AppBar(title: const Text('Mehr')),
      body: ListView(
        children: const [
          _MoreItem(title: 'Einstellungen'),
          _MoreItem(title: 'Profil'),
          _MoreItem(title: 'Über Lutalia'),
          _MoreItem(title: 'Datenschutz'),
          _MoreItem(title: 'Impressum'),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final String title;

  const _MoreItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // später mit echten Seiten belegen
      },
    );
  }
}
