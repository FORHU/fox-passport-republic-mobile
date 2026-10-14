import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter_template/features/onboarding/presentation/theme/onboarding_palette.dart';
import 'package:flutter_template/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:flutter_template/features/onboarding/presentation/widgets/onboarding_fields.dart';
import 'package:flutter_template/features/onboarding/presentation/widgets/role_details_sheet.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// FoxPassport onboarding — the web app's `/onboarding` flow on a phone:
/// **Profile → Interests → Roles**, in the web's dark / lime look.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final TextEditingController _name;
  late final TextEditingController _district;

  @override
  void initState() {
    super.initState();
    final s = ref.read(onboardingControllerProvider);
    _name = TextEditingController(text: s.name);
    _district = TextEditingController(text: s.district);
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    super.dispose();
  }

  /// Leaving onboarding for good. The router sends unseen users back here, so
  /// every exit has to mark it seen first.
  Future<void> _exit([String route = RouteNames.home]) async {
    await ref.read(storageServiceProvider).setOnboardingSeen();
    if (mounted) context.go(route);
  }

  Future<void> _continueProfile() =>
      ref.read(onboardingControllerProvider.notifier).saveProfileAndContinue();

  Future<void> _openRole(RoleCatalogEntry role) async {
    final proceed = await showRoleDetailsSheet(context, role);
    if (!proceed || !mounted) return;
    await _openOnWeb(role.href);
  }

  Future<void> _openOnWeb(String path) async {
    final opened = await openWebApp(path);
    if (!opened && mounted) {
      showTopToast(
        context,
        context.l10n.onboardingWebNotConfigured,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Surface save errors as a toast, then they clear on the next change.
    ref.listen(onboardingControllerProvider.select((s) => s.error), (_, e) {
      if (e != null) showTopToast(context, e);
    });
    // The loaded profile may have newer values than the cached session user.
    ref.listen(onboardingControllerProvider.select((s) => s.isLoading),
        (was, loading) {
      if (was == true && !loading) {
        final s = ref.read(onboardingControllerProvider);
        if (_name.text != s.name) _name.text = s.name;
        if (_district.text != s.district) _district.text = s.district;
      }
    });

    return Scaffold(
      backgroundColor: OnboardingPalette.canvas,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _TopBar(
                      journey: state.journey,
                      current: state.step,
                      onHome: _exit,
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: switch (state.step) {
                        OnboardingStep.profile => _ProfileStep(
                            key: const ValueKey('profile'),
                            state: state,
                            nameController: _name,
                            districtController: _district,
                            onContinue: _continueProfile,
                          ),
                        OnboardingStep.intent => _IntentStep(
                            key: const ValueKey('intent'),
                            onBook: () => _exit(RouteNames.search),
                            onFoxer: () =>
                                controller.goTo(OnboardingStep.roles),
                            onBack: () =>
                                controller.goTo(OnboardingStep.profile),
                          ),
                        OnboardingStep.roles => _RolesStep(
                            key: const ValueKey('roles'),
                            state: state,
                            onRole: _openRole,
                            onRevision: (id) =>
                                _openOnWeb('/foxer/resubmit/$id'),
                            onBack: controller.backFromRoles,
                            onFinish: () => state.hasHeldRoles
                                ? _openOnWeb('/creator-dashboard')
                                : _exit(),
                            onSkip: _exit,
                          ),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The web's `bg-gradient-dark`: violet, pink and lime glows on the canvas.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    RadialGradient glow(Alignment at, Color c, double a) => RadialGradient(
          center: at,
          radius: 0.9,
          colors: [c.withValues(alpha: a), c.withValues(alpha: 0)],
          stops: const [0, 0.55],
        );

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: glow(
                  const Alignment(-0.7, 0),
                  AppColors.violet,
                  0.15,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: glow(
                  const Alignment(0.7, -0.4),
                  AppColors.rose,
                  0.10,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: glow(
                  Alignment.topCenter,
                  OnboardingPalette.accent,
                  0.05,
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.journey,
    required this.current,
    required this.onHome,
  });

  final List<OnboardingStep> journey;
  final OnboardingStep current;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onHome,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: OnboardingPalette.white(0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.home,
                  style: OnboardingPalette.body(
                    weight: FontWeight.w800,
                    color: OnboardingPalette.white(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        OnboardingStepper(journey: journey, current: current),
      ],
    );
  }
}

// ── Step 1: Profile ─────────────────────────────────────────────────────

class _ProfileStep extends ConsumerWidget {
  const _ProfileStep({
    required this.state,
    required this.nameController,
    required this.districtController,
    required this.onContinue,
    super.key,
  });

  final OnboardingState state;
  final TextEditingController nameController;
  final TextEditingController districtController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(onboardingControllerProvider.notifier);
    final l10n = context.l10n;
    final firstName =
        ref.watch(authControllerProvider).user?.name.split(' ').first ?? '';
    final greetName = firstName.isEmpty ? l10n.onboardingFriend : firstName;
    final districtEnabled = state.city.trim().isNotEmpty;
    final locationBusy = state.isLoading;

    return StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            icon: Icons.waving_hand_rounded,
            title: '',
            titleSpans: [
              TextSpan(
                text: state.hasHeldRoles
                    ? l10n.onboardingBackAgain
                    : l10n.onboardingWelcome,
              ),
              TextSpan(
                text: '$greetName!',
                style: const TextStyle(color: OnboardingPalette.accent),
              ),
            ],
            subtitle: state.hasHeldRoles
                ? l10n.onboardingProfileSubtitleReturning
                : l10n.onboardingProfileSubtitleNew,
          ),
          FieldLabel(l10n.onboardingDisplayName, required: true),
          OnboardingTextField(
            controller: nameController,
            hint: l10n.onboardingDisplayNameHint,
            icon: Icons.person_outline_rounded,
            onChanged: c.setName,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OnboardingPalette.white(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OnboardingPalette.white(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: OnboardingPalette.white(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        text: l10n.onboardingYourAddress.toUpperCase(),
                        style: OnboardingPalette.body(
                          size: 13,
                          weight: FontWeight.w800,
                          color: OnboardingPalette.white(0.8),
                          letterSpacing: 1,
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: OnboardingPalette.accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.onboardingAddressHelp,
                  style: OnboardingPalette.body(
                    size: 12,
                    color: OnboardingPalette.white(0.4),
                  ),
                ),
                const SizedBox(height: 14),
                FieldLabel(l10n.onboardingCountry),
                SearchableSelectField(
                  value: state.country,
                  placeholder: locationBusy
                      ? l10n.onboardingLoading
                      : l10n.onboardingSelectCountry,
                  searchHint: l10n.onboardingSearchCountries,
                  options: [for (final x in state.countries) x.name],
                  enabled: state.countries.isNotEmpty,
                  loading: locationBusy,
                  onSelected: c.selectCountry,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stateField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.onboardingStateProvince),
                        SearchableSelectField(
                          value: state.state,
                          placeholder: state.countryCode == null
                              ? l10n.onboardingSelectCountryFirst
                              : !state.statesFetched
                                  ? l10n.onboardingLoading
                                  : state.hasStates
                                      ? l10n.onboardingSelectState
                                      : l10n.onboardingNoStates,
                          searchHint: l10n.onboardingSearchStates,
                          options: [for (final x in state.states) x.name],
                          enabled: state.countryCode != null && state.hasStates,
                          allowCustom: state.hasStates,
                          loading:
                              state.countryCode != null && !state.statesFetched,
                          onSelected: c.selectState,
                        ),
                      ],
                    );
                    final cityField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(l10n.onboardingCity),
                        SearchableSelectField(
                          value: state.city,
                          placeholder: state.countryCode == null
                              ? l10n.onboardingSelectCountryFirst
                              : state.hasStates && state.state.trim().isEmpty
                                  ? l10n.onboardingSelectStateFirst
                                  : l10n.onboardingSelectCity,
                          searchHint: l10n.onboardingSearchCities,
                          options: state.cities,
                          enabled: state.cityReady,
                          allowCustom: true,
                          onSelected: c.selectCity,
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 520) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          stateField,
                          const SizedBox(height: 12),
                          cityField,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: stateField),
                        const SizedBox(width: 16),
                        Expanded(child: cityField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                FieldLabel(
                  state.isPhilippines
                      ? l10n.onboardingBarangay
                      : l10n.onboardingDistrict,
                  hint: l10n.onboardingOptional,
                ),
                OnboardingTextField(
                  controller: districtController,
                  hint: districtEnabled
                      ? l10n.onboardingYourDistrict(
                          (state.isPhilippines
                                  ? l10n.onboardingBarangay
                                  : l10n.onboardingDistrict)
                              .toLowerCase(),
                        )
                      : l10n.onboardingSelectCityFirst,
                  icon: Icons.home_work_outlined,
                  enabled: districtEnabled,
                  onChanged: c.setDistrict,
                ),
              ],
            ),
          ),
          StepFooter(
            children: [
              if (!state.profileComplete) ...[
                Text(
                  l10n.onboardingAddMissing(
                    [
                      if (state.name.trim().isEmpty) l10n.onboardingFieldName,
                      if (state.country.trim().isEmpty)
                        l10n.onboardingFieldCountry,
                      if (state.city.trim().isEmpty) l10n.onboardingFieldCity,
                    ].join(', '),
                  ),
                  textAlign: TextAlign.center,
                  style: OnboardingPalette.body(
                    size: 12,
                    color: OnboardingPalette.white(0.4),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AccentButton(
                label: state.isSaving
                    ? l10n.onboardingSaving
                    : l10n.onboardingContinue,
                trailing: Icons.arrow_forward_rounded,
                loading: state.isSaving,
                onPressed: state.profileComplete ? onContinue : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Intent (new users only) ─────────────────────────────────────

class _IntentStep extends StatelessWidget {
  const _IntentStep({
    required this.onBook,
    required this.onFoxer,
    required this.onBack,
    super.key,
  });

  final VoidCallback onBook;
  final VoidCallback onFoxer;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StepCard(
      glow: OnboardingPalette.intent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            icon: Icons.explore_rounded,
            color: OnboardingPalette.intent,
            title: l10n.onboardingIntentTitle,
            subtitle: l10n.onboardingIntentSubtitle,
          ),
          _IntentOption(
            icon: Icons.local_activity_rounded,
            color: OnboardingPalette.accent,
            title: l10n.onboardingIntentBookTitle,
            body: l10n.onboardingIntentBookBody,
            onTap: onBook,
          ),
          const SizedBox(height: 12),
          _IntentOption(
            icon: Icons.badge_rounded,
            color: OnboardingPalette.foxer,
            title: l10n.onboardingIntentFoxerTitle,
            body: l10n.onboardingIntentFoxerBody,
            onTap: onFoxer,
          ),
          const SizedBox(height: 12),
          _IntentOption(
            icon: Icons.people_alt_rounded,
            color: AppColors.textPrimary,
            muted: true,
            title: l10n.onboardingIntentBothTitle,
            body: l10n.onboardingIntentBothBody,
            onTap: onFoxer,
          ),
          StepFooter(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackAction(onPressed: onBack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntentOption extends StatelessWidget {
  const _IntentOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OnboardingPalette.white(0.03),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OnboardingPalette.white(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: muted
                      ? OnboardingPalette.white(0.05)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: muted ? OnboardingPalette.white(0.5) : color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: OnboardingPalette.display(size: 16)),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: OnboardingPalette.body(
                        size: 13,
                        color: OnboardingPalette.white(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: OnboardingPalette.white(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Roles ───────────────────────────────────────────────────────

class _RolesStep extends StatelessWidget {
  const _RolesStep({
    required this.state,
    required this.onRole,
    required this.onRevision,
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
    super.key,
  });

  final OnboardingState state;
  final ValueChanged<RoleCatalogEntry> onRole;
  final ValueChanged<String> onRevision;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = state.hasHeldRoles
        ? l10n.onboardingRolesTitleHeld
        : state.pendingRoles.isNotEmpty
            ? l10n.onboardingRolesTitlePending
            : l10n.onboardingRolesTitleChoose;
    final subtitle = state.hasHeldRoles
        ? l10n.onboardingRolesSubtitleHeld
        : state.pendingRoles.isNotEmpty
            ? l10n.onboardingRolesSubtitlePending
            : l10n.onboardingRolesSubtitleChoose;
    final finishLabel = state.hasHeldRoles
        ? l10n.onboardingFinishDashboard
        : state.pendingRoles.isNotEmpty
            ? l10n.onboardingFinishHome
            : l10n.onboardingFinishSkip;

    return StepCard(
      glow: OnboardingPalette.roles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            icon: Icons.badge_rounded,
            color: OnboardingPalette.roles,
            title: title,
            subtitle: subtitle,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 2 : 1;
              final cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final role in roleCatalog)
                    SizedBox(
                      width: cardWidth,
                      child: _roleCard(role),
                    ),
                ],
              );
            },
          ),
          StepFooter(
            children: [
              OutlineActionButton(
                label: finishLabel,
                onPressed: state.hasHeldRoles ? onFinish : onSkip,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: BackAction(onPressed: onBack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleCard(RoleCatalogEntry role) {
    if (state.heldRoles.contains(role.roleType)) {
      return RoleCard(role: role, status: RoleStatus.active, onTap: null);
    }
    if (state.pendingRoles.contains(role.roleType)) {
      return RoleCard(role: role, status: RoleStatus.pending, onTap: null);
    }
    for (final r in state.revisions) {
      if (r.roleType == role.roleType) {
        return RoleCard(
          role: role,
          status: RoleStatus.revision,
          onTap: () => onRevision(r.id),
        );
      }
    }
    return RoleCard(
      role: role,
      status: RoleStatus.available,
      onTap: () => onRole(role),
    );
  }
}
