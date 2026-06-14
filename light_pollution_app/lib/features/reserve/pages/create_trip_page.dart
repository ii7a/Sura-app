import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/trip_model.dart';
import '../providers/reserve_provider.dart';
import 'location_picker_page.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _groupSizeController = TextEditingController();
  final _durationController = TextEditingController();
  final _includedController = TextEditingController();

  DateTime? _selectedDate;
  int _bortleClass = 3;
  final List<String> _includedItems = [];

  // Cover image
  File? _coverImage;

  static const _gradientPresets = [
    [Color(0xFF000814), Color(0xFF001d3d), Color(0xFF1a0a00)],
    [Color(0xFF0a0a2e), Color(0xFF1a1a4e), Color(0xFF0d0d1a)],
    [Color(0xFF0a0020), Color(0xFF2d1b69), Color(0xFF0a0a2e)],
    [Color(0xFF0f0f2e), Color(0xFF1e1e4e), Color(0xFF15152e)],
    [Color(0xFF000000), Color(0xFF0d1b2a), Color(0xFF0a0a0a)],
    [Color(0xFF000814), Color(0xFF003566), Color(0xFF001d3d)],
  ];
  int _selectedGradient = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _groupSizeController.dispose();
    _durationController.dispose();
    _includedController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addIncludedItem() {
    final text = _includedController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _includedItems.add(text);
        _includedController.clear();
      });
    }
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  void _showImagePickerSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takeAPhoto),
              onTap: () {
                Navigator.pop(context);
                _pickCoverImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickCoverImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _locationController.text = result);
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectDate),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    final guideName = user?.name ?? 'Guide';
    final guideId = user?.id ?? '';
    final groupSize = int.tryParse(_groupSizeController.text) ?? 10;

    // Upload cover image if selected
    String? coverImageUrl;
    if (_coverImage != null) {
      try {
        final storage = StorageService();
        final path = 'trips/${DateTime.now().millisecondsSinceEpoch}.jpg';
        coverImageUrl = await storage.uploadImage(_coverImage!, path);
      } catch (_) {
        // Continue without cover image if upload fails
      }
    }

    final trip = StargazingTrip(
      id: '',
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      date: _selectedDate!,
      durationHours: int.tryParse(_durationController.text) ?? 4,
      guideName: guideName,
      guideId: guideId,
      guideAvatarUrl: user?.avatarUrl,
      guideRating: 5.0,
      bortleClass: _bortleClass,
      price: double.tryParse(_priceController.text) ?? 0,
      maxGroupSize: groupSize,
      spotsLeft: groupSize,
      description: _descriptionController.text.trim(),
      included: List.from(_includedItems),
      gradientColors: _gradientPresets[_selectedGradient],
      coverImageUrl: coverImageUrl,
    );

    try {
      await addTripToFirestore(trip);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.tripCreated),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('MMM d, yyyy', isArabic ? 'ar' : 'en');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          l10n.createTrip,
          style: font(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitTrip,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      l10n.post,
                      style: font(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cover image / gradient preview
            GestureDetector(
              onTap: _showImagePickerSheet,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: _coverImage != null
                      ? DecorationImage(
                          image: FileImage(_coverImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: _coverImage == null
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _gradientPresets[_selectedGradient],
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Dark overlay for text readability
                    if (_coverImage != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _coverImage != null
                                ? Icons.camera_alt
                                : Icons.add_photo_alternate,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 36,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.changeCoverImage,
                            style: font(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Gradient picker (shown only when no cover image)
            if (_coverImage == null) ...[
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gradientPresets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedGradient == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGradient = index),
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _gradientPresets[index],
                          ),
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.tripTitle,
                hintText: l10n.tripTitleHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),

            // Location with map picker
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.locationLabel,
                hintText: l10n.tripLocationHint,
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppColors.navy),
                  tooltip: l10n.pickFromMap,
                  onPressed: _openLocationPicker,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.tripDate,
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate != null
                      ? dateFormat.format(_selectedDate!)
                      : l10n.selectDate,
                  style: font(
                    color: _selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration + Price row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: l10n.duration,
                      suffixText: l10n.hours,
                      prefixIcon: const Icon(Icons.schedule),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: l10n.price,
                      suffix: SvgPicture.asset(
                        'assets/sar_symbol.svg',
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Group size + Bortle class row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _groupSizeController,
                    decoration: InputDecoration(
                      labelText: l10n.groupSize,
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.bortleClassLabel,
                      prefixIcon: const Icon(Icons.star, color: Colors.amber),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _bortleClass,
                        isDense: true,
                        items: List.generate(
                          9,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              '${i + 1}',
                              style: font(fontSize: 14),
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _bortleClass = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.aboutTrip,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 20),

            // What's included
            Text(
              l10n.whatsIncluded,
              style: font(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _includedController,
                    decoration: InputDecoration(
                      hintText: l10n.addItemHint,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addIncludedItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addIncludedItem,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _includedItems
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text(
                        entry.value,
                        style: font(fontSize: 13),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _includedItems.removeAt(entry.key));
                      },
                      backgroundColor: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
