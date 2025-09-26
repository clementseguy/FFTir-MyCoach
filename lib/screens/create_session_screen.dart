
import 'package:flutter/material.dart';
import '../widgets/session_form.dart';
import '../models/shooting_session.dart';


import '../services/session_service.dart';


class CreateSessionScreen extends StatelessWidget {
  final Map<String, dynamic>? initialSessionData;
  final bool isEdit;
  const CreateSessionScreen({Key? key, this.initialSessionData, this.isEdit = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final formKey = GlobalKey<SessionFormState>();
    ShootingSession? pendingSession; // tampon local avant sauvegarde
    return StatefulBuilder(
      builder: (ctx, setLocalState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Modifier session' : 'Nouvelle session'),
            actions: [
              IconButton(
                tooltip: 'Enregistrer',
                icon: Icon(Icons.save_outlined),
                onPressed: () async {
                  if (pendingSession == null) {
                    final state = formKey.currentState;
                    if (state == null) return;
                    final ok = state.validateAndBuild();
                    if (!ok) return;
                  }
                  try {
                    final s = pendingSession!;
                    if (isEdit) {
                      await SessionService().updateSession(s);
                    } else {
                      await SessionService().addSession(s);
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
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SessionForm(
              key: formKey,
              initialSessionData: initialSessionData,
              isEdit: isEdit,
              onSave: (session) {
                // Session valide retournée par le formulaire
                pendingSession = session;
              },
            ),
          ),
        );
      },
    );
  }
}
