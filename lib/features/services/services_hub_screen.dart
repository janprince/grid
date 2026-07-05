import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../home/widgets/emergency_sheet.dart';
import 'booking_flow_screen.dart';

class ServicesHubScreen extends ConsumerStatefulWidget {
  const ServicesHubScreen({super.key});

  @override
  ConsumerState<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends ConsumerState<ServicesHubScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final categories = ServiceCategory.values
        .where(
          (c) =>
              query.isEmpty ||
              c.label.toLowerCase().contains(query) ||
              c.description.toLowerCase().contains(query) ||
              c.issues.any((i) => i.toLowerCase().contains(query)),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.lg,
                  Insets.xl,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home services', style: theme.textTheme.headlineLarge),
                    Gaps.xs,
                    Text(
                      'Vetted professionals for everything your home needs.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Gaps.lg,
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search plumbing, AC, cleaning…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                    Gaps.lg,
                    const InfoBanner(
                      icon: Icons.verified_rounded,
                      message:
                          'All GRID professionals are vetted, background-'
                          'checked and rated by homeowners like you.',
                    ),
                  ],
                ),
              ),
            ),
            if (query.isEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Most requested'),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                    scrollDirection: Axis.horizontal,
                    itemCount: MockData.popularServices.length,
                    separatorBuilder: (_, _) => Gaps.md,
                    itemBuilder: (context, i) =>
                        _PopularCard(category: MockData.popularServices[i]),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SectionHeader(
                title: query.isEmpty ? 'All services' : 'Results',
              ),
            ),
            if (categories.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching service',
                  message:
                      'Try a different word — or book a general handyman '
                      'and describe the job.',
                  compact: true,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                sliver: SliverList.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => Gaps.md,
                  itemBuilder: (context, i) =>
                      _CategoryCard(category: categories[i]),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xl),
                child: Material(
                  color: AppColors.dangerSoft,
                  borderRadius: Corners.lgRadius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => showEmergencySheet(context),
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.lg),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            color: AppColors.danger,
                            size: 24,
                          ),
                          Gaps.md,
                          Expanded(
                            child: Text(
                              'Emergency? Get help now',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
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

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: AppCard(
        padding: const EdgeInsets.all(Insets.lg),
        borderRadius: Corners.lgRadius,
        onTap: () => context.push(
          Routes.bookService,
          extra: BookingArgs(category: category),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIcon(
              category.icon,
              size: 34,
              color: AppColors.forest,
              background: AppColors.mint,
            ),
            const Spacer(),
            Text(
              category.label,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(Insets.lg),
      onTap: () => context.push(
        Routes.bookService,
        extra: BookingArgs(category: category),
      ),
      child: Row(
        children: [
          TintedIcon(category.icon, size: 48),
          Gaps.lg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  category.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.calloutFee > 0
                      ? 'Call-out from ${Fmt.cedis(category.calloutFee)}'
                      : 'Quoted after details',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
