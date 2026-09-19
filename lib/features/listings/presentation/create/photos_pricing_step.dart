import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';

class PhotosPricingStep extends ConsumerStatefulWidget {
  const PhotosPricingStep({
    super.key,
    required this.onPreview,
    required this.onSubmit,
  });

  final VoidCallback onPreview;
  final VoidCallback onSubmit;

  @override
  ConsumerState<PhotosPricingStep> createState() => _PhotosPricingStepState();
}

class _PhotosPricingStepState extends ConsumerState<PhotosPricingStep> {
  late final TextEditingController _priceController;
  late final TextEditingController _agencyController;
  late final TextEditingController _legalController;
  late final TextEditingController _noteController;
  late final TextEditingController _interiorController;
  late final TextEditingController _landController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(createListingProvider);
    _priceController = TextEditingController(
      text: draft.price > 0 ? _commas(draft.price.round()) : '',
    );
    _agencyController = TextEditingController(
      text: draft.agencyFee == null || draft.agencyFee == 0
          ? ''
          : _commas(draft.agencyFee!.round()),
    );
    _legalController = TextEditingController(
      text: draft.legalFee == null || draft.legalFee == 0
          ? ''
          : _commas(draft.legalFee!.round()),
    );
    _noteController = TextEditingController(text: draft.description);
    _interiorController = TextEditingController(
      text: draft.propertySize == null
          ? ''
          : draft.propertySize!.round().toString(),
    );
    _landController = TextEditingController(
      text: draft.landSize == null ? '' : draft.landSize!.round().toString(),
    );
  }

  void _hydrateFromDraft(CreateListingState draft) {
    if (draft.price > 0) {
      _priceController.text = _commas(draft.price.round());
    }
    _agencyController.text = draft.agencyFee == null || draft.agencyFee == 0
        ? ''
        : _commas(draft.agencyFee!.round());
    _legalController.text = draft.legalFee == null || draft.legalFee == 0
        ? ''
        : _commas(draft.legalFee!.round());
    _noteController.text = draft.description;
    _interiorController.text = draft.propertySize == null
        ? ''
        : draft.propertySize!.round().toString();
    _landController.text = draft.landSize == null
        ? ''
        : draft.landSize!.round().toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _agencyController.dispose();
    _legalController.dispose();
    _noteController.dispose();
    _interiorController.dispose();
    _landController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(createListingProvider);
    final notifier = ref.read(createListingProvider.notifier);
    final user = ref.watch(authSessionProvider).asData?.value;
    final photos = draft.photos;

    ref.listen(createListingProvider.select((s) => s.listingId), (_, id) {
      if (id == null) return;
      _hydrateFromDraft(ref.read(createListingProvider));
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: TerravaColors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 15,
                color: TerravaColors.onSecondaryContainer,
              ),
              SizedBox(width: 6),
              Text(
                'STEP 3 OF 3 · REVIEW & PUBLISH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: TerravaColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Details, Photos & Pricing',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload visuals, set your terms, and submit for review. Listings go live on the map after approval.',
          style: TextStyle(color: TerravaColors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.photo_library, size: 20),
            const SizedBox(width: 6),
            Text(
              'Photos & Media',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${photos.length} of 20 added',
              style: const TextStyle(color: TerravaColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty) ...[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _CoverPhoto(
              photo: photos.first,
              onDelete: () => notifier.removePhoto(photos.first.key),
            ),
          ),
          const SizedBox(height: 10),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 4 / 3,
          children: [
            for (final photo in photos.skip(1))
              _GridPhoto(
                photo: photo,
                onDelete: () => notifier.removePhoto(photo.key),
              ),
            _AddPhotoCard(onTap: notifier.pickPhotos),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(0x1A006C4A),
                child: Icon(
                  Icons.insights,
                  size: 16,
                  color: TerravaColors.secondary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: TerravaColors.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: 'High resolution architectural photos ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: TerravaColors.onSurface,
                        ),
                      ),
                      TextSpan(text: 'attract more verified inquiries.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.tune, size: 20),
            const SizedBox(width: 6),
            Text(
              'Key Specifications',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!draft.isLand)
          Row(
            children: [
              Expanded(
                child: _CounterCard(
                  label: 'Bedrooms',
                  value: '${draft.bedrooms}',
                  onMinus: () => notifier.setBedrooms(draft.bedrooms - 1),
                  onPlus: () => notifier.setBedrooms(draft.bedrooms + 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CounterCard(
                  label: 'Bathrooms',
                  value: draft.bathrooms == draft.bathrooms.roundToDouble()
                      ? '${draft.bathrooms.round()}'
                      : draft.bathrooms.toStringAsFixed(1),
                  onMinus: () => notifier.setBathrooms(draft.bathrooms - 0.5),
                  onPlus: () => notifier.setBathrooms(draft.bathrooms + 0.5),
                ),
              ),
            ],
          ),
        if (!draft.isLand) const SizedBox(height: 10),
        Row(
          children: [
            if (!draft.isLand)
              Expanded(
                child: _MetricField(
                  label: 'Interior Floor',
                  suffix: 'sqm',
                  controller: _interiorController,
                  onChanged: (value) => notifier.setPropertySize(
                    double.tryParse(value.replaceAll(',', '')),
                  ),
                ),
              ),
            if (!draft.isLand) const SizedBox(width: 10),
            Expanded(
              child: _MetricField(
                label: 'Land size',
                suffix: 'sqm',
                controller: _landController,
                onChanged: (value) => notifier.setLandSize(
                  double.tryParse(value.replaceAll(',', '')),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.payments, size: 20),
            const SizedBox(width: 6),
            Text(
              'Pricing & Settlement',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 12),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.isRental
                    ? 'ANNUAL ${draft.transactionType == 'LEASE' ? 'LEASE' : 'RENT'} (NGN)'
                    : 'ASKING PRICE (NGN)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: TerravaColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: TerravaColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      '₦',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                        ],
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(
                            value.replaceAll(',', ''),
                          );
                          notifier.setPrice(parsed ?? 0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricField(
                      label: 'Agency fee',
                      suffix: 'NGN',
                      controller: _agencyController,
                      onChanged: (value) {
                        final parsed = double.tryParse(
                          value.replaceAll(',', ''),
                        );
                        notifier.setAgencyFee(parsed ?? 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricField(
                      label: 'Legal fee',
                      suffix: 'NGN',
                      controller: _legalController,
                      onChanged: (value) {
                        final parsed = double.tryParse(
                          value.replaceAll(',', ''),
                        );
                        notifier.setLegalFee(parsed ?? 0);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.badge, size: 20),
            const SizedBox(width: 6),
            Text(
              'Who is listing',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final option in const ['OWNER', 'AGENT', 'TENANT'])
              ChoiceChip(
                label: Text(listedByLabel(option)),
                selected: draft.listedBy == option,
                onSelected: (_) => notifier.setListedBy(option),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: TerravaColors.surfaceContainer,
                    backgroundImage: user?.profileImageUrl == null
                        ? null
                        : CachedNetworkImageProvider(user!.profileImageUrl!),
                    child: user?.profileImageUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Owner',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TerravaColors.secondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 13,
                                color: TerravaColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                listedByLabel(draft.listedBy),
                                style: const TextStyle(
                                  color: TerravaColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "OWNER'S ARCHITECTURAL NOTE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: TerravaColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 4,
                onChanged: notifier.setDescription,
                decoration: InputDecoration(
                  hintText:
                      'Tell prospective buyers what makes this space special...',
                  filled: true,
                  fillColor: TerravaColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: draft.submitting ? null : widget.onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: TerravaColors.primary,
              shape: const StadiumBorder(),
            ),
            child: Text(draft.submitting ? 'Submitting…' : 'Submit for review'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: FilledButton.tonal(
            onPressed: widget.onPreview,
            style: FilledButton.styleFrom(
              backgroundColor: TerravaColors.surfaceContainerHighest,
              foregroundColor: TerravaColors.onSurface,
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 18),
                SizedBox(width: 8),
                Text('Preview listing on map'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.photo, required this.onDelete});

  final DraftPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PhotoImage(photo: photo),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x66000000)],
              ),
            ),
          ),
          const Positioned(
            top: 10,
            left: 10,
            child: _Chip(icon: Icons.star, label: 'Cover photo'),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _IconBtn(icon: Icons.close, onTap: onDelete),
          ),
          if (photo.uploading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

class _GridPhoto extends StatelessWidget {
  const _GridPhoto({required this.photo, required this.onDelete});

  final DraftPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PhotoImage(photo: photo),
          Positioned(
            top: 8,
            right: 8,
            child: _IconBtn(icon: Icons.close, onTap: onDelete),
          ),
          if (photo.uploading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (photo.error != null)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Text(
                  'Upload failed',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: TerravaColors.surfaceContainerHighest,
              child: Icon(Icons.add_a_photo, color: TerravaColors.primary),
            ),
            SizedBox(height: 8),
            Text('+ Add Photos', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              'Up to 20 total',
              style: TextStyle(
                fontSize: 12,
                color: TerravaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.photo});

  final DraftPhoto photo;

  @override
  Widget build(BuildContext context) {
    if (photo.url != null) {
      return CachedNetworkImage(imageUrl: photo.url!, fit: BoxFit.cover);
    }
    if (photo.localPath != null && !kIsWeb) {
      return Image.file(File(photo.localPath!), fit: BoxFit.cover);
    }
    return const ColoredBox(color: TerravaColors.surfaceContainer);
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: TerravaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RoundIcon(icon: Icons.remove, onTap: onMinus),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              _RoundIcon(icon: Icons.add, onTap: onPlus, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: TerravaColors.onSurfaceVariant,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixText: suffix,
              isDense: true,
            ),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? TerravaColors.primary
          : TerravaColors.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: filled ? TerravaColors.onPrimary : TerravaColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TerravaColors.primary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 16)),
      ),
    );
  }
}

String _commas(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
