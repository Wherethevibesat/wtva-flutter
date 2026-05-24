import 'package:flutter/material.dart';

import '../../../models/business/business_models.dart';
import '../../../services/business_repository.dart';
import '../../../services/business_service.dart';
import '../../../services/user_service.dart';
import '../../../services/venue_image_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/wtva/neighborhood_dropdown.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';

const _venueTypes = [
  'Nightclub',
  'Lounge',
  'Bar',
  'Restaurant',
  'Speakeasy',
  'Rooftop',
  'After Hours Club',
  'Hookah Lounge',
];

/// Add or edit a venue — image upload, hours, website & social links.
class BusinessVenueFormScreen extends StatefulWidget {
  const BusinessVenueFormScreen({super.key, this.createMode = false});

  final bool createMode;

  @override
  State<BusinessVenueFormScreen> createState() => _BusinessVenueFormScreenState();
}

class _BusinessVenueFormScreenState extends State<BusinessVenueFormScreen> {
  late BusinessVenueProfile _profile;
  late VenueOpeningHours _hours;
  late TextEditingController _name;
  late TextEditingController _address;
  late TextEditingController _phone;
  late TextEditingController _description;
  late TextEditingController _website;
  late TextEditingController _instagram;
  late TextEditingController _facebook;
  late TextEditingController _tiktok;
  late TextEditingController _twitter;
  String? _neighborhood;
  String _venueType = 'Nightclub';
  String? _imageUrl;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _profile = BusinessService.instance.profile;
    _hours = _profile.openingHours;
    _name = TextEditingController(text: _profile.venueName);
    _address = TextEditingController(text: _profile.address);
    _phone = TextEditingController(text: _profile.phone);
    _description = TextEditingController(text: _profile.description);
    _website = TextEditingController(text: _profile.websiteUrl);
    _instagram = TextEditingController(text: _profile.instagramUrl);
    _facebook = TextEditingController(text: _profile.facebookUrl);
    _tiktok = TextEditingController(text: _profile.tiktokUrl);
    _twitter = TextEditingController(text: _profile.twitterUrl);
    _neighborhood = _profile.neighborhood.isEmpty ? null : _profile.neighborhood;
    _venueType = _profile.venueType;
    _imageUrl = _profile.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _description.dispose();
    _website.dispose();
    _instagram.dispose();
    _facebook.dispose();
    _tiktok.dispose();
    _twitter.dispose();
    super.dispose();
  }

  BusinessVenueProfile _buildProfile() {
    return BusinessVenueProfile(
      venueName: _name.text.trim(),
      venueType: _venueType,
      address: _address.text.trim(),
      neighborhood: _neighborhood ?? '',
      phone: _phone.text.trim(),
      description: _description.text.trim(),
      imageUrl: _imageUrl,
      openingHours: _hours,
      websiteUrl: _website.text.trim(),
      instagramUrl: _instagram.text.trim(),
      facebookUrl: _facebook.text.trim(),
      tiktokUrl: _tiktok.text.trim(),
      twitterUrl: _twitter.text.trim(),
      categories: _profile.categories,
      serviceOptions: _profile.serviceOptions,
      tier: _profile.tier,
      verified: _profile.verified,
      verificationDocumentPath: _profile.verificationDocumentPath,
      verificationStatus: _profile.verificationStatus,
    );
  }

  Future<void> _pickImage() async {
    final ownerId = UserService().currentUser?.id;
    if (ownerId == null) return;
    final file = await VenueImageService.instance.pickImage();
    if (file == null) return;
    setState(() => _uploadingImage = true);
    final url = await VenueImageService.instance.uploadForOwner(ownerId: ownerId, file: file);
    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) _imageUrl = url;
    });
    if (url == null) {
      showWtvaSnack(context, 'Image upload failed');
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || (_neighborhood?.isEmpty ?? true)) {
      showWtvaSnack(context, 'Venue name and neighborhood are required');
      return;
    }
    setState(() => _saving = true);
    final profile = _buildProfile();
    final ownerId = UserService().currentUser?.id;
    try {
      if (widget.createMode && ownerId != null) {
        final venueId = await BusinessRepository.instance.createVenueForOwner(
          profile: profile,
          ownerId: ownerId,
        );
        if (venueId != null) {
          await BusinessRepository.instance.saveVenueProfile(profile, venueId: venueId);
        }
      } else {
        await BusinessService.instance.updateProfile(profile);
      }
      if (!mounted) return;
      Navigator.pop(context);
      showWtvaSnack(context, widget.createMode ? 'Venue added' : 'Venue saved');
    } catch (e) {
      if (mounted) showWtvaSnack(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(String dayKey, {required bool isOpen}) async {
    final slot = _hours.day(dayKey);
    final parts = (isOpen ? slot.open : slot.close)?.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts?.first ?? '21') ?? 21,
      minute: int.tryParse(parts?.length == 2 ? parts![1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final next = slot.copyWith(
      closed: false,
      open: isOpen ? value : (slot.open ?? '21:00'),
      close: isOpen ? (slot.close ?? '02:00') : value,
    );
    setState(() => _hours = _hours.copyDay(dayKey, next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text(
          widget.createMode ? 'Add venue' : 'Edit venue',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: AspectRatio(
              aspectRatio: 21 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: WtvaColors.dark400,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WtvaColors.dark300),
                  image: _imageUrl != null
                      ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageUrl == null
                    ? Center(
                        child: _uploadingImage
                            ? const CircularProgressIndicator()
                            : const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: WtvaColors.neutral300),
                                  SizedBox(height: 8),
                                  Text('Upload venue photo', style: TextStyle(color: WtvaColors.neutral300)),
                                ],
                              ),
                      )
                    : null,
              ),
            ),
          ),
          if (_imageUrl != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _uploadingImage ? null : _pickImage,
              child: Text(_uploadingImage ? 'Uploading…' : 'Replace photo'),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Venue name *'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _venueTypes.contains(_venueType) ? _venueType : _venueTypes.first,
            decoration: const InputDecoration(labelText: 'Venue type *'),
            items: _venueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _venueType = v ?? _venueType),
          ),
          const SizedBox(height: 16),
          NeighborhoodDropdown(
            value: _neighborhood,
            onChanged: (value) => setState(() => _neighborhood = value),
          ),
          const SizedBox(height: 16),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 16),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 24),
          Text('Opening hours', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...weekdayKeys.map((key) {
            final slot = _hours.day(key);
            return Card(
              color: WtvaColors.dark400,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(weekdayLabels[key]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Checkbox(
                          value: slot.closed,
                          onChanged: (v) {
                            setState(() {
                              _hours = _hours.copyDay(
                                key,
                                slot.copyWith(closed: v ?? false),
                              );
                            });
                          },
                        ),
                        const Text('Closed', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    if (!slot.closed)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _pickTime(key, isOpen: true),
                            child: Text('Opens ${slot.open ?? 'Set'}'),
                          ),
                          TextButton(
                            onPressed: () => _pickTime(key, isOpen: false),
                            child: Text('Closes ${slot.close ?? 'Set'}'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 24),
          Text('Website & social', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _website, decoration: const InputDecoration(labelText: 'Website')),
          const SizedBox(height: 12),
          TextField(controller: _instagram, decoration: const InputDecoration(labelText: 'Instagram')),
          const SizedBox(height: 12),
          TextField(controller: _facebook, decoration: const InputDecoration(labelText: 'Facebook')),
          const SizedBox(height: 12),
          TextField(controller: _tiktok, decoration: const InputDecoration(labelText: 'TikTok')),
          const SizedBox(height: 12),
          TextField(controller: _twitter, decoration: const InputDecoration(labelText: 'X (Twitter)')),
          const SizedBox(height: 28),
          WtvaGradientButton(
            label: _saving ? 'Saving…' : (widget.createMode ? 'Add venue' : 'Save changes'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
