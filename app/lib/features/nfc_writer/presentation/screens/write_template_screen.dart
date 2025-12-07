import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/animations/nfc_scan_animation.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../nfc_reader/data/datasources/nfc_native_datasource.dart';
import '../../../nfc_reader/presentation/providers/nfc_reader_provider.dart';
import '../../domain/entities/write_data.dart';
import '../providers/templates_provider.dart';

class WriteTemplateScreen extends ConsumerStatefulWidget {
  final String templateType;
  final String? initialUrl;
  final Map<String, dynamic>? initialData;

  const WriteTemplateScreen({
    super.key,
    required this.templateType,
    this.initialUrl,
    this.initialData,
  });

  @override
  ConsumerState<WriteTemplateScreen> createState() => _WriteTemplateScreenState();
}

class _WriteTemplateScreenState extends ConsumerState<WriteTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isWriting = false;
  bool _writeSuccess = false;
  String? _errorMessage;

  // Controllers pour les différents types
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsBodyController = TextEditingController();

  WifiAuthType _wifiAuthType = WifiAuthType.wpa2;
  bool _wifiHidden = false;

  @override
  void initState() {
    super.initState();
    _initializeFromData();
  }

  void _initializeFromData() {
    // Pré-remplir l'URL si fournie (depuis l'écran de partage de carte)
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }

    // Pré-remplir avec les données du modèle si fournies
    if (widget.initialData != null) {
      final data = widget.initialData!;
      switch (widget.templateType) {
        case 'url':
          _urlController.text = data['url'] ?? '';
          break;
        case 'text':
          _textController.text = data['text'] ?? '';
          break;
        case 'wifi':
          _ssidController.text = data['ssid'] ?? '';
          _passwordController.text = data['password'] ?? '';
          _wifiAuthType = WifiAuthType.values.firstWhere(
            (e) => e.name == data['authType'],
            orElse: () => WifiAuthType.wpa2,
          );
          _wifiHidden = data['hidden'] ?? false;
          break;
        case 'vcard':
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _organizationController.text = data['organization'] ?? '';
          _titleController.text = data['title'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _websiteController.text = data['website'] ?? '';
          break;
        case 'phone':
          _phoneController.text = data['phone'] ?? '';
          break;
        case 'email':
          _emailController.text = data['email'] ?? '';
          _textController.text = data['subject'] ?? '';
          _smsBodyController.text = data['body'] ?? '';
          break;
        case 'sms':
          _phoneController.text = data['phone'] ?? '';
          _smsBodyController.text = data['message'] ?? '';
          break;
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _smsBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final writeType = _getWriteType();

    return Scaffold(
      appBar: AppBar(
        title: Text(writeType.displayName),
        actions: [
          if (!_isWriting)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveAsTemplate,
              tooltip: 'Sauvegarder comme template',
            ),
        ],
      ),
      body: _isWriting
          ? _buildWritingState(theme)
          : _writeSuccess
              ? _buildSuccessState(theme)
              : _errorMessage != null
                  ? _buildErrorState(theme)
                  : _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Formulaire selon le type
            ..._buildFormFields(theme),

            const SizedBox(height: 24),

            // Estimation de la taille
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.memory, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Taille estimée: ~${_estimateSize()} bytes',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton d'écriture
            PrimaryButton(
              label: 'Écrire sur le tag',
              icon: Icons.edit,
              onPressed: _startWriting,
            ),

            const SizedBox(height: 16),

            // Options supplémentaires
            ExpansionTile(
              title: const Text('Options avancées'),
              children: [
                SwitchListTile(
                  title: const Text('Verrouiller après écriture'),
                  subtitle: const Text('Le tag ne pourra plus être modifié'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implémenter le verrouillage
                  },
                ),
                SwitchListTile(
                  title: const Text('Protection par mot de passe'),
                  subtitle: const Text('Nécessite un mot de passe pour modifier'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implémenter la protection
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(ThemeData theme) {
    switch (widget.templateType) {
      case 'url':
        return [
          TextFormField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
              prefixIcon: Icon(Icons.link),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une URL';
              }
              if (!value.startsWith('http://') && !value.startsWith('https://')) {
                return 'L\'URL doit commencer par http:// ou https://';
              }
              return null;
            },
          ),
        ];

      case 'text':
        return [
          TextFormField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Texte',
              hintText: 'Entrez votre message...',
              prefixIcon: Icon(Icons.text_fields),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer du texte';
              }
              return null;
            },
          ),
        ];

      case 'vcard':
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _organizationController,
            decoration: const InputDecoration(
              labelText: 'Entreprise',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre / Fonction',
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Site web',
              prefixIcon: Icon(Icons.language),
            ),
          ),
        ];

      case 'wifi':
        return [
          TextFormField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'Nom du réseau (SSID) *',
              prefixIcon: Icon(Icons.wifi),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du réseau';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WifiAuthType>(
            initialValue: _wifiAuthType,
            decoration: const InputDecoration(
              labelText: 'Type de sécurité',
              prefixIcon: Icon(Icons.security),
            ),
            items: WifiAuthType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _wifiAuthType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          if (_wifiAuthType != WifiAuthType.open)
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe *',
                prefixIcon: Icon(Icons.password),
              ),
              validator: (value) {
                if (_wifiAuthType != WifiAuthType.open &&
                    (value == null || value.isEmpty)) {
                  return 'Veuillez entrer le mot de passe';
                }
                return null;
              },
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Réseau masqué'),
            value: _wifiHidden,
            onChanged: (value) {
              setState(() => _wifiHidden = value);
            },
          ),
        ];

      case 'phone':
        return [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone *',
              hintText: '+33 6 12 34 56 78',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un numéro';
              }
              return null;
            },
          ),
        ];

      case 'email':
        return [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse email *',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une adresse email';
              }
              if (!value.contains('@')) {
                return 'Adresse email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Sujet (optionnel)',
              prefixIcon: Icon(Icons.subject),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _smsBodyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Corps du message (optionnel)',
              alignLabelWithHint: true,
            ),
          ),
        ];

      case 'sms':
        return [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone *',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un numéro';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _smsBodyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message (optionnel)',
              alignLabelWithHint: true,
            ),
          ),
        ];

      default:
        return [
          Text(
            'Type non supporté: ${widget.templateType}',
            style: theme.textTheme.bodyMedium,
          ),
        ];
    }
  }

  Widget _buildWritingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NfcScanAnimation(isScanning: true),
            const SizedBox(height: 32),
            Text(
              'Approchez le tag NFC...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tenez le tag contre l\'arrière de votre téléphone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: _cancelWriting,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Écriture réussie !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Les données ont été écrites sur le tag',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Écrire un autre tag',
              onPressed: () {
                setState(() => _writeSuccess = false);
              },
              isExpanded: false,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Erreur d\'écriture',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: () {
                setState(() => _errorMessage = null);
                _startWriting();
              },
              isExpanded: false,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _errorMessage = null);
              },
              child: const Text('Modifier les données'),
            ),
          ],
        ),
      ),
    );
  }

  WriteDataType _getWriteType() {
    switch (widget.templateType) {
      case 'url':
        return WriteDataType.url;
      case 'text':
        return WriteDataType.text;
      case 'vcard':
        return WriteDataType.vcard;
      case 'wifi':
        return WriteDataType.wifi;
      case 'phone':
        return WriteDataType.phone;
      case 'email':
        return WriteDataType.email;
      case 'sms':
        return WriteDataType.sms;
      case 'location':
        return WriteDataType.location;
      default:
        return WriteDataType.custom;
    }
  }

  int _estimateSize() {
    switch (widget.templateType) {
      case 'url':
        return _urlController.text.length + 10;
      case 'text':
        return _textController.text.length + 10;
      case 'vcard':
        return 100 +
            _firstNameController.text.length +
            _lastNameController.text.length +
            _organizationController.text.length +
            _phoneController.text.length +
            _emailController.text.length;
      case 'wifi':
        return _ssidController.text.length + _passwordController.text.length + 50;
      default:
        return 50;
    }
  }

  void _startWriting() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isWriting = true;
        _errorMessage = null;
      });

      try {
        final writeData = _buildNdefWriteData();
        final datasource = ref.read(nfcNativeDatasourceProvider);

        await datasource.startWriteSession(
          writeData: writeData,
          onWriteSuccess: () {
            if (mounted) {
              setState(() {
                _isWriting = false;
                _writeSuccess = true;
              });
            }
          },
          onWriteError: (error) {
            if (mounted) {
              setState(() {
                _isWriting = false;
                _errorMessage = error;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isWriting = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  NdefWriteData _buildNdefWriteData() {
    switch (widget.templateType) {
      case 'url':
        return NdefWriteData(
          type: NdefWriteType.url,
          url: _urlController.text,
        );
      case 'text':
        return NdefWriteData(
          type: NdefWriteType.text,
          text: _textController.text,
        );
      case 'wifi':
        return NdefWriteData(
          type: NdefWriteType.wifi,
          ssid: _ssidController.text,
          password: _passwordController.text,
          authType: _wifiAuthType.name,
          hidden: _wifiHidden,
        );
      case 'vcard':
        return NdefWriteData(
          type: NdefWriteType.vcard,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          organization: _organizationController.text,
          title: _titleController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          website: _websiteController.text,
        );
      case 'phone':
        return NdefWriteData(
          type: NdefWriteType.phone,
          phone: _phoneController.text,
        );
      case 'email':
        return NdefWriteData(
          type: NdefWriteType.email,
          email: _emailController.text,
          subject: _textController.text,
          body: _smsBodyController.text,
        );
      case 'sms':
        return NdefWriteData(
          type: NdefWriteType.sms,
          phone: _phoneController.text,
          message: _smsBodyController.text,
        );
      default:
        return NdefWriteData(
          type: NdefWriteType.text,
          text: 'Unknown type',
        );
    }
  }

  void _cancelWriting() async {
    try {
      final datasource = ref.read(nfcNativeDatasourceProvider);
      await datasource.stopWriteSession();
    } catch (_) {}

    if (mounted) {
      setState(() => _isWriting = false);
    }
  }

  void _saveAsTemplate() {
    if (_formKey.currentState!.validate()) {
      final nameController = TextEditingController();

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sauvegarder comme template'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom du template',
              hintText: _getDefaultTemplateName(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim().isEmpty
                    ? _getDefaultTemplateName()
                    : nameController.text.trim();

                final data = _buildTemplateData();
                await ref.read(templatesProvider.notifier).addTemplate(
                  name: name,
                  type: _getWriteType(),
                  data: data,
                );

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Template "$name" sauvegardé')),
                  );
                }
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      );
    }
  }

  String _getDefaultTemplateName() {
    switch (widget.templateType) {
      case 'url':
        final url = _urlController.text;
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          return uri?.host ?? 'Lien web';
        }
        return 'Lien web';
      case 'text':
        final text = _textController.text;
        return text.length > 20 ? '${text.substring(0, 20)}...' : text.isEmpty ? 'Texte' : text;
      case 'wifi':
        return 'WiFi ${_ssidController.text}';
      case 'vcard':
        return '${_firstNameController.text} ${_lastNameController.text}'.trim();
      case 'phone':
        return 'Appel ${_phoneController.text}';
      case 'email':
        return 'Email ${_emailController.text}';
      case 'sms':
        return 'SMS ${_phoneController.text}';
      default:
        return 'Template';
    }
  }

  Map<String, dynamic> _buildTemplateData() {
    switch (widget.templateType) {
      case 'url':
        return {'url': _urlController.text};
      case 'text':
        return {'text': _textController.text};
      case 'wifi':
        return {
          'ssid': _ssidController.text,
          'password': _passwordController.text,
          'authType': _wifiAuthType.name,
          'hidden': _wifiHidden,
        };
      case 'vcard':
        return {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'organization': _organizationController.text,
          'title': _titleController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'website': _websiteController.text,
        };
      case 'phone':
        return {'phone': _phoneController.text};
      case 'email':
        return {
          'email': _emailController.text,
          'subject': _textController.text,
          'body': _smsBodyController.text,
        };
      case 'sms':
        return {
          'phone': _phoneController.text,
          'message': _smsBodyController.text,
        };
      default:
        return {};
    }
  }
}
