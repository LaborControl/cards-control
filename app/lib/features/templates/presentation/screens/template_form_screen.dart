import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/ai_token_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/image_generation_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../nfc_writer/domain/entities/write_data.dart';
import '../../../nfc_writer/presentation/providers/templates_provider.dart';
import '../../domain/services/template_ai_service.dart';

/// Écran pour créer/éditer un modèle de tag
class TemplateFormScreen extends ConsumerStatefulWidget {
  final String templateType;
  final String? templateId;
  final Map<String, dynamic>? initialData;
  final bool isEditMode;
  final String? templateName;

  const TemplateFormScreen({
    super.key,
    required this.templateType,
    this.templateId,
    this.initialData,
    this.isEditMode = false,
    this.templateName,
  });

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventAddressController = TextEditingController();

  // Nouveaux contrôleurs pour les types spéciaux
  final _googlePlaceIdController = TextEditingController();
  final _appStoreUrlController = TextEditingController();
  final _playStoreUrlController = TextEditingController();
  final _tipPaypalController = TextEditingController();
  final _tipStripeController = TextEditingController();
  final _tipCustomUrlController = TextEditingController();

  // ID Médical
  final _medicalNameController = TextEditingController();
  final _medicalBloodTypeController = TextEditingController();
  final _medicalAllergiesController = TextEditingController();
  final _medicalMedicationsController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicalEmergencyContactController = TextEditingController();
  final _medicalDoctorNameController = TextEditingController();
  final _medicalDoctorPhoneController = TextEditingController();

  // ID Animal
  final _petNameController = TextEditingController();
  final _petSpeciesController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petOwnerNameController = TextEditingController();
  final _petOwnerPhoneController = TextEditingController();
  final _petVetNameController = TextEditingController();
  final _petVetPhoneController = TextEditingController();
  final _petChipNumberController = TextEditingController();

  // ID Bagages
  final _luggageOwnerNameController = TextEditingController();
  final _luggageOwnerPhoneController = TextEditingController();
  final _luggageOwnerEmailController = TextEditingController();
  final _luggageAddressController = TextEditingController();
  final _luggageFlightNumberController = TextEditingController();

  WifiAuthType _wifiAuthType = WifiAuthType.wpa2;
  String _tipProvider = 'paypal';
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _wifiHidden = false;
  bool _isSaving = false;
  bool _isGeneratingAI = false;
  bool _isGeneratingImage = false;

