import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/services/card_ocr_service.dart';
import '../../data/parsers/business_card_parser.dart';
import '../../domain/models/scanned_card_data.dart';

/// Écran de prévisualisation après capture de la carte
class ScanCardPreviewScreen extends StatefulWidget {
  final String imagePath;

  const ScanCardPreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ScanCardPreviewScreen> createState() => _ScanCardPreviewScreenState();
}

class _ScanCardPreviewScreenState extends State<ScanCardPreviewScreen> {
  final CardOcrService _ocrService = CardOcrService();
  final BusinessCardParser _parser = BusinessCardParser();

  bool _isProcessing = true;
  ScannedCardData? _scannedData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Extraction OCR
      final rawText = await _ocrService.extractTextFromImage(widget.imagePath);

      if (rawText.isEmpty) {
        setState(() {
          _error = 'Aucun texte détecté. Veuillez réessayer avec une meilleure qualité d\'image.';
          _isProcessing = false;
        });
        return;
      }

      // Parsing des champs (async avec Claude ou regex)
      final scannedData = await _parser.parse(rawText);

      setState(() {
        _scannedData = scannedData;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du traitement: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du scan'),
        actions: [
          if (!_isProcessing && _scannedData != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                context.push('/contacts/scan-card/edit', extra: {
                  'imagePath': widget.imagePath,
                  'scannedData': _scannedData,
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse de la carte en cours...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image capturée
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imagePath),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // Score de confiance
          if (_scannedData != null)
            _buildConfidenceIndicator(_scannedData!.confidence),

          const SizedBox(height: 16),

          // Champs détectés
          const Text(
            'Informations détectées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_scannedData != null) ...[
            if (_scannedData!.hasDetectedFields)
              ..._buildDetectedFields()
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aucun champ détecté automatiquement. Vous pourrez saisir les informations manuellement.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Texte brut
            ExpansionTile(
              title: const Text('Texte brut extrait'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _scannedData!.rawText,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Réessayer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/contacts/scan-card/edit', extra: {
                        'imagePath': widget.imagePath,
                        'scannedData': _scannedData,
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Éditer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).toInt();
    Color color;
    String label;

    if (confidence >= 0.7) {
      color = Colors.green;
      label = 'Excellente détection';
    } else if (confidence >= 0.4) {
      color = Colors.orange;
      label = 'Détection partielle';
    } else {
      color = Colors.red;
      label = 'Faible détection';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.analytics, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '$percentage% de confiance',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetectedFields() {
    final fields = <Widget>[];

    if (_scannedData!.firstName != null || _scannedData!.lastName != null) {
      fields.add(_buildFieldCard('Nom', _scannedData!.fullName, Icons.person));
    }
    if (_scannedData!.email != null) {
      fields.add(_buildFieldCard('Email', _scannedData!.email!, Icons.email));
    }
    if (_scannedData!.phone != null) {
      fields.add(_buildFieldCard('Téléphone Fixe', _scannedData!.phone!, Icons.phone));
    }
    if (_scannedData!.mobile != null) {
      fields.add(_buildFieldCard('Mobile', _scannedData!.mobile!, Icons.smartphone));
    }
    if (_scannedData!.company != null) {
      fields.add(_buildFieldCard('Entreprise', _scannedData!.company!, Icons.business));
    }
    if (_scannedData!.jobTitle != null) {
      fields.add(_buildFieldCard('Poste', _scannedData!.jobTitle!, Icons.work));
    }
    if (_scannedData!.website != null) {
      fields.add(_buildFieldCard('Site web', _scannedData!.website!, Icons.language));
    }
    if (_scannedData!.address != null) {
      fields.add(_buildFieldCard('Adresse', _scannedData!.address!, Icons.location_on));
    }

    return fields;
  }

  Widget _buildFieldCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
