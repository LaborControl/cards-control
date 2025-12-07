import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firebase_service.dart';

/// Résultat du modal de personnalisation du fond
class HeaderBackgroundResult {
  final String type; // 'color', 'preset', 'image'
  final String? value;
  final String? localImagePath;

  const HeaderBackgroundResult({
    required this.type,
    this.value,
    this.localImagePath,
  });
}

/// Modal pour personnaliser le fond d'en-tête de la carte
class HeaderBackgroundModal extends StatefulWidget {
  final String currentType;
  final String? currentValue;

  const HeaderBackgroundModal({
    super.key,
    required this.currentType,
    this.currentValue,
  });

  static Future<HeaderBackgroundResult?> show(
    BuildContext context, {
    required String currentType,
    String? currentValue,
  }) {
    return showModalBottomSheet<HeaderBackgroundResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HeaderBackgroundModal(
        currentType: currentType,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<HeaderBackgroundModal> createState() => _HeaderBackgroundModalState();
}

class _HeaderBackgroundModalState extends State<HeaderBackgroundModal> {
  late String _type;
  String? _value;
  String? _localImagePath;
  bool _isUploading = false;

  // Fonds prédéfinis
  static const List<Map<String, String>> _presetBackgrounds = [
    {'id': 'gradient_blue', 'name': 'Bleu', 'value': 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'},
    {'id': 'gradient_green', 'name': 'Vert', 'value': 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)'},
    {'id': 'gradient_orange', 'name': 'Orange', 'value': 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)'},
    {'id': 'gradient_purple', 'name': 'Violet', 'value': 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)'},
    {'id': 'gradient_dark', 'name': 'Sombre', 'value': 'linear-gradient(135deg, #232526 0%, #414345 100%)'},
    {'id': 'gradient_gold', 'name': 'Or', 'value': 'linear-gradient(135deg, #f5af19 0%, #f12711 100%)'},
  ];

  static const List<String> _colors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F97316',
    '#EAB308', '#22C55E', '#14B8A6', '#06B6D4', '#3B82F6',
    '#1E293B', '#64748B',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    _value = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fond d\'en-tête',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isUploading ? null : () {
                      Navigator.pop(context, HeaderBackgroundResult(
                        type: _type,
                        value: _value,
                        localImagePath: _localImagePath,
                      ));
                    },
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ),

            // Preview
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _type == 'color' && _value != null
                    ? _parseColor(_value!)
                    : theme.colorScheme.primaryContainer,
                gradient: _type == 'preset' && _value != null
                    ? _parseGradient(_value!)
                    : null,
                image: _type == 'image' && (_value != null || _localImagePath != null)
                    ? DecorationImage(
                        image: _localImagePath != null
                            ? FileImage(File(_localImagePath!))
                            : NetworkImage(_value!) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : null,
            ),
            const SizedBox(height: 16),

            // Type selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'color', label: Text('Couleur'), icon: Icon(Icons.palette)),
                  ButtonSegment(value: 'preset', label: Text('Dégradé'), icon: Icon(Icons.gradient)),
                  ButtonSegment(value: 'image', label: Text('Image'), icon: Icon(Icons.image)),
                ],
                selected: {_type},
                onSelectionChanged: (selected) {
                  setState(() {
                    _type = selected.first;
                    if (_type == 'color' && _value == null) {
                      _value = '#6366F1';
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Options selon le type
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildOptions(theme),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(ThemeData theme) {
    switch (_type) {
      case 'color':
        return _buildColorPicker(theme);
      case 'preset':
        return _buildPresetSelector(theme);
      case 'image':
        return _buildImagePicker(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildColorPicker(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors.map((color) {
        final isSelected = _value == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _value = color;
            });
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _parseColor(color),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              boxShadow: isSelected
                  ? [BoxShadow(color: _parseColor(color).withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPresetSelector(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _presetBackgrounds.length,
      itemBuilder: (context, index) {
        final preset = _presetBackgrounds[index];
        final isSelected = _value == preset['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _value = preset['value'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: _parseGradient(preset['value']!),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    preset['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Dimensions recommandées: 1200 x 400 px',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_value != null || _localImagePath != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _value = null;
                      _localImagePath = null;
                    });
                  },
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  label: Text('Supprimer', style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: const Icon(Icons.upload),
                label: Text(_value != null || _localImagePath != null ? 'Changer' : 'Choisir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _localImagePath = image.path;
        _isUploading = true;
      });

      try {
        final file = File(image.path);
        final userId = FirebaseAuthService.instance.currentUser?.uid ?? 'anonymous';
        final fileName = '${const Uuid().v4()}.jpg';
        final path = 'business_cards/$userId/headers/$fileName';

        final downloadUrl = await FirebaseStorageService.instance.uploadFile(
          path: path,
          file: file,
          metadata: {'contentType': 'image/jpeg'},
        );

        if (mounted) {
          setState(() {
            _value = downloadUrl;
            _isUploading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _localImagePath = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'upload: $e')),
          );
        }
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  LinearGradient? _parseGradient(String cssGradient) {
    try {
      final regex = RegExp(r'linear-gradient\((\d+)deg,\s*([#\w]+)\s*\d+%,\s*([#\w]+)\s*\d+%\)');
      final match = regex.firstMatch(cssGradient);
      if (match != null) {
        final angle = double.parse(match.group(1)!) * 3.14159 / 180;
        final color1 = _parseColor(match.group(2)!);
        final color2 = _parseColor(match.group(3)!);
        return LinearGradient(
          begin: Alignment(-1 * math.cos(angle), -1 * math.sin(angle)),
          end: Alignment(math.cos(angle), math.sin(angle)),
          colors: [color1, color2],
        );
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }
}
