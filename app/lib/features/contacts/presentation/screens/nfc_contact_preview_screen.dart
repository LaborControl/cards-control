import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/web_contact_extraction_service.dart';
import '../providers/contacts_provider.dart';

/// Écran de prévisualisation d'un contact extrait depuis une URL NFC
class NfcContactPreviewScreen extends ConsumerStatefulWidget {
  final ExtractedWebContact? extractedContact;
  final String sourceUrl;

  const NfcContactPreviewScreen({
    super.key,
    this.extractedContact,
    required this.sourceUrl,
  });

  @override
  ConsumerState<NfcContactPreviewScreen> createState() => _NfcContactPreviewScreenState();
}

class _NfcContactPreviewScreenState extends ConsumerState<NfcContactPreviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  String? _photoUrl;
  String? _companyLogoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final contact = widget.extractedContact;

    _firstNameController = TextEditingController(text: contact?.firstName ?? '');
    _lastNameController = TextEditingController(text: contact?.lastName ?? '');
    _companyController = TextEditingController(text: contact?.company ?? '');
    _jobTitleController = TextEditingController(text: contact?.jobTitle ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _mobileController = TextEditingController(text: contact?.mobile ?? '');
    _websiteController = TextEditingController(text: contact?.website ?? widget.sourceUrl);
    _addressController = TextEditingController(text: contact?.address ?? '');
    _notesController = TextEditingController(text: 'Source NFC: ${widget.sourceUrl}');

    _photoUrl = contact?.photoUrl;
    _companyLogoUrl = contact?.companyLogoUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(contactsProvider.notifier).createContact(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photoUrl: _photoUrl,
        companyLogoUrl: _companyLogoUrl,
        source: 'nfc',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/contacts');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contact = widget.extractedContact;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contact),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveContact,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicateur de confiance
                    if (contact != null)
                      _buildConfidenceIndicator(contact.confidence, theme),

                    const SizedBox(height: 16),

                    // Photo et logo
                    _buildImageSection(theme),

                    const SizedBox(height: 24),

                    // Informations détectées
                    Text(
                      l10n.contact,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Formulaire
                    _buildFormFields(l10n, theme),

                    const SizedBox(height: 16),

                    // URL source
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: theme.colorScheme.outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Source URL',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    widget.sourceUrl,
                                    style: theme.textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close),
                            label: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveContact,
                            icon: const Icon(Icons.save),
                            label: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence, ThemeData theme) {
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
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
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

  Widget _buildImageSection(ThemeData theme) {
    return Row(
      children: [
        // Photo de profil
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Photo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Logo entreprise
        if (_companyLogoUrl != null)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      _companyLogoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logo',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormFields(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        // Nom et prénom
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: l10n.firstName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if ((value == null || value.trim().isEmpty) &&
                      (_lastNameController.text.trim().isEmpty)) {
                    return l10n.error;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: l10n.lastName,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Entreprise et poste
        TextFormField(
          controller: _companyController,
          decoration: InputDecoration(
            labelText: l10n.company,
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _jobTitleController,
          decoration: InputDecoration(
            labelText: l10n.jobTitle,
            prefixIcon: const Icon(Icons.work_outline),
          ),
        ),

        const SizedBox(height: 16),

        // Contact
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: l10n.email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: l10n.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _mobileController,
          decoration: InputDecoration(
            labelText: l10n.mobile,
            prefixIcon: const Icon(Icons.smartphone),
          ),
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 16),

        // Web et adresse
        TextFormField(
          controller: _websiteController,
          decoration: InputDecoration(
            labelText: l10n.website,
            prefixIcon: const Icon(Icons.language),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: l10n.address,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: l10n.notes,
            prefixIcon: const Icon(Icons.notes),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
