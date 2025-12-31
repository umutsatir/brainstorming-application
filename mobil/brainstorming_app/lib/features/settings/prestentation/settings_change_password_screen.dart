// import 'package:flutter/material.dart';

// class SettingsChangePasswordScreen extends StatefulWidget {
//   const SettingsChangePasswordScreen({super.key});

//   @override
//   State<SettingsChangePasswordScreen> createState() =>
//       _SettingsChangePasswordScreenState();
// }

// class _SettingsChangePasswordScreenState
//     extends State<SettingsChangePasswordScreen> {
//   final _oldController = TextEditingController();
//   final _newController = TextEditingController();
//   final _confirmController = TextEditingController();

//   @override
//   void dispose() {
//     _oldController.dispose();
//     _newController.dispose();
//     _confirmController.dispose();
//     super.dispose();
//   }

//   void _save() {
//     final oldPass = _oldController.text;
//     final newPass = _newController.text;
//     final confirmPass = _confirmController.text;

//     if (newPass.length < 6) {
//       ScaffoldMessenger.of(context)
//         ..hideCurrentSnackBar()
//         ..showSnackBar(
//           const SnackBar(
//             content: Text('New password should be at least 6 characters.'),
//           ),
//         );
//       return;
//     }

//     if (newPass != confirmPass) {
//       ScaffoldMessenger.of(context)
//         ..hideCurrentSnackBar()
//         ..showSnackBar(
//           const SnackBar(content: Text('Passwords do not match.')),
//         );
//       return;
//     }

//     // TODO: Backend entegrasyonu:
//     // POST /auth/change-password { oldPassword: oldPass, newPassword: newPass }

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         const SnackBar(
//           content: Text('Password changed (dummy – backend not wired yet).'),
//         ),
//       );

//     Navigator.of(context).pop(); // geri dön
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Change password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _oldController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'Current password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _newController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'New password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _confirmController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'Confirm new password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               height: 44,
//               child: ElevatedButton(
//                 onPressed: _save,
//                 child: const Text('Update password'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
