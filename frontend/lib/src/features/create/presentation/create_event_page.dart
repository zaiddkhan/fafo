import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/categories/data/categories_repository.dart';
import 'package:fafu/src/features/categories/domain/category.dart';
import 'package:fafu/src/features/create/presentation/map_picker_page.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';

// Default map center when device location is unavailable (Bengaluru, per PRD).
const _defaultLat = 12.9716;
const _defaultLng = 77.5946;

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key, this.event});

  static const routeName = 'create-event';
  static const routePath = '/event/create';

  /// When provided, this page works as the full-screen event editor using the
  /// same UI as creation instead of the old compact edit dialog.
  final EventResponse? event;

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerContactController = TextEditingController();
  final _organizerInstagramController = TextEditingController();
  final _capacityController = TextEditingController();
  final _customEmojiController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<CategoryResponse> _categories = const [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;
  String? _categoriesError;

  EventType _eventType = EventType.normal;
  XFile? _selectedCoverImage;
  Uint8List? _coverBytes;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  double? _lat;
  double? _lng;
  String? _locationName;
  String? _address;
  String? _locationDetails;

  bool _submitting = false;
  String? _submitError;
  bool _published = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _organizerNameController.text = event.organizerName ?? '';
      _organizerContactController.text = event.organizerContact ?? '';
      _organizerInstagramController.text = event.organizerInstagram ?? '';
      _capacityController.text = event.capacity?.toString() ?? '';
      _customEmojiController.text = event.customEmoji ?? '';
      _selectedCategoryId = event.categoryId;
      _eventType = event.eventType == EventType.spotlight
          ? EventType.normal
          : event.eventType;
      _selectedDateTime = event.dateTime.toLocal();
      _lat = event.lat;
      _lng = event.lng;
      _locationName = event.locationName;
      _address = event.address;
      _locationDetails = event.locationDetails;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await ref
          .read(categoriesRepositoryProvider)
          .getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId ??= categories.isNotEmpty
            ? categories.first.id
            : null;
        _loadingCategories = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = e.message;
        _loadingCategories = false;
      });
    }
  }

  String get _dateLabel => DateFormat('EEE, MMM d').format(_selectedDateTime);

  String get _timeLabel => DateFormat('h:mm a').format(_selectedDateTime);

  Future<void> _pickCoverImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedCoverImage = image;
      _coverBytes = bytes;
    });
  }

  Future<void> _pickLocation() async {
    var centerLat = _lat ?? _defaultLat;
    var centerLng = _lng ?? _defaultLng;

    if (_lat == null) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition();
          centerLat = position.latitude;
          centerLng = position.longitude;
        }
      } catch (_) {
        // Fall back to the default center.
      }
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<MapPickResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: centerLat,
          initialLng: centerLng,
          initialName: _locationName,
          initialAddress: _address,
          initialDetails: _locationDetails,
          hasInitialPin: _lat != null && _lng != null,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _locationName = result.locationName;
      _address = result.address;
      _locationDetails = result.locationDetails;
    });
  }

  void _showDateTimePicker(BuildContext context) {
    var tempDateTime = _selectedDateTime;
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          color: AppColors.bgPrimary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                height: 56,
                color: AppColors.bgSecondary,
                child: Row(
                  children: [
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() => _selectedDateTime = tempDateTime);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 260,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: false,
                  initialDateTime: _selectedDateTime,
                  minimumDate: DateTime.now(),
                  onDateTimeChanged: (value) => tempDateTime = value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    final categoryId = _selectedCategoryId;
    final lat = _lat;
    final lng = _lng;
    final locationName = _locationName;

    final organizerName = _organizerNameController.text.trim();
    final organizerContact = _organizerContactController.text.trim();

    String? validation;
    if (title.isEmpty) {
      validation = 'Add a title for your event.';
    } else if (categoryId == null) {
      validation = 'Pick a category.';
    } else if (lat == null || lng == null || locationName == null) {
      validation = 'Set a location on the map.';
    } else if (organizerName.isEmpty) {
      validation =
          'Add the organizer\'s full name so attendees know who is hosting.';
    } else if (organizerContact.isEmpty) {
      validation = 'Add a public organizer contact (email or phone).';
    }
    if (validation != null) {
      setState(() => _submitError = validation);
      return;
    }

    int? capacity;
    final capacityText = _capacityController.text.trim();
    if (capacityText.isNotEmpty) {
      capacity = int.tryParse(capacityText);
      if (capacity == null || capacity <= 0) {
        setState(() => _submitError = 'Capacity must be a positive number.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final request = EventCreateRequest(
      title: title,
      description: optional(_descriptionController),
      categoryId: categoryId!,
      eventType: _eventType,
      customEmoji: optional(_customEmojiController),
      lat: lat!,
      lng: lng!,
      locationName: locationName!,
      address: _address,
      locationDetails: _locationDetails,
      dateTime: _selectedDateTime.toUtc(),
      capacity: capacity,
      organizerName: optional(_organizerNameController),
      organizerContact: optional(_organizerContactController),
      organizerInstagram: optional(_organizerInstagramController),
    );

    try {
      final repo = ref.read(eventsRepositoryProvider);
      final editingEvent = widget.event;
      if (editingEvent == null) {
        final created = await repo.createEvent(request);
        if (_selectedCoverImage != null) {
          await repo.uploadBanner(created.id, _selectedCoverImage!);
        }
      } else {
        await repo.updateEvent(
          editingEvent.id,
          EventUpdateRequest(
            title: request.title,
            description: request.description,
            categoryId: request.categoryId,
            eventType: request.eventType,
            customEmoji: request.customEmoji,
            lat: request.lat,
            lng: request.lng,
            locationName: request.locationName,
            address: request.address,
            locationDetails: request.locationDetails,
            dateTime: request.dateTime,
            capacity: request.capacity,
            organizerName: request.organizerName,
            organizerContact: request.organizerContact,
            organizerInstagram: request.organizerInstagram,
          ),
        );
        if (_selectedCoverImage != null) {
          await repo.uploadBanner(editingEvent.id, _selectedCoverImage!);
        }
      }
      if (!mounted) return;
      // Tell the Explore + Creator Dashboard tabs (persistent in the shell's
      // IndexedStack) to re-fetch so the new/edited event shows up immediately.
      bumpEventsRevision(ref);
      setState(() {
        _submitting = false;
        _published = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  void _resetForm() {
    if (_isEditing || Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _published = false;
      _titleController.clear();
      _descriptionController.clear();
      _organizerNameController.clear();
      _organizerContactController.clear();
      _organizerInstagramController.clear();
      _capacityController.clear();
      _customEmojiController.clear();
      _selectedCoverImage = null;
      _coverBytes = null;
      _eventType = EventType.normal;
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
      _lat = null;
      _lng = null;
      _locationName = null;
      _address = null;
      _locationDetails = null;
      _submitError = null;
      _selectedCategoryId = _categories.isNotEmpty
          ? _categories.first.id
          : null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    _organizerInstagramController.dispose();
    _capacityController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF1F1F1F)
        : AppColors.bgPrimary;
    final fieldBackground = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final fieldText = isDark ? Colors.white : const Color(0xFF181818);
    final hintColor = isDark
        ? const Color(0xFF9B9B9B)
        : const Color(0xFFB3B3B3);
    final outlineColor = isDark ? Colors.white : const Color(0xFF171717);
    final shadowColor = isDark ? Colors.white : const Color(0xFF2A2A2A);

    if (_published) {
      return _SuccessView(
        title: _isEditing ? 'Event Updated!' : 'Event Published!',
        body: _isEditing
            ? 'Your event details have been saved.'
            : 'Your event is now live and visible\nto everyone nearby.',
        onDone: _resetForm,
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
          children: [
            Text(
              _isEditing ? 'Edit Event' : 'Create Event',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.accentPrimary,
                fontSize: 30,
                height: 1,
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(label: 'Event Banner', textColor: fieldText),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCoverImage,
              child: _RaisedSurface(
                height: 132,
                radius: 8,
                shadowColor: shadowColor,
                outlineColor: outlineColor,
                child: Container(
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius: BorderRadius.circular(8),
                    image: _coverBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_coverBytes!),
                            fit: BoxFit.cover,
                          )
                        : widget.event?.bannerUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.event!.bannerUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      _selectedCoverImage == null &&
                          widget.event?.bannerUrl == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: hintColor,
                                size: 26,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Add a banner to your event',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Change Banner',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(label: 'Event Title', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _titleController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'Write title here',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Event Description', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              minHeight: 108,
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 1000,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'Write description here',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Date & Time', textColor: fieldText),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showDateTimePicker(context),
              child: _OutlinedFieldShell(
                backgroundColor: fieldBackground,
                outlineColor: outlineColor,
                shadowColor: shadowColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_dateLabel, $_timeLabel',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: fieldText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: hintColor, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Location', textColor: fieldText),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLocation,
              child: _OutlinedFieldShell(
                backgroundColor: fieldBackground,
                outlineColor: outlineColor,
                shadowColor: shadowColor,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: _locationName != null
                          ? AppColors.accentPrimary
                          : hintColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _locationName ?? 'Search for a place',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _locationName != null
                                  ? fieldText
                                  : hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_locationName != null &&
                              (_locationDetails != null || _address != null))
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _locationDetails ?? _address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: hintColor, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Event Type', textColor: fieldText),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('Normal', EventType.normal, isDark, outlineColor),
                _typeChip(
                  'Volunteering',
                  EventType.volunteering,
                  isDark,
                  outlineColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Category', textColor: fieldText),
            const SizedBox(height: 10),
            _buildCategorySelector(theme, isDark, outlineColor, hintColor),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Capacity (optional)', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'Leave blank for unlimited',
                ),
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(label: 'Pin emoji (optional)', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _customEmojiController,
                maxLength: 4,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'e.g. 🎸 — shown as your map pin',
                ).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(label: 'Organizer Verification', textColor: fieldText),
            const SizedBox(height: 8),
            _RaisedSurface(
              radius: 8,
              minHeight: 96,
              shadowColor: shadowColor,
              outlineColor: outlineColor,
              child: Container(
                width: double.infinity,
                color: fieldBackground,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.accentPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trust check for attendees',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: fieldText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your public organizer details, including Instagram, so the event page shows who is hosting it.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: hintColor,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(label: 'Organizer Full Name', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _organizerNameController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'Who is organizing this event?',
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(label: 'Organizer Contact', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _organizerContactController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  'Public email or phone',
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(label: 'Public Instagram Handle', textColor: fieldText),
            const SizedBox(height: 8),
            _OutlinedFieldShell(
              backgroundColor: fieldBackground,
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              child: TextField(
                controller: _organizerInstagramController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: fieldText,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  theme,
                  hintColor,
                  '@yourpublichandle',
                ),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Text(
                _submitError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE5484D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            _PublishButton(
              label: _isEditing ? 'Save Changes' : 'Publish Event',
              outlineColor: outlineColor,
              shadowColor: shadowColor,
              submitting: _submitting,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    ThemeData theme,
    Color hintColor,
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: hintColor,
        fontWeight: FontWeight.w600,
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _typeChip(
    String label,
    EventType type,
    bool isDark,
    Color outlineColor,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _eventType = type),
      child: _Chip(
        label: label,
        isSelected: _eventType == type,
        isDark: isDark,
        outlineColor: outlineColor,
      ),
    );
  }

  Widget _buildCategorySelector(
    ThemeData theme,
    bool isDark,
    Color outlineColor,
    Color hintColor,
  ) {
    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPrimary,
          ),
        ),
      );
    }
    if (_categoriesError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _categoriesError!,
              style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
            ),
          ),
          TextButton(onPressed: _loadCategories, child: const Text('Retry')),
        ],
      );
    }
    if (_categories.isEmpty) {
      return Text(
        'No categories available yet.',
        style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((c) {
        final selected = _selectedCategoryId == c.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoryId = c.id),
          child: _Chip(
            label: '${c.emoji} ${c.name}',
            isSelected: selected,
            isDark: isDark,
            outlineColor: outlineColor,
          ),
        );
      }).toList(),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.label,
    required this.outlineColor,
    required this.shadowColor,
    required this.submitting,
    required this.onTap,
  });

  final String label;
  final Color outlineColor;
  final Color shadowColor;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(8, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: shadowColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            AppPressable(
              onTap: submitting ? null : onTap,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: outlineColor, width: 1.6),
                ),
                alignment: Alignment.center,
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.outlineColor,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: outlineColor, width: 1.1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isSelected
              ? Colors.white
              : isDark
              ? Colors.white
              : const Color(0xFF181818),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _OutlinedFieldShell extends StatelessWidget {
  const _OutlinedFieldShell({
    required this.child,
    required this.backgroundColor,
    required this.outlineColor,
    required this.shadowColor,
    this.minHeight = 38,
  });

  final Widget child;
  final Color backgroundColor;
  final Color outlineColor;
  final Color shadowColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    const offset = 2.5;

    return Padding(
      padding: const EdgeInsets.only(right: offset, bottom: offset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(offset, offset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: outlineColor, width: 1.6),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RaisedSurface extends StatelessWidget {
  const _RaisedSurface({
    required this.child,
    required this.radius,
    required this.shadowColor,
    required this.outlineColor,
    this.minHeight,
    this.height,
  });

  final Widget child;
  final double radius;
  final Color shadowColor;
  final Color outlineColor;
  final double? minHeight;
  final double? height;

  @override
  Widget build(BuildContext context) {
    const offset = 8.0;

    return Padding(
      padding: EdgeInsets.only(right: offset, bottom: offset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(offset, offset),
            child: Container(
              constraints: minHeight != null
                  ? BoxConstraints(minHeight: minHeight!)
                  : null,
              height: height,
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          Container(
            constraints: minHeight != null
                ? BoxConstraints(minHeight: minHeight!)
                : null,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: outlineColor, width: 1.6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.title,
    required this.body,
    required this.onDone,
  });

  final String title;
  final String body;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(title, style: theme.textTheme.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.featured,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
