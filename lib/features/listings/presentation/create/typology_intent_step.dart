import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';

class TypologyIntentStep extends ConsumerWidget {
  const TypologyIntentStep({super.key});

  static const _types = <_PropertyTypeOption>[
    _PropertyTypeOption(
      value: 'LAND',
      title: 'Land',
      subtitle: 'Plots, acreage & hillside sites',
      icon: Icons.landscape,
      badge: 'Topography',
    ),
    _PropertyTypeOption(
      value: 'HOUSE',
      title: 'House',
      subtitle: 'Single family, villa, architectural home',
      icon: Icons.villa,
    ),
    _PropertyTypeOption(
      value: 'APARTMENT',
      title: 'Apartment',
      subtitle: 'Modern condo, loft, penthouse',
      icon: Icons.apartment,
    ),
    _PropertyTypeOption(
      value: 'ROOM',
      title: 'Room',
      subtitle: 'Private suite, guest house, studio',
      icon: Icons.bed,
    ),
    _PropertyTypeOption(
      value: 'COMMERCIAL',
      title: 'Commercial',
      subtitle: 'Creative studio, retail, workspace',
      icon: Icons.storefront,
    ),
    _PropertyTypeOption(
      value: 'OTHER',
      title: 'Other',
      subtitle: 'Historic site, agricultural, sanctuary',
      icon: Icons.park,
    ),
  ];

  static const _intents = <_IntentOption>[
    _IntentOption(
      value: 'SALE',
      title: 'Sell',
      subtitle: 'Transfer ownership or estate title',
      beacon: 'Beacon: Slate',
      icon: Icons.sell,
    ),
    _IntentOption(
      value: 'RENT',
      title: 'Rent',
      subtitle: 'Long-term or annual tenancy',
      beacon: 'Beacon: Amber',
      icon: Icons.key,
    ),
    _IntentOption(
      value: 'LEASE',
      title: 'Lease',
      subtitle: 'Seasonal or ground lease',
      beacon: 'Beacon: Ochre',
      icon: Icons.description,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createListingProvider);
    final notifier = ref.read(createListingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: TerravaColors.primaryContainer),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: TerravaColors.secondaryFixed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'STEP 1 OF 3 · PROPERTY BASICS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What are you listing on the map?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
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
        const SizedBox(height: 16),
        const Text(
          'Choose the category that best describes your property. This determines how it will appear to buyers and renters.',
          style: TextStyle(color: TerravaColors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Select Property Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Text(
              'REQUIRED',
              style: TextStyle(
                color: TerravaColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.12,
          children: [
            for (final type in _types)
              _TypeCard(
                option: type,
                selected: state.propertyType == type.value,
                onTap: () => notifier.setPropertyType(type.value),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'What do you want to do?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the listing intent for precision beacon styling.',
          style: TextStyle(color: TerravaColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (final intent in _intents) ...[
          _IntentRow(
            option: intent,
            selected: state.transactionType == intent.value,
            onTap: () => notifier.setTransactionType(intent.value),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TerravaColors.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: TerravaColors.secondary,
                child: Icon(
                  Icons.lightbulb,
                  size: 16,
                  color: TerravaColors.onSecondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Friendly notice',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You can list multiple parcels or properties under your Terrava owner profile at any time.',
                      style: TextStyle(
                        color: TerravaColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertyTypeOption {
  const _PropertyTypeOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
}

class _IntentOption {
  const _IntentOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.beacon,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final String beacon;
  final IconData icon;
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PropertyTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      elevation: selected ? 3 : 0.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? TerravaColors.secondary.withValues(alpha: 0.12)
                          : TerravaColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      option.icon,
                      color: selected
                          ? TerravaColors.secondary
                          : TerravaColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: TerravaColors.secondary,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: TerravaColors.onSecondary,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      option.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (option.badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TerravaColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        option.badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: TerravaColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                option.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: TerravaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentRow extends StatelessWidget {
  const _IntentRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _IntentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amber = option.value != 'SALE';
    return Material(
      color: selected
          ? TerravaColors.surfaceContainerLowest
          : TerravaColors.surfaceContainerLow,
      elevation: selected ? 2 : 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: selected
                    ? TerravaColors.primary
                    : TerravaColors.surfaceContainerHighest,
                child: Icon(
                  option.icon,
                  color: selected
                      ? TerravaColors.onPrimary
                      : TerravaColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TerravaColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            option.beacon,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: amber
                                  ? TerravaColors.onTertiaryContainer
                                  : TerravaColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: selected
                    ? TerravaColors.primary
                    : TerravaColors.surfaceContainerHighest,
                child: Icon(
                  Icons.done,
                  size: 16,
                  color: selected
                      ? TerravaColors.onPrimary
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
