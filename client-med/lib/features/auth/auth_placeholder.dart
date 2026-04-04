import 'package:flutter/material.dart';

/// Luồng đăng nhập / JWT — thay bằng màn hình thật + repository.
class AuthPlaceholder extends StatelessWidget {
  const AuthPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: const Center(child: Text('auth — JWT login')),
    );
  }
}
