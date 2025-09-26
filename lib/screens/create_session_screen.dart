
import 'package:flutter/material.dart';
import '../widgets/session_form.dart';


import '../services/session_service.dart';


class CreateSessionScreen extends StatelessWidget {
  final Map<String, dynamic>? initialSessionData;
  final bool isEdit;
  const CreateSessionScreen({Key? key, this.initialSessionData, this.isEdit = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SessionForm(
          initialSessionData: initialSessionData,
          isEdit: isEdit,
          onSave: (session) async {
            try {
              if (isEdit) {
                await SessionService().updateSession(session);
              } else {
                await SessionService().addSession(session);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Session enregistrée')),
                );
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur à l\'enregistrement')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
