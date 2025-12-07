import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/entities/business_card.dart';
import '../providers/business_cards_provider.dart';
import '../widgets/header_background_modal.dart';
import '../../../../l10n/app_localizations.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final String? cardId;
  final Map<String, dynamic>? importedData;

  const CardEditorScreen({super.key, this.cardId, this.importedData});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedinUrlController = TextEditingController();

  // Social links
  final Map<String, TextEditingController> _socialControllers = {};

  // Type de carte
  late BusinessCardType _cardType;

  String? _photoUrl;
  String? _logoUrl;
  String? _cvUrl;
  String? _localPhotoPath;
  String? _localLogoPath;
  String? _cvFileName;
  String _headerBackgroundType = 'color';
  String? _headerBackgroundValue;
  String? _localHeaderImagePath;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingLogo = false;
  bool _isUploadingCv = false;
  bool _isUploadingHeaderImage = false;

  // Fonds prédéfinis
  static const List<Map<String, String>> _presetBackgrounds = [
    {'id': 'gradient_blue', 'name': 'Bleu', 'value': 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'},
    {'id': 'gradient_green', 'name': 'Vert', 'value': 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)'},
    {'id': 'gradient_orange', 'name': 'Orange', 'value': 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)'},
    {'id': 'gradient_purple', 'name': 'Violet', 'value': 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)'},
    {'id': 'gradient_dark', 'name': 'Sombre', 'value': 'linear-gradient(135deg, #232526 0%, #414345 100%)'},
    {'id': 'gradient_gold', 'name': 'Or', 'value': 'linear-gradient(135deg, #f5af19 0%, #f12711 100%)'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialise les controllers pour les réseaux sociaux
    for (final network in SocialNetwork.values) {
      _socialControllers[network.key] = TextEditingController();
    }

    // Initialiser le type de carte depuis les données importées ou par défaut
    if (widget.importedData != null && widget.importedData!['cardType'] != null) {
      _cardType = BusinessCardType.fromString(widget.importedData!['cardType']);
    } else {
      _cardType = BusinessCardType.professional;
    }

    if (widget.cardId != null) {
      _loadCard();
    } else if (widget.importedData != null) {
      _loadImportedData();
    }
  }

  void _loadImportedData() {
    final data = widget.importedData!;
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _companyController.text = data['company'] ?? '';
    _titleController.text = data['jobTitle'] ?? '';
    _websiteController.text = data['website'] ?? '';
  }

  void _loadCard() {
    final card = ref.read(cardByIdProvider(widget.cardId!));
    if (card != null) {
      _cardType = card.cardType;
      _firstNameController.text = card.firstName;
      _lastNameController.text = card.lastName;
      _titleController.text = card.jobTitle ?? '';
      _companyController.text = card.company ?? '';
      _emailController.text = card.email ?? '';
      _phoneController.text = card.phone ?? '';
      _mobileController.text = card.mobile ?? '';
      _websiteController.text = card.website ?? '';
      _addressController.text = card.address ?? '';
      _bioController.text = card.bio ?? '';
      _linkedinUrlController.text = card.linkedinUrl ?? '';
      _photoUrl = card.photoUrl;
      _logoUrl = card.logoUrl;
      _cvUrl = card.cvUrl;
      if (card.cvUrl != null && card.cvUrl!.isNotEmpty) {
        _cvFileName = 'CV.pdf';
      }

      // Charger le fond d'en-tête
      _headerBackgroundType = card.headerBackgroundType;
      _headerBackgroundValue = card.headerBackgroundValue;

      // Charger les réseaux sociaux
      for (final entry in card.socialLinks.entries) {
        if (_socialControllers.containsKey(entry.key)) {
          _socialControllers[entry.key]!.text = entry.value;
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _linkedinUrlController.dispose();
    for (final controller in _socialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.cardId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editCard : l10n.newCard),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCard,
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de profil
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: _getPhotoImage(),
                      child: _isUploadingPhoto
                          ? const CircularProgressIndicator()
                          : (_photoUrl == null && _localPhotoPath == null)
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isUploadingPhoto
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isUploadingPhoto ? Icons.hourglass_empty : Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Indicateur du type de carte
            _buildCardTypeIndicator(theme),

            const SizedBox(height: 24),

            // Fond d'en-tête (bouton compact qui ouvre le modal)
            _buildHeaderBackgroundButton(theme),

            const SizedBox(height: 24),

            // LinkedIn URL pour les cartes Profil (sur la première page)
            if (_cardType == BusinessCardType.profile) ...[
              _SectionHeader(title: 'Profil LinkedIn'),
              TextFormField(
                controller: _linkedinUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL LinkedIn',
                  hintText: 'https://linkedin.com/in/votre-profil',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Informations personnelles
            _SectionHeader(title: l10n.personalInfo),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.firstNameRequired,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
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
                    decoration: InputDecoration(
                      labelText: l10n.lastNameRequired,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.jobTitle,
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            // Champ Entreprise / Club ou Association (pas pour Profil)
            if (_cardType != BusinessCardType.profile)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: _cardType == BusinessCardType.personal
                            ? 'Club ou Association'
                            : l10n.company,
                        prefixIcon: Icon(
                          _cardType == BusinessCardType.personal
                              ? Icons.groups
                              : Icons.business,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isUploadingLogo
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Stack(
                          children: [
                            IconButton(
                              icon: _getLogoImage() != null
                                  ? CircleAvatar(
                                      radius: 16,
                                      backgroundImage: _getLogoImage(),
                                    )
                                  : Icon(
                                      Icons.add_photo_alternate,
                                      color: _logoUrl != null
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                              onPressed: _pickLogo,
                              tooltip: l10n.addLogo,
                            ),
                          ],
                        ),
                ],
              ),
            // Champ Bio pour les cartes Profil
            if (_cardType == BusinessCardType.profile) ...[
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ma Bio',
                  hintText: 'Décrivez-vous en quelques lignes...',
                  prefixIcon: Icon(Icons.person_outline),
                  alignLabelWithHint: true,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Coordonnées
            _SectionHeader(title: l10n.contactInfo),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.mobile,
                prefixIcon: const Icon(Icons.smartphone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.website,
                prefixIcon: const Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.address,
                prefixIcon: const Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // CV / Resume (uniquement pour les cartes Profil)
            if (_cardType == BusinessCardType.profile) ...[
              _SectionHeader(title: 'CV / Resume'),
              _buildCvSelector(theme, l10n),
              const SizedBox(height: 24),
            ],

            // Réseaux sociaux
            ExpansionTile(
              title: Text(l10n.socialNetworks),
              children: [
                ...SocialNetwork.values.map((network) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextFormField(
                      controller: _socialControllers[network.key],
                      decoration: InputDecoration(
                        labelText: network.displayName,
                        hintText: 'URL ou identifiant',
                        prefixIcon: Icon(_getSocialIcon(network)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            PrimaryButton(
              label: _isUploadingPhoto || _isUploadingLogo || _isUploadingCv
                  ? l10n.uploading
                  : (isEditing ? l10n.saveChanges : l10n.createCard),
              onPressed: (_isUploadingPhoto || _isUploadingLogo || _isUploadingCv) ? null : _saveCard,
              isLoading: _isLoading,
            ),

            if (!isEditing) ...[
              const SizedBox(height: 16),
              SecondaryButton(
                label: l10n.importFromContacts,
                icon: Icons.contacts,
                onPressed: _importFromContacts,
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getPhotoImage() {
    if (_photoUrl != null && _photoUrl!.startsWith('http')) {
      return NetworkImage(_photoUrl!);
    } else if (_localPhotoPath != null) {
      return FileImage(File(_localPhotoPath!));
    }
    return null;
  }

  ImageProvider? _getLogoImage() {
    if (_logoUrl != null && _logoUrl!.startsWith('http')) {
      return NetworkImage(_logoUrl!);
    } else if (_localLogoPath != null) {
      return FileImage(File(_localLogoPath!));
    }
    return null;
  }

  IconData _getSocialIcon(SocialNetwork network) {
    switch (network) {
      case SocialNetwork.linkedin:
        return Icons.work;
      case SocialNetwork.twitter:
        return Icons.alternate_email;
      case SocialNetwork.facebook:
        return Icons.facebook;
      case SocialNetwork.instagram:
        return Icons.camera_alt;
      case SocialNetwork.github:
        return Icons.code;
      case SocialNetwork.youtube:
        return Icons.play_arrow;
      case SocialNetwork.tiktok:
        return Icons.music_note;
      case SocialNetwork.whatsapp:
        return Icons.chat;
      case SocialNetwork.telegram:
        return Icons.send;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _localPhotoPath = image.path;
        _isUploadingPhoto = true;
      });

      try {
        final file = File(image.path);
        final userId = FirebaseAuthService.instance.currentUser?.uid ?? 'anonymous';
        final fileName = '${const Uuid().v4()}.jpg';
        final path = 'business_cards/$userId/photos/$fileName';

        final downloadUrl = await FirebaseStorageService.instance.uploadFile(
          path: path,
          file: file,
          metadata: {'contentType': 'image/jpeg'},
        );

        if (mounted) {
          setState(() {
            _photoUrl = downloadUrl;
            _isUploadingPhoto = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploadingPhoto = false;
            _localPhotoPath = null;
          });
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.photoUploadError}: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _localLogoPath = image.path;
        _isUploadingLogo = true;
      });

      try {
        final file = File(image.path);
        final userId = FirebaseAuthService.instance.currentUser?.uid ?? 'anonymous';
        final fileName = '${const Uuid().v4()}.jpg';
        final path = 'business_cards/$userId/logos/$fileName';

        final downloadUrl = await FirebaseStorageService.instance.uploadFile(
          path: path,
          file: file,
          metadata: {'contentType': 'image/jpeg'},
        );

        if (mounted) {
          setState(() {
            _logoUrl = downloadUrl;
            _isUploadingLogo = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploadingLogo = false;
            _localLogoPath = null;
          });
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.logoUploadError}: $e')),
          );
        }
      }
    }
  }

  Widget _buildCvSelector(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cvUrl != null
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _cvUrl != null ? Icons.description : Icons.upload_file,
              color: _cvUrl != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cvFileName ?? 'Ajouter un CV',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cvUrl != null
                      ? 'CV uploadé avec succès'
                      : 'PDF, DOC ou DOCX (max 5 MB)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _cvUrl != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_isUploadingCv)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (_cvUrl != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: () {
                  setState(() {
                    _cvUrl = null;
                    _cvFileName = null;
                  });
                },
                tooltip: 'Supprimer le CV',
              ),
            IconButton(
              icon: Icon(
                _cvUrl != null ? Icons.edit : Icons.add,
                color: theme.colorScheme.primary,
              ),
              onPressed: _pickCv,
              tooltip: _cvUrl != null ? 'Modifier le CV' : 'Ajouter un CV',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Vérifier la taille (max 5 MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le fichier est trop volumineux (max 5 MB)')),
            );
          }
          return;
        }

        setState(() {
          _cvFileName = file.name;
          _isUploadingCv = true;
        });

        try {
          final localFile = File(file.path!);
          final userId = FirebaseAuthService.instance.currentUser?.uid ?? 'anonymous';
          final fileName = '${const Uuid().v4()}.${file.extension}';
          final path = 'business_cards/$userId/cv/$fileName';

          final downloadUrl = await FirebaseStorageService.instance.uploadFile(
            path: path,
            file: localFile,
            metadata: {'contentType': _getContentType(file.extension ?? 'pdf')},
          );

          if (mounted) {
            setState(() {
              _cvUrl = downloadUrl;
              _isUploadingCv = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isUploadingCv = false;
              _cvFileName = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'upload du CV: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildCardTypeIndicator(ThemeData theme) {
    IconData icon;
    Color color;
    String label;

    switch (_cardType) {
      case BusinessCardType.professional:
        icon = Icons.business_center;
        color = Colors.blue;
        label = 'Carte Professionnelle';
        break;
      case BusinessCardType.personal:
        icon = Icons.people;
        color = Colors.green;
        label = 'Carte Personnelle';
        break;
      case BusinessCardType.profile:
        icon = Icons.person_pin;
        color = Colors.purple;
        label = 'Profil avec CV';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderBackgroundButton(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final result = await HeaderBackgroundModal.show(
          context,
          currentType: _headerBackgroundType,
          currentValue: _headerBackgroundValue,
        );
        if (result != null) {
          setState(() {
            _headerBackgroundType = result.type;
            _headerBackgroundValue = result.value;
            _localHeaderImagePath = result.localImagePath;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _headerBackgroundType == 'color' && _headerBackgroundValue != null
              ? _parseColor(_headerBackgroundValue!)
              : theme.colorScheme.primaryContainer,
          gradient: _headerBackgroundType == 'preset' && _headerBackgroundValue != null
              ? _parseGradient(_headerBackgroundValue!)
              : null,
          image: _headerBackgroundType == 'image' && (_headerBackgroundValue != null || _localHeaderImagePath != null)
              ? DecorationImage(
                  image: _localHeaderImagePath != null
                      ? FileImage(File(_localHeaderImagePath!))
                      : NetworkImage(_headerBackgroundValue!) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Overlay semi-transparent
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            // Contenu
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Personnaliser le fond d\'en-tête',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
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

  Widget _buildHeaderBackgroundSelector(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aperçu du fond actuel
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _headerBackgroundType == 'color' && _headerBackgroundValue != null
                ? _parseColor(_headerBackgroundValue!)
                : theme.colorScheme.primaryContainer,
            gradient: _headerBackgroundType == 'preset' && _headerBackgroundValue != null
                ? _parseGradient(_headerBackgroundValue!)
                : null,
            image: _headerBackgroundType == 'image' && (_headerBackgroundValue != null || _localHeaderImagePath != null)
                ? DecorationImage(
                    image: _localHeaderImagePath != null
                        ? FileImage(File(_localHeaderImagePath!))
                        : NetworkImage(_headerBackgroundValue!) as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _isUploadingHeaderImage
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : null,
        ),
        const SizedBox(height: 12),

        // Sélecteur de type
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'color', label: Text('Couleur'), icon: Icon(Icons.palette)),
            ButtonSegment(value: 'preset', label: Text('Prédéfini'), icon: Icon(Icons.gradient)),
            ButtonSegment(value: 'image', label: Text('Image'), icon: Icon(Icons.image)),
          ],
          selected: {_headerBackgroundType},
          onSelectionChanged: (selected) {
            setState(() {
              _headerBackgroundType = selected.first;
              if (_headerBackgroundType == 'color' && _headerBackgroundValue == null) {
                _headerBackgroundValue = '#6366F1';
              }
            });
          },
        ),
        const SizedBox(height: 16),

        // Options selon le type
        if (_headerBackgroundType == 'color') _buildColorPicker(theme),
        if (_headerBackgroundType == 'preset') _buildPresetSelector(theme),
        if (_headerBackgroundType == 'image') _buildImagePicker(theme),
      ],
    );
  }

  Widget _buildColorPicker(ThemeData theme) {
    final colors = [
      '#6366F1', '#8B5CF6', '#EC4899', '#EF4444', '#F97316',
      '#EAB308', '#22C55E', '#14B8A6', '#06B6D4', '#3B82F6',
      '#1E293B', '#64748B',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = _headerBackgroundValue == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _headerBackgroundValue = color;
            });
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _parseColor(color),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPresetSelector(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _presetBackgrounds.length,
        itemBuilder: (context, index) {
          final preset = _presetBackgrounds[index];
          final isSelected = _headerBackgroundValue == preset['value'];
          return Padding(
            padding: EdgeInsets.only(right: index < _presetBackgrounds.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _headerBackgroundValue = preset['value'];
                });
              },
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: _parseGradient(preset['value']!),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 3)
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        preset['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Dimensions recommandées: 1200 x 400 px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_headerBackgroundValue != null && _headerBackgroundType == 'image')
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _headerBackgroundValue = null;
                      _localHeaderImagePath = null;
                    });
                  },
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  label: Text('Supprimer', style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isUploadingHeaderImage ? null : _pickHeaderImage,
                icon: const Icon(Icons.upload),
                label: Text(_headerBackgroundValue != null ? 'Changer' : 'Choisir une image'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickHeaderImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _localHeaderImagePath = image.path;
        _isUploadingHeaderImage = true;
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
            _headerBackgroundValue = downloadUrl;
            _isUploadingHeaderImage = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploadingHeaderImage = false;
            _localHeaderImagePath = null;
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
      // Parse: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
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

  Future<void> _importFromContacts() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Vérifier et demander la permission avec permission_handler
      var status = await Permission.contacts.status;

      if (status.isDenied) {
        status = await Permission.contacts.request();
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.permissionRequired),
              content: Text(
                l10n.contactPermissionDesc,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.openSettings),
                ),
              ],
            ),
          );

          if (shouldOpen == true) {
            await openAppSettings();
          }
        }
        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.contactPermissionDenied)),
          );
        }
        return;
      }

      // Ouvrir le sélecteur de contact natif
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      // Récupérer les détails complets du contact
      final fullContact = await FlutterContacts.getContact(
        contact.id,
        withProperties: true,
        withPhoto: true,
      );

      if (fullContact == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.contactDetailsError)),
          );
        }
        return;
      }

      // Remplir les champs avec les données du contact
      setState(() {
        _firstNameController.text = fullContact.name.first;
        _lastNameController.text = fullContact.name.last;

        if (fullContact.emails.isNotEmpty) {
          _emailController.text = fullContact.emails.first.address;
        }

        if (fullContact.phones.isNotEmpty) {
          _phoneController.text = fullContact.phones.first.number;
          if (fullContact.phones.length > 1) {
            _mobileController.text = fullContact.phones[1].number;
          }
        }

        if (fullContact.organizations.isNotEmpty) {
          _companyController.text = fullContact.organizations.first.company;
          _titleController.text = fullContact.organizations.first.title;
        }

        if (fullContact.websites.isNotEmpty) {
          _websiteController.text = fullContact.websites.first.url;
        }

        if (fullContact.addresses.isNotEmpty) {
          _addressController.text = fullContact.addresses.first.address;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contactImportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _saveCard() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Collecte des réseaux sociaux
      final socialLinks = <String, String>{};
      for (final entry in _socialControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          socialLinks[entry.key] = entry.value.text;
        }
      }

      final notifier = ref.read(businessCardsProvider.notifier);

      if (widget.cardId != null) {
        // Mise à jour
        final existingCard = ref.read(cardByIdProvider(widget.cardId!));
        if (existingCard != null) {
          await notifier.updateCard(existingCard.copyWith(
            cardType: _cardType,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            jobTitle: _titleController.text.isEmpty ? null : _titleController.text,
            company: _companyController.text.isEmpty ? null : _companyController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            mobile: _mobileController.text.isEmpty ? null : _mobileController.text,
            website: _websiteController.text.isEmpty ? null : _websiteController.text,
            address: _addressController.text.isEmpty ? null : _addressController.text,
            bio: _bioController.text.isEmpty ? null : _bioController.text,
            linkedinUrl: _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text,
            photoUrl: _photoUrl,
            logoUrl: _logoUrl,
            cvUrl: _cardType == BusinessCardType.profile ? _cvUrl : null,
            headerBackgroundType: _headerBackgroundType,
            headerBackgroundValue: _headerBackgroundValue,
            socialLinks: socialLinks,
          ));
        }
      } else {
        // Création
        await notifier.createCard(
          cardType: _cardType,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          jobTitle: _titleController.text.isEmpty ? null : _titleController.text,
          company: _companyController.text.isEmpty ? null : _companyController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          mobile: _mobileController.text.isEmpty ? null : _mobileController.text,
          website: _websiteController.text.isEmpty ? null : _websiteController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          bio: _bioController.text.isEmpty ? null : _bioController.text,
          linkedinUrl: _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text,
          photoUrl: _photoUrl,
          logoUrl: _logoUrl,
          cvUrl: _cardType == BusinessCardType.profile ? _cvUrl : null,
          headerBackgroundType: _headerBackgroundType,
          headerBackgroundValue: _headerBackgroundValue,
          socialLinks: socialLinks,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cardSavedSuccess)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCard() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCard),
        content: Text(
          l10n.deleteCardConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(businessCardsProvider.notifier).deleteCard(widget.cardId!);
      if (mounted) {
        context.pop();
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