  // Photo d'événement
  File? _eventImage;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFromData();
  }

  void _initializeFromData() {
    // Pré-remplir le nom du modèle en mode édition
    if (widget.templateName != null && widget.templateName!.isNotEmpty) {
      _templateNameController.text = widget.templateName!;
    }

    if (widget.initialData != null) {
      final data = widget.initialData!;

      // Pré-remplir selon le type
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
        case 'location':
          _latitudeController.text = data['latitude']?.toString() ?? '';
          _longitudeController.text = data['longitude']?.toString() ?? '';
          break;
        case 'event':
          _eventTitleController.text = data['title'] ?? '';
          _eventDescriptionController.text = data['description'] ?? '';
          _eventLocationController.text = data['location'] ?? '';
          _eventAddressController.text = data['address'] ?? '';
          _urlController.text = data['url'] ?? '';
          if (data['date'] != null) {
            _eventDate = DateTime.tryParse(data['date']);
          }
          if (data['time'] != null) {
            final timeParts = (data['time'] as String).split(':');
            if (timeParts.length >= 2) {
              _eventTime = TimeOfDay(
                hour: int.tryParse(timeParts[0]) ?? 0,
                minute: int.tryParse(timeParts[1]) ?? 0,
              );
            }
          }
          break;
        case 'googleReview':
          _googlePlaceIdController.text = data['placeId'] ?? '';
          break;
        case 'appDownload':
          _appStoreUrlController.text = data['appStoreUrl'] ?? '';
          _playStoreUrlController.text = data['playStoreUrl'] ?? '';
          break;
        case 'tip':
          _tipProvider = data['provider'] ?? 'paypal';
          _tipPaypalController.text = data['paypalUrl'] ?? '';
          _tipStripeController.text = data['stripeUrl'] ?? '';
          _tipCustomUrlController.text = data['customUrl'] ?? '';
          break;
        case 'medicalId':
          _medicalNameController.text = data['name'] ?? '';
          _medicalBloodTypeController.text = data['bloodType'] ?? '';
          _medicalAllergiesController.text = data['allergies'] ?? '';
          _medicalMedicationsController.text = data['medications'] ?? '';
          _medicalConditionsController.text = data['conditions'] ?? '';
          _medicalEmergencyContactController.text = data['emergencyContact'] ?? '';
          _medicalDoctorNameController.text = data['doctorName'] ?? '';
          _medicalDoctorPhoneController.text = data['doctorPhone'] ?? '';
          break;
        case 'petId':
          _petNameController.text = data['petName'] ?? '';
          _petSpeciesController.text = data['species'] ?? '';
          _petBreedController.text = data['breed'] ?? '';
          _petOwnerNameController.text = data['ownerName'] ?? '';
          _petOwnerPhoneController.text = data['ownerPhone'] ?? '';
          _petVetNameController.text = data['vetName'] ?? '';
          _petVetPhoneController.text = data['vetPhone'] ?? '';
          _petChipNumberController.text = data['chipNumber'] ?? '';
          break;
        case 'luggageId':
          _luggageOwnerNameController.text = data['ownerName'] ?? '';
          _luggageOwnerPhoneController.text = data['ownerPhone'] ?? '';
          _luggageOwnerEmailController.text = data['ownerEmail'] ?? '';
          _luggageAddressController.text = data['address'] ?? '';
          _luggageFlightNumberController.text = data['flightNumber'] ?? '';
          break;
      }
    } else {
      // Mode création : pré-remplir certains champs pour améliorer l'UX
      if (widget.templateType == 'url') {
        _urlController.text = 'https://';
      }
    }
  }

  /// Génère une description enrichie et une image avec l'IA
  Future<void> _generateWithAI(AppLocalizations l10n) async {
    if (_isGeneratingAI) return;

    // Vérifier qu'on a au moins un titre pour l'événement
    if (widget.templateType == 'event' && _eventTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventTitleRequired)),
      );
      return;
    }

    setState(() => _isGeneratingAI = true);

    try {
      final apiKey = ApiConfig.claudeApiKey;
      final tokenService = AITokenService();
      final aiService = TemplateAIService(
        apiKey: apiKey,
        tokenService: tokenService,
      );

      TemplateAIResult result;

      if (widget.templateType == 'event') {
        result = await aiService.enhanceEventDescription(
          title: _eventTitleController.text,
          date: _eventDate?.toIso8601String(),
          time: _eventTime != null
              ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}'
              : null,
          location: _eventLocationController.text,
          description: _eventDescriptionController.text,
        );

        // Générer ou améliorer l'image
        // Si l'utilisateur a chargé une photo, l'IA va la sublimer/mettre en situation
        // Sinon, l'IA génère une nouvelle image
        _generateEventImage();
      } else {
        result = await aiService.enhanceTemplateDescription(
          type: widget.templateType,
          data: _buildTemplateData(),
          currentName: _templateNameController.text,
        );
      }

      if (result.success && mounted) {
        // Appliquer les résultats
        if (result.enhancedDescription != null &&
            result.enhancedDescription!.isNotEmpty) {
          if (widget.templateType == 'event') {
            _eventDescriptionController.text = result.enhancedDescription!;
          }
        }

        if (result.suggestedName != null &&
            result.suggestedName!.isNotEmpty &&
            _templateNameController.text.isEmpty) {
          _templateNameController.text = result.suggestedName!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiGenerationSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? l10n.aiGenerationError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiGenerationError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  /// Génère ou améliore une image pour l'événement
  /// Si l'utilisateur a chargé une photo, elle sera améliorée/mise en situation
  /// Sinon, une nouvelle image sera générée
  Future<void> _generateEventImage() async {
    if (_isGeneratingImage) return;

    final l10n = AppLocalizations.of(context)!;
    final inputImage = _eventImage; // Sauvegarder avant de mettre le loading

    setState(() => _isGeneratingImage = true);

    try {
      final result = await ImageGenerationService.instance.generateEventImage(
        eventTitle: _eventTitleController.text,
        eventDescription: _eventDescriptionController.text,
        eventLocation: _eventLocationController.text,
        eventDate: _eventDate,
        inputImage: inputImage, // Passer la photo utilisateur si elle existe
      );

      if (mounted) {
        if (result.success && result.imageFile != null) {
          setState(() {
            _eventImage = result.imageFile;
          });
        } else {
          // Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? l10n.aiGenerationError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating event image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
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
    _latitudeController.dispose();
    _longitudeController.dispose();
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    _eventAddressController.dispose();
    // Nouveaux types
    _googlePlaceIdController.dispose();
    _appStoreUrlController.dispose();
    _playStoreUrlController.dispose();
    _tipPaypalController.dispose();
    _tipStripeController.dispose();
    _tipCustomUrlController.dispose();
    // Medical ID
    _medicalNameController.dispose();
    _medicalBloodTypeController.dispose();
    _medicalAllergiesController.dispose();
    _medicalMedicationsController.dispose();
    _medicalConditionsController.dispose();
    _medicalEmergencyContactController.dispose();
    _medicalDoctorNameController.dispose();
    _medicalDoctorPhoneController.dispose();
    // Pet ID
    _petNameController.dispose();
    _petSpeciesController.dispose();
    _petBreedController.dispose();
    _petOwnerNameController.dispose();
    _petOwnerPhoneController.dispose();
    _petVetNameController.dispose();
    _petVetPhoneController.dispose();
    _petChipNumberController.dispose();
    // Luggage ID
    _luggageOwnerNameController.dispose();
    _luggageOwnerPhoneController.dispose();
    _luggageOwnerEmailController.dispose();
    _luggageAddressController.dispose();
    _luggageFlightNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final writeType = _getWriteType();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode
            ? l10n.editTemplate
            : l10n.newTemplateType(writeType.displayName)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom du modèle
              Card(
                color: AppColors.primary.withValues(alpha: 0.1),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.templateName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _templateNameController,
                        decoration: InputDecoration(
                          hintText: _getDefaultTemplateName(l10n),
                          prefixIcon: const Icon(Icons.bookmark),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Formulaire selon le type
              Text(
                l10n.templateData,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              ..._buildFormFields(theme, l10n),

              const SizedBox(height: 32),

              // Bouton de sauvegarde
              PrimaryButton(
                label: widget.isEditMode ? l10n.update : l10n.createTemplateBtn,
                icon: Icons.save,
                isLoading: _isSaving,
                onPressed: _saveTemplate,
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEventImage(BuildContext context, AppLocalizations l10n) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _eventImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Widget _buildEventImagePicker(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.eventPhoto,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${l10n.optional})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isGeneratingImage ? null : () => _pickEventImage(context, l10n),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isGeneratingImage
                    ? const Color(0xFF8B5CF6)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: _isGeneratingImage ? 2 : 1,
              ),
            ),
            child: _isGeneratingImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ).createShader(bounds),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.generatingImage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : _eventImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _eventImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () => setState(() => _eventImage = null),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.addEventPhoto,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIButton(ThemeData theme, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _isGeneratingAI ? null : () => _generateWithAI(l10n),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: _isGeneratingAI ? Colors.grey : const Color(0xFF8B5CF6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: _isGeneratingAI
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
      label: Text(
        _isGeneratingAI ? l10n.loading : l10n.aiEnhanceDescription,
        style: TextStyle(
          color: _isGeneratingAI ? Colors.grey : const Color(0xFF8B5CF6),
        ),
      ),
    );
  }

  /// Construit le champ d'adresse avec bouton pour ouvrir Google Maps
  Widget _buildAddressAutocompleteField(ThemeData theme, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _eventAddressController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.address,
              hintText: '123 rue de la Paix, 75001 Paris',
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.filled(
            onPressed: () => _openGoogleMapsSearch(),
            icon: const Icon(Icons.map),
            tooltip: l10n.searchOnMap,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// Ouvre Google Maps pour rechercher une adresse
  Future<void> _openGoogleMapsSearch() async {
    final query = _eventAddressController.text.isNotEmpty
        ? _eventAddressController.text
        : _eventLocationController.text;

    final encodedQuery = Uri.encodeComponent(query.isNotEmpty ? query : 'France');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _buildFormFields(ThemeData theme, AppLocalizations l10n) {
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
                return l10n.enterUrl;
              }
              if (!value.startsWith('http://') && !value.startsWith('https://')) {
                return l10n.urlMustStartWith;
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
            decoration: InputDecoration(
              labelText: l10n.text,
              hintText: 'Entrez votre message...',
              prefixIcon: const Icon(Icons.text_fields),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.enterText;
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
                  decoration: InputDecoration(
                    labelText: '${l10n.firstName} *',
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
                  decoration: InputDecoration(
                    labelText: '${l10n.lastName} *',
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
            decoration: InputDecoration(
              labelText: l10n.company,
              prefixIcon: const Icon(Icons.business),
            ),
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
            decoration: InputDecoration(
              labelText: l10n.website,
              prefixIcon: const Icon(Icons.language),
            ),
          ),
        ];

      case 'wifi':
        return [
          TextFormField(
            controller: _ssidController,
            decoration: InputDecoration(
              labelText: l10n.ssidRequired,
              prefixIcon: const Icon(Icons.wifi),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WifiAuthType>(
            initialValue: _wifiAuthType,
            decoration: InputDecoration(
              labelText: l10n.securityType,
              prefixIcon: const Icon(Icons.security),
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
              decoration: InputDecoration(
                labelText: l10n.passwordRequired,
                prefixIcon: const Icon(Icons.password),
              ),
              validator: (value) {
                if (_wifiAuthType != WifiAuthType.open &&
                    (value == null || value.isEmpty)) {
                  return l10n.required;
                }
                return null;
              },
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.hiddenNetwork),
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
            decoration: InputDecoration(
              labelText: l10n.phoneRequired,
              hintText: '+33 6 12 34 56 78',
              prefixIcon: const Icon(Icons.phone),
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
            decoration: InputDecoration(
              labelText: l10n.emailRequired,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
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
            decoration: InputDecoration(
              labelText: l10n.subjectOptional,
              prefixIcon: const Icon(Icons.subject),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _smsBodyController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.bodyOptional,
              alignLabelWithHint: true,
            ),
          ),
        ];

      case 'sms':
        return [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneRequired,
              prefixIcon: const Icon(Icons.phone),
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
            decoration: InputDecoration(
              labelText: l10n.messageOptional,
              alignLabelWithHint: true,
            ),
          ),
        ];

      case 'location':
        return [
          TextFormField(
            controller: _latitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: l10n.latitudeRequired,
              hintText: '48.8566',
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              final lat = double.tryParse(value);
              if (lat == null || lat < -90 || lat > 90) {
                return 'Latitude invalide (-90 à 90)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _longitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: l10n.longitudeRequired,
              hintText: '2.3522',
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              final lon = double.tryParse(value);
              if (lon == null || lon < -180 || lon > 180) {
                return 'Longitude invalide (-180 à 180)';
              }
              return null;
            },
          ),
        ];

      case 'event':
        return [
          // Photo de l'événement
          _buildEventImagePicker(theme, l10n),
          const SizedBox(height: 16),
          TextFormField(
            controller: _eventTitleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.eventTitleRequired,
              hintText: 'Réunion, Conférence...',
              prefixIcon: const Icon(Icons.event_available),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Date et Heure
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateRequired,
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _eventDate != null
                          ? '${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.year}'
                          : l10n.select,
                      style: TextStyle(
                        color: _eventDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.time,
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    child: Text(
                      _eventTime != null
                          ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}'
                          : l10n.optional,
                      style: TextStyle(
                        color: _eventTime != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _eventLocationController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.location,
              hintText: 'Nom du lieu (ex: Salle des fêtes)',
              prefixIcon: const Icon(Icons.place),
            ),
          ),
          const SizedBox(height: 16),
          // Champ Adresse avec autocomplétion Google Places
          _buildAddressAutocompleteField(theme, l10n),
          const SizedBox(height: 16),
          TextFormField(
            controller: _eventDescriptionController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.description,
              hintText: 'Détails de l\'événement...',
              prefixIcon: const Icon(Icons.description),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          // Bouton IA pour améliorer la description
          _buildAIButton(theme, l10n),
          const SizedBox(height: 16),
          TextFormField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.linkOptional,
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link),
            ),
          ),
        ];

      case 'googleReview':
        return [
          TextFormField(
            controller: _googlePlaceIdController,
            decoration: InputDecoration(
              labelText: l10n.placeIdRequired,
              hintText: 'ChIJ...',
              prefixIcon: const Icon(Icons.star_rate),
              helperText: 'Trouvez votre Place ID sur Google Maps',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.googleReviewDesc,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];

      case 'appDownload':
        return [
          TextFormField(
            controller: _appStoreUrlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: '${l10n.appStore} (iOS)',
              hintText: 'https://apps.apple.com/...',
              prefixIcon: const Icon(Icons.apple),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _playStoreUrlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: '${l10n.playStore} (Android)',
              hintText: 'https://play.google.com/store/apps/...',
              prefixIcon: const Icon(Icons.android),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.cyan.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.cyan.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appDownloadDesc,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];

      case 'tip':
        return [
          DropdownButtonFormField<String>(
            initialValue: _tipProvider,
            decoration: InputDecoration(
              labelText: l10n.provider,
              prefixIcon: const Icon(Icons.payment),
            ),
            items: [
              DropdownMenuItem(value: 'paypal', child: Text(l10n.paypal)),
              DropdownMenuItem(value: 'stripe', child: Text(l10n.stripe)),
              DropdownMenuItem(value: 'custom', child: Text(l10n.customLink)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _tipProvider = value);
              }
            },
          ),
          const SizedBox(height: 16),
          if (_tipProvider == 'paypal')
            TextFormField(
              controller: _tipPaypalController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.paypalLink,
                hintText: 'https://paypal.me/votre_nom',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (_tipProvider == 'paypal' && (value == null || value.isEmpty)) {
                  return l10n.required;
                }
                return null;
              },
            ),
          if (_tipProvider == 'stripe')
            TextFormField(
              controller: _tipStripeController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.stripeLink,
                hintText: 'https://buy.stripe.com/...',
                prefixIcon: const Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (_tipProvider == 'stripe' && (value == null || value.isEmpty)) {
                  return l10n.required;
                }
                return null;
              },
            ),
          if (_tipProvider == 'custom')
            TextFormField(
              controller: _tipCustomUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.customUrl,
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.link),
              ),
              validator: (value) {
                if (_tipProvider == 'custom' && (value == null || value.isEmpty)) {
                  return l10n.enterUrl;
                }
                return null;
              },
            ),
        ];

      case 'medicalId':
        return [
          TextFormField(
            controller: _medicalNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.fullName,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _medicalBloodTypeController,
                  decoration: InputDecoration(
                    labelText: l10n.bloodType,
                    hintText: 'A+, B-, O+...',
                    prefixIcon: const Icon(Icons.bloodtype),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicalEmergencyContactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.emergencyContact,
                    hintText: '+33...',
                    prefixIcon: const Icon(Icons.emergency),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicalAllergiesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.allergies,
              hintText: 'Pénicilline, arachides...',
              prefixIcon: const Icon(Icons.warning_amber),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicalMedicationsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.medications,
              hintText: 'Insuline, Aspirine...',
              prefixIcon: const Icon(Icons.medication),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicalConditionsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.conditions,
              hintText: 'Diabète, Asthme...',
              prefixIcon: const Icon(Icons.medical_information),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _medicalDoctorNameController,
                  decoration: InputDecoration(
                    labelText: l10n.doctor,
                    prefixIcon: const Icon(Icons.local_hospital),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicalDoctorPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.doctorPhone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
              ),
            ],
          ),
        ];

      case 'petId':
        return [
          TextFormField(
            controller: _petNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.petName,
              prefixIcon: const Icon(Icons.pets),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _petSpeciesController,
                  decoration: InputDecoration(
                    labelText: l10n.species,
                    hintText: 'Chien, Chat...',
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _petBreedController,
                  decoration: InputDecoration(
                    labelText: l10n.breed,
                    hintText: 'Labrador...',
                    prefixIcon: const Icon(Icons.pets),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _petChipNumberController,
            decoration: InputDecoration(
              labelText: l10n.chipNumber,
              hintText: '250...',
              prefixIcon: const Icon(Icons.memory),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.owner,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _petOwnerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.ownerName,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _petOwnerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.ownerPhone,
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.vet,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _petVetNameController,
                  decoration: InputDecoration(
                    labelText: l10n.vetClinic,
                    prefixIcon: const Icon(Icons.local_hospital),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _petVetPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.vetPhone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
              ),
            ],
          ),
        ];

      case 'luggageId':
        return [
          TextFormField(
            controller: _luggageOwnerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.ownerName,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _luggageOwnerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneRequired,
              hintText: '+33...',
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.required;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _luggageOwnerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _luggageAddressController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.destinationAddress,
              hintText: 'Hôtel, adresse...',
              prefixIcon: const Icon(Icons.location_on),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _luggageFlightNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.flightNumberOptional,
              hintText: 'AF123',
              prefixIcon: const Icon(Icons.flight),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blueGrey.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.luggageDesc,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
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
      case 'event':
        return WriteDataType.event;
      case 'googleReview':
        return WriteDataType.googleReview;
      case 'appDownload':
        return WriteDataType.appDownload;
      case 'tip':
        return WriteDataType.tip;
      case 'medicalId':
        return WriteDataType.medicalId;
      case 'petId':
        return WriteDataType.petId;
      case 'luggageId':
        return WriteDataType.luggageId;
      default:
        return WriteDataType.custom;
    }
  }

  String _getDefaultTemplateName(AppLocalizations l10n) {
    switch (widget.templateType) {
      case 'url':
        final url = _urlController.text;
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          return uri?.host ?? l10n.webLink;
        }
        return l10n.webLink;
      case 'text':
        final text = _textController.text;
        return text.length > 20 ? '${text.substring(0, 20)}...' : text.isEmpty ? l10n.text : text;
      case 'wifi':
        return _ssidController.text.isEmpty ? l10n.wifiConfig : 'WiFi ${_ssidController.text}';
      case 'vcard':
        final name = '${_firstNameController.text} ${_lastNameController.text}'.trim();
        return name.isEmpty ? l10n.businessCard : name;
      case 'phone':
        return _phoneController.text.isEmpty ? l10n.phoneCall : '${l10n.phoneCall} ${_phoneController.text}';
      case 'email':
        return _emailController.text.isEmpty ? l10n.email : '${l10n.email} ${_emailController.text}';
      case 'sms':
        return _phoneController.text.isEmpty ? l10n.sms : '${l10n.sms} ${_phoneController.text}';
      case 'location':
        return l10n.gpsPosition;
      case 'event':
        return _eventTitleController.text.isEmpty ? l10n.event : _eventTitleController.text;
      case 'googleReview':
        return l10n.googleReview;
      case 'appDownload':
        return l10n.appDownload;
      case 'tip':
        return l10n.tip;
      case 'medicalId':
        return _medicalNameController.text.isEmpty ? l10n.medicalId : 'ID ${_medicalNameController.text}';
      case 'petId':
        return _petNameController.text.isEmpty ? l10n.petId : 'ID ${_petNameController.text}';
      case 'luggageId':
        return _luggageOwnerNameController.text.isEmpty ? l10n.luggageId : '${l10n.luggageId} ${_luggageOwnerNameController.text}';
      default:
        return l10n.template;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _eventTime = picked);
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
      case 'location':
        return {
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        };
      case 'event':
        return {
          'title': _eventTitleController.text,
          'date': _eventDate?.toIso8601String(),
          'time': _eventTime != null
              ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'location': _eventLocationController.text,
          'address': _eventAddressController.text,
          'description': _eventDescriptionController.text,
          'url': _urlController.text,
        };
      case 'googleReview':
        return {
          'placeId': _googlePlaceIdController.text,
        };
      case 'appDownload':
        return {
          'appStoreUrl': _appStoreUrlController.text,
          'playStoreUrl': _playStoreUrlController.text,
        };
      case 'tip':
        return {
          'provider': _tipProvider,
          'paypalUrl': _tipPaypalController.text,
          'stripeUrl': _tipStripeController.text,
          'customUrl': _tipCustomUrlController.text,
        };
      case 'medicalId':
        return {
          'name': _medicalNameController.text,
          'bloodType': _medicalBloodTypeController.text,
          'allergies': _medicalAllergiesController.text,
          'medications': _medicalMedicationsController.text,
          'conditions': _medicalConditionsController.text,
          'emergencyContact': _medicalEmergencyContactController.text,
          'doctorName': _medicalDoctorNameController.text,
          'doctorPhone': _medicalDoctorPhoneController.text,
        };
      case 'petId':
        return {
          'petName': _petNameController.text,
          'species': _petSpeciesController.text,
          'breed': _petBreedController.text,
          'ownerName': _petOwnerNameController.text,
          'ownerPhone': _petOwnerPhoneController.text,
          'vetName': _petVetNameController.text,
          'vetPhone': _petVetPhoneController.text,
          'chipNumber': _petChipNumberController.text,
        };
      case 'luggageId':
        return {
          'ownerName': _luggageOwnerNameController.text,
          'ownerPhone': _luggageOwnerPhoneController.text,
          'ownerEmail': _luggageOwnerEmailController.text,
          'address': _luggageAddressController.text,
          'flightNumber': _luggageFlightNumberController.text,
        };
      default:
        return {};
    }
  }

  Future<void> _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final l10n = AppLocalizations.of(context)!;

      try {
        final name = _templateNameController.text.trim().isEmpty
            ? _getDefaultTemplateName(l10n)
            : _templateNameController.text.trim();

        final data = _buildTemplateData();

        // Si c'est un événement avec une image, uploader l'image
        if (widget.templateType == 'event' && _eventImage != null) {
          final storageService = FirebaseStorageService.instance;
          final userId = FirebaseAuthService.instance.currentUser?.uid ?? 'anonymous';
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final path = 'event_images/$userId/$timestamp.jpg';

          final imageUrl = await storageService.uploadFile(
            path: path,
            file: _eventImage!,
            metadata: {'contentType': 'image/jpeg'},
          );

          data['imageUrl'] = imageUrl;
        }

        if (widget.isEditMode && widget.templateId != null) {
          // Mode édition : récupérer le modèle existant et le mettre à jour
          final templates = ref.read(templatesProvider).templates;
          final existingTemplate = templates.firstWhere(
            (t) => t.id == widget.templateId,
          );
          final updatedTemplate = existingTemplate.copyWith(
            name: name,
            data: data,
          );
          await ref.read(templatesProvider.notifier).updateTemplate(updatedTemplate);
        } else {
          // Mode création : ajouter un nouveau modèle
          await ref.read(templatesProvider.notifier).addTemplate(
            name: name,
            type: _getWriteType(),
            data: data,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditMode
                  ? l10n.templateUpdated(name)
                  : l10n.templateCreated(name)),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}
