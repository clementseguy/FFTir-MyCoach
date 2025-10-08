import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/backup_service.dart';
import '../services/session_service.dart';
import '../config/app_config.dart';
import '../widgets/series_cards.dart'; // Pour TwoFistsIcon

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backup = BackupService();
    final sessionService = SessionService();
    final prefBox = Hive.box('app_preferences');
    String current = prefBox.get('default_hand_method', defaultValue: 'two');
    String? defaultCaliber = prefBox.get('default_caliber');
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Préférences Tir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prise par défaut (pistolet)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: prefBox.listenable(keys: ['default_hand_method']),
                    builder: (context, box, _) {
                      final val = box.get('default_hand_method', defaultValue: current);
                      return SegmentedButton<String>(
                        segments: [
                          const ButtonSegment(value: 'one', label: Text('1 main'), icon: Icon(Icons.front_hand)),
                          ButtonSegment(value: 'two', label: const Text('2 mains'), icon: const TwoFistsIcon(size:18)),
                        ],
                        selected: {val},
                        onSelectionChanged: (s) async {
                          await box.put('default_hand_method', s.first);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Prise par défaut: ${s.first == 'one' ? '1 main' : '2 mains'}')),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Calibre par défaut', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: prefBox.listenable(keys: ['default_caliber']),
                    builder: (context, box, _) {
                      final calib = (box.get('default_caliber', defaultValue: defaultCaliber) as String?) ?? '';
                      final ctrl = TextEditingController(text: calib);
                      final focus = FocusNode();
                      return RawAutocomplete<String>(
                        textEditingController: ctrl,
                        focusNode: focus,
                        optionsBuilder: (TextEditingValue tev) {
                          final list = AppConfig.I.calibers;
                          final q = tev.text.trim();
                          if (q.isEmpty) return list;
                          return list.where((c)=> c.toLowerCase().contains(q.toLowerCase()));
                        },
                        fieldViewBuilder: (context, c, f, onSubmit) {
                          return TextFormField(
                            controller: c,
                            focusNode: f,
                            decoration: const InputDecoration(labelText: 'Calibre (prérempli)'),
                            onFieldSubmitted: (_) => onSubmit(),
                            onChanged: (_) {},
                            onEditingComplete: () => onSubmit(),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final opts = options.toList();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: Theme.of(context).cardColor,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: opts.length,
                                  itemBuilder: (context, i) {
                                    final opt = opts[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(opt),
                                      onTap: () => onSelected(opt),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (val) async {
                          final nv = val.trim();
                          if (nv.isEmpty) {
                            await box.delete('default_caliber');
                          } else {
                            await box.put('default_caliber', nv);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(nv.isEmpty ? 'Préférence calibre effacée' : 'Calibre par défaut: $nv')),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Sauvegarde & Portabilité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exporter toutes les sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Génère un JSON: sessions (séries, synthèse, analyse) + objectifs.'),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_download),
                    label: Text('Exporter (.json)'),
                    onPressed: () async {
                      try {
                        final file = await backup.exportAllSessionsToJsonFile();
                        await Share.shareXFiles([XFile(file.path)], text: 'Export sessions MyCoach');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Enregistrer dans un dossier'),
                    onPressed: () async {
                      try {
                        final file = await backup.exportAllSessionsToUserFolder();
                        if (file == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Export annulé')),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fichier enregistré: ${file.path.split('/').last}')),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur sauvegarde: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"Exporter (.json)" permet de partager directement (mail, messagerie).\n'
                    '"Enregistrer dans un dossier" crée le fichier dans le dossier que tu sélectionnes. '
                    'Conseil: crée un dossier "MyCoachExports" sur ton téléphone.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importer des sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Sélectionne un fichier JSON exporté précédemment pour réintégrer les sessions.'),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_upload),
                    label: Text('Importer (.json)'),
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result == null || result.files.isEmpty) return;
                        final path = result.files.single.path;
                        if (path == null) return;
                        final content = await File(path).readAsString();
                        final imported = await backup.importSessionsFromJson(content);
                        final total = (await sessionService.getAllSessions()).length;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$imported sessions importées. Total: $total')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur import: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 28),
          Text('Avertissement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Les exports ne chiffrent pas les données. Ne partage pas le fichier si tu ne fais pas confiance au destinataire.' , style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}