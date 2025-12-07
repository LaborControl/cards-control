import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact.dart';
import '../providers/contacts_provider.dart';

class ContactEditScreen extends ConsumerStatefulWidget {
  final Contact? contact;

  const ContactEditScreen({super.key, this.contact});

  @override
  ConsumerState<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends ConsumerState<ContactEditScreen> {
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
  File? _localPhotoFile;
  File? _localLogoFile;
  bool _isUploading = false;
  bool _isSaving = false;
  String _selectedCategoryId = '';

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.contact?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.contact?.lastName ?? '');
    _companyController = TextEditingController(text: widget.contact?.company ?? '');
    _jobTitleController = TextEditingController(text: widget.contact?.jobTitle ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _mobileController = TextEditingController(text: widget.contact?.mobile ?? '');
    _websiteController = TextEditingController(text: widget.contact?.website ?? '');
    _addressController = TextEditingController(text: widget.contact?.address ?? '');
    _notesController = TextEditingController(text: widget.contact?.notes ?? '');
    _photoUrl = widget.contact?.photoUrl;
    _companyLogoUrl = widget.contact?.companyLogoUrl;
    _selectedCategoryId = widget.contact?.category ?? '';
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

  Future<void> _pickImage(bool isPhoto) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (isPhoto) {
          _localPhotoFile = File(pickedFile.path);
        } else {
          _localLogoFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File file, String folder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/$folder/$timestamp.jpg');

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _saveContact() async {
    if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _isUploading = _localPhotoFile != null || _localLogoFile != null;
    });

    try {
      // Upload images if needed
      String? finalPhotoUrl = _photoUrl;
      String? finalLogoUrl = _companyLogoUrl;

      if (_localPhotoFile != null) {
        finalPhotoUrl = await _uploadImage(_localPhotoFile!, 'contact_photos');
      }
      if (_localLogoFile != null) {
        finalLogoUrl = await _uploadImage(_localLogoFile!, 'company_logos');
      }

      setState(() => _isUploading = false);

      if (isEditing) {
        await ref.read(contactsProvider.notifier).updateContact(
          widget.contact!.copyWith(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            company: _companyController.text.isNotEmpty ? _companyController.text : null,
            jobTitle: _jobTitleController.text.isNotEmpty ? _jobTitleController.text : null,
            email: _emailController.text.isNotEmpty ? _emailController.text : null,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
            mobile: _mobileController.text.isNotEmpty ? _mobileController.text : null,
            website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
            address: _addressController.text.isNotEmpty ? _addressController.text : null,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            photoUrl: finalPhotoUrl,
            companyLogoUrl: finalLogoUrl,
            category: _selectedCategoryId,
          ),
        );
      } else {
        await ref.read(contactsProvider.notifier).createContact(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          company: _companyController.text.isNotEmpty ? _companyController.text : null,
          jobTitle: _jobTitleController.text.isNotEmpty ? _jobTitleController.text : null,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          mobile: _mobileController.text.isNotEmpty ? _mobileController.text : null,
          website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
          address: _addressController.text.isNotEmpty ? _addressController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          photoUrl: finalPhotoUrl,
          companyLogoUrl: finalLogoUrl,
          category: _selectedCategoryId,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? l10n.contactUpdated : l10n.contactAdded)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _photoUrl = null;
      _localPhotoFile = null;
    });
  }

  void _removeLogo() {
    setState(() {
      _companyLogoUrl = null;
      _localLogoFile = null;
    });
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final categories = ref.watch(contactCategoriesProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategoryId == category.id;
        return FilterChip(
          selected: isSelected,
          label: Text(category.label),
          avatar: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              _selectedCategoryId = selected ? category.id : '';
            });
          },
          selectedColor: category.color.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: isSelected ? category.color : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          checkmarkColor: category.color,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editContact : l10n.addContact),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveContact,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Photo et Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Photo du contact
                _ImagePickerWidget(
                  label: l10n.contactPhoto,
                  imageUrl: _photoUrl,
                  localFile: _localPhotoFile,
                  onPick: () => _pickImage(true),
                  onRemove: _removePhoto,
                  isCircle: true,
                ),
                // Logo entreprise
                _ImagePickerWidget(
                  label: l10n.companyLogo,
                  imageUrl: _companyLogoUrl,
                  localFile: _localLogoFile,
                  onPick: () => _pickImage(false),
                  onRemove: _removeLogo,
                  isCircle: false,
                ),
              ],
            ),

            if (_isUploading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Upload des images...',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Informations personnelles
            Text(
              l10n.personalInfo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: l10n.firstName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: l10n.lastName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Catégorie
            Text(
              'Catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(theme),
            const SizedBox(height: 24),

            // Informations professionnelles
            Text(
              l10n.professionalInfo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: l10n.company,
                prefixIcon: const Icon(Icons.business),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: l10n.jobTitle,
                prefixIcon: const Icon(Icons.work_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Coordonnées
            Text(
              l10n.contactInfo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                      labelText: l10n.mobile,
                      prefixIcon: const Icon(Icons.smartphone),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: l10n.website,
                prefixIcon: const Icon(Icons.language),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.address,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              l10n.notes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Bouton Enregistrer
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveContact,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final File? localFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool isCircle;

  const _ImagePickerWidget({
    required this.label,
    this.imageUrl,
    this.localFile,
    required this.onPick,
    required this.onRemove,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null || localFile != null;

    Widget imageWidget;
    if (localFile != null) {
      imageWidget = Image.file(
        localFile!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    } else if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    } else {
      imageWidget = _buildPlaceholder(theme);
    }

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircle ? null : BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: isCircle
                    ? ClipOval(child: imageWidget)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageWidget,
                      ),
              ),
            ),
            if (hasImage)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!hasImage)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onPick,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isCircle ? null : BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.add_a_photo,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 100,
      height: 100,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        isCircle ? Icons.person : Icons.business,
        size: 40,
        color: theme.colorScheme.outline,
      ),
    );
  }
}
