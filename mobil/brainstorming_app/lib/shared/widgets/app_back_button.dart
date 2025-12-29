import 'package:flutter/material.dart';

/// Uygulama genelinde kullanmak için ortak geri butonu.
/// Eğer Navigator stack'inde geri gidilecek sayfa yoksa hiç görünmez.
class AppBackButton extends StatelessWidget {
  final Color? color;

  const AppBackButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    if (!canPop) {
      // Root sayfalarda (örneğin TeamLeaderShell) geri butonu göstermeyelim
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, color: color),
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: 'Back',
    );
  }
}
