import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppSizing — Responsive design token system
//
// 5 breakpoints — covers everything from small Android phones to 12" tablets
// and web browsers:
//
//  ┌────────────┬──────────┬────────────────────────────────────────────────┐
//  │ Breakpoint │  Width   │ Examples                                       │
//  ├────────────┼──────────┼────────────────────────────────────────────────┤
//  │ compact    │ < 360dp  │ Small Android phones (Galaxy A series portrait)│
//  │ mobile     │ 360–599  │ Normal phones (most Android + iPhone portrait) │
//  │ tablet     │ 600–839  │ 7–8" tablets, phone landscape, foldables       │
//  │ largeTab   │ 840–1279 │ 10–12" tablets (iPad Pro, Galaxy Tab portrait) │
//  │ desktop    │ ≥ 1280   │ Chrome web, 12" landscape, desktop browser     │
//  └────────────┴──────────┴────────────────────────────────────────────────┘
//
// Key design decisions for 10–12" tablets (largeTab):
//   • Touch-friendly tap targets (min 48dp) preserved
//   • Navigation rail shown but NOT expanded (80dp, icons + selected label)
//   • Two-column word list layout
//   • Larger fonts than small tablet but not as large as desktop
//   • screenPaddingH wide enough to avoid content touching the rail
//
// Usage:
//   final s = AppSizing.of(context);
//   Padding(padding: EdgeInsets.all(s.md))
//
//   AppSizing.isLargeTablet(context) → 10–12" form factor
//   AppSizing.isPhone(context)       → use bottom nav bar
//   AppSizing.isWide(context)        → use navigation rail
// ─────────────────────────────────────────────────────────────────────────────

enum AppBreakpoint { compact, mobile, tablet, largeTablet, desktop }

class AppSizing {
  // ── Breakpoint thresholds (dp) ─────────────────────────────────────
  static const double kCompact = 360.0;
  static const double kMobile = 600.0;
  static const double kTablet = 840.0; // Material 3 recommended
  static const double kLargeTab = 1280.0; // Separates large tablet from desktop
  // ≥ 1280 = desktop / Chrome web

  // ── Touch target minimum (Material 3 = 48dp) ──────────────────────
  static const double minTouchTarget = 48.0;

  // ── Content width caps ─────────────────────────────────────────────
  /// Max width for a single content column (word list, cards)
  static const double maxColumnWidth = 720.0;

  /// Max width of the full two-column shell on desktop
  static const double maxShellWidth = 1440.0;

  /// Navigation rail — compact (icon only + selected label)
  static const double navRailCompact = 80.0;

  /// Navigation rail — wide (icon + all labels, 10–12" tablets)
  static const double navRailWide = 100.0;

  /// Full navigation drawer width on desktop
  static const double navDrawerWidth = 256.0;

  // Legacy alias
  static const double maxContentWidth = maxColumnWidth;

  // ── Orientation helper ─────────────────────────────────────────────
  static bool isLandscape(BuildContext ctx) =>
      MediaQuery.orientationOf(ctx) == Orientation.landscape;

  // ── Breakpoint checks ──────────────────────────────────────────────
  static AppBreakpoint bp(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w < kCompact) return AppBreakpoint.compact;
    if (w < kMobile) return AppBreakpoint.mobile;
    if (w < kTablet) return AppBreakpoint.tablet;
    if (w < kLargeTab) return AppBreakpoint.largeTablet;
    return AppBreakpoint.desktop;
  }

  static bool isCompact(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < kCompact;

  static bool isMobile(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= kCompact && w < kMobile;
  }

  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= kMobile && w < kTablet;
  }

  /// True for 10–12" tablets in portrait, or large tablets in landscape.
  static bool isLargeTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= kTablet && w < kLargeTab;
  }

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= kLargeTab;

  /// True for any phone form factor → show bottom nav bar
  static bool isPhone(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < kMobile;

  /// True for tablet, largeTablet, or desktop → show navigation rail
  static bool isWide(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= kMobile;

  /// True for largeTablet + desktop → show expanded content / 2-col layout
  static bool isXWide(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= kTablet;

  // Legacy helpers
  static bool isSmall(BuildContext ctx) => isCompact(ctx);
  static bool isMedium(BuildContext ctx) => isMobile(ctx);
  static bool isLarge(BuildContext ctx) => isWide(ctx);

  // ── Factory ────────────────────────────────────────────────────────
  factory AppSizing.of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < kCompact) return AppSizing._compact();
    if (w < kMobile) return AppSizing._mobile();
    if (w < kTablet) return AppSizing._tablet();
    if (w < kLargeTab) return AppSizing._largeTablet();
    return AppSizing._desktop();
  }

  AppSizing._({
    required this.breakpoint,
    // Spacing
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    // Icons
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    // Touch targets (always ≥ 48dp on touch devices)
    required this.touchTarget,
    // Avatars
    required this.avatarSm,
    required this.avatarMd,
    required this.avatarLg,
    // Radii
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    // Layout
    required this.appBarHeight,
    required this.bottomNavHeight,
    required this.listItemHeight,
    required this.navRailWidth,
    // Padding
    required this.cardPaddingH,
    required this.cardPaddingV,
    required this.screenPaddingH,
    required this.screenPaddingV,
    // Fonts
    required this.fontXs,
    required this.fontSm,
    required this.fontMd,
    required this.fontLg,
    required this.fontXl,
    required this.fontXxl,
    required this.fontDisplay,
    required this.fontHero,
    // Grid
    required this.gridColumns,
    required this.gridSpacing,
    // Nav rail style
    required this.navLabelType,
    required this.showNavRail,
  });

  // ─────────────────────────────────────────────────────────────────
  // compact  < 360dp — small Android phones
  // ─────────────────────────────────────────────────────────────────
  factory AppSizing._compact() => AppSizing._(
    breakpoint: AppBreakpoint.compact,
    xs: 2,
    sm: 6,
    md: 10,
    lg: 14,
    xl: 18,
    xxl: 22,
    iconSm: 14,
    iconMd: 18,
    iconLg: 22,
    touchTarget: 44, // slightly below 48 — compact screens need density
    avatarSm: 28,
    avatarMd: 34,
    avatarLg: 44,
    radiusSm: 6,
    radiusMd: 10,
    radiusLg: 14,
    radiusXl: 18,
    appBarHeight: 52,
    bottomNavHeight: 52,
    listItemHeight: 60,
    navRailWidth: 0,
    cardPaddingH: 10,
    cardPaddingV: 8,
    screenPaddingH: 10,
    screenPaddingV: 8,
    fontXs: 9,
    fontSm: 10,
    fontMd: 12,
    fontLg: 13,
    fontXl: 15,
    fontXxl: 18,
    fontDisplay: 22,
    fontHero: 26,
    gridColumns: 1,
    gridSpacing: 8,
    navLabelType: NavigationRailLabelType.none,
    showNavRail: false,
  );

  // ─────────────────────────────────────────────────────────────────
  // mobile  360–599dp — standard phones
  // ─────────────────────────────────────────────────────────────────
  factory AppSizing._mobile() => AppSizing._(
    breakpoint: AppBreakpoint.mobile,
    xs: 4,
    sm: 8,
    md: 14,
    lg: 18,
    xl: 24,
    xxl: 30,
    iconSm: 16,
    iconMd: 20,
    iconLg: 24,
    touchTarget: 48,
    avatarSm: 32,
    avatarMd: 40,
    avatarLg: 52,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 18,
    radiusXl: 24,
    appBarHeight: 60,
    bottomNavHeight: 56,
    listItemHeight: 68,
    navRailWidth: 0,
    cardPaddingH: 14,
    cardPaddingV: 12,
    screenPaddingH: 16,
    screenPaddingV: 12,
    fontXs: 10,
    fontSm: 12,
    fontMd: 13,
    fontLg: 14,
    fontXl: 17,
    fontXxl: 22,
    fontDisplay: 28,
    fontHero: 34,
    gridColumns: 1,
    gridSpacing: 10,
    navLabelType: NavigationRailLabelType.none,
    showNavRail: false,
  );

  // ─────────────────────────────────────────────────────────────────
  // tablet  600–839dp — 7–8" tablets, phone landscape, foldables
  // ─────────────────────────────────────────────────────────────────
  factory AppSizing._tablet() => AppSizing._(
    breakpoint: AppBreakpoint.tablet,
    xs: 6,
    sm: 12,
    md: 18,
    lg: 24,
    xl: 32,
    xxl: 40,
    iconSm: 20,
    iconMd: 24,
    iconLg: 30,
    touchTarget: 48,
    avatarSm: 36,
    avatarMd: 48,
    avatarLg: 60,
    radiusSm: 10,
    radiusMd: 14,
    radiusLg: 20,
    radiusXl: 28,
    appBarHeight: 64,
    bottomNavHeight: 60,
    listItemHeight: 72,
    navRailWidth: AppSizing.navRailCompact,
    cardPaddingH: 18,
    cardPaddingV: 14,
    screenPaddingH: 24,
    screenPaddingV: 16,
    fontXs: 11,
    fontSm: 13,
    fontMd: 14,
    fontLg: 16,
    fontXl: 19,
    fontXxl: 25,
    fontDisplay: 32,
    fontHero: 40,
    gridColumns: 2,
    gridSpacing: 14,
    navLabelType: NavigationRailLabelType.selected,
    showNavRail: true,
  );

  // ─────────────────────────────────────────────────────────────────
  // largeTablet  840–1279dp — 10–12" tablets (iPad Pro, Galaxy Tab)
  //
  // Key decisions for this breakpoint:
  //   • touchTarget = 52dp — fingers on a large tablet are comfortable
  //     but still need generous tap areas
  //   • navRailWidth = 100dp — icons + ALL labels always visible
  //   • gridColumns = 2 — two columns of word cards, comfortable reading
  //   • screenPaddingH = 36 — breathing room from rail + screen edge
  //   • fontDisplay = 38 — readable at arm's length on a 12" screen
  //   • listItemHeight = 80 — roomier rows, easier to tap precisely
  // ─────────────────────────────────────────────────────────────────
  factory AppSizing._largeTablet() => AppSizing._(
    breakpoint: AppBreakpoint.largeTablet,
    xs: 8,
    sm: 14,
    md: 20,
    lg: 28,
    xl: 36,
    xxl: 44,
    iconSm: 22,
    iconMd: 28,
    iconLg: 34,
    touchTarget: 52, // generous but not over-sized
    avatarSm: 42,
    avatarMd: 56,
    avatarLg: 72,
    radiusSm: 12,
    radiusMd: 16,
    radiusLg: 22,
    radiusXl: 30,
    appBarHeight: 68,
    bottomNavHeight: 64,
    listItemHeight: 80,
    navRailWidth: AppSizing.navRailWide, // 100dp — icons + all labels
    cardPaddingH: 24,
    cardPaddingV: 18,
    screenPaddingH: 36,
    screenPaddingV: 20,
    fontXs: 12,
    fontSm: 14,
    fontMd: 15,
    fontLg: 17,
    fontXl: 21,
    fontXxl: 28,
    fontDisplay: 38,
    fontHero: 48,
    gridColumns: 2, // 2 columns — comfortable reading width
    gridSpacing: 18,
    navLabelType: NavigationRailLabelType.all, // all labels always shown
    showNavRail: true,
  );

  // ─────────────────────────────────────────────────────────────────
  // desktop  ≥ 1280dp — Chrome web, large tablet landscape, desktop
  // ─────────────────────────────────────────────────────────────────
  factory AppSizing._desktop() => AppSizing._(
    breakpoint: AppBreakpoint.desktop,
    xs: 8,
    sm: 14,
    md: 20,
    lg: 28,
    xl: 40,
    xxl: 52,
    iconSm: 22,
    iconMd: 28,
    iconLg: 36,
    touchTarget: 40, // mouse target — can be smaller than touch
    avatarSm: 44,
    avatarMd: 60,
    avatarLg: 80,
    radiusSm: 12,
    radiusMd: 18,
    radiusLg: 24,
    radiusXl: 32,
    appBarHeight: 72,
    bottomNavHeight: 68,
    listItemHeight: 80,
    navRailWidth: AppSizing.navDrawerWidth, // 256dp full drawer
    cardPaddingH: 28,
    cardPaddingV: 20,
    screenPaddingH: 48,
    screenPaddingV: 24,
    fontXs: 12,
    fontSm: 14,
    fontMd: 16,
    fontLg: 18,
    fontXl: 22,
    fontXxl: 30,
    fontDisplay: 42,
    fontHero: 54,
    gridColumns: 3,
    gridSpacing: 20,
    navLabelType: NavigationRailLabelType.all,
    showNavRail: true,
  );

  // ── Fields ─────────────────────────────────────────────────────────
  final AppBreakpoint breakpoint;

  // Spacing scale
  final double xs; // 2–8
  final double sm; // 6–14
  final double md; // 10–20
  final double lg; // 14–28
  final double xl; // 18–40
  final double xxl; // 22–52

  // Icons
  final double iconSm;
  final double iconMd;
  final double iconLg;

  // Touch / click targets
  final double touchTarget;

  // Avatars / containers
  final double avatarSm;
  final double avatarMd;
  final double avatarLg;

  // Border radii
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  // Layout dimensions
  final double appBarHeight;
  final double bottomNavHeight;
  final double listItemHeight;
  final double navRailWidth;

  // Padding
  final double cardPaddingH;
  final double cardPaddingV;
  final double screenPaddingH;
  final double screenPaddingV;

  // Typography
  final double fontXs; // badge / caption
  final double fontSm; // secondary text
  final double fontMd; // body default
  final double fontLg; // body emphasis
  final double fontXl; // section heading
  final double fontXxl; // screen title
  final double fontDisplay; // word hero / card title
  final double fontHero; // banner / splash

  // Grid
  final int gridColumns; // 1 / 2 / 3
  final double gridSpacing;

  // Navigation
  final NavigationRailLabelType navLabelType;
  final bool showNavRail;

  // ── Convenience getters ────────────────────────────────────────────
  bool get isCompactBp => breakpoint == AppBreakpoint.compact;
  bool get isMobileBp => breakpoint == AppBreakpoint.mobile;
  bool get isTabletBp => breakpoint == AppBreakpoint.tablet;
  bool get isLargeTabBp => breakpoint == AppBreakpoint.largeTablet;
  bool get isDesktopBp => breakpoint == AppBreakpoint.desktop;

  /// Any phone — use bottom nav
  bool get isPhoneBp => isCompactBp || isMobileBp;

  /// Tablet or larger — use nav rail
  bool get isWideBp => !isPhoneBp;

  /// Large tablet or desktop — use expanded layout / 2-col+
  bool get isXWideBp => isLargeTabBp || isDesktopBp;

  EdgeInsets get cardPadding =>
      EdgeInsets.symmetric(horizontal: cardPaddingH, vertical: cardPaddingV);
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  BorderRadius get cardRadius => BorderRadius.circular(radiusLg);
  BorderRadius get pillRadius => BorderRadius.circular(100);
  BorderRadius get tileRadius => BorderRadius.circular(radiusMd);
  BorderRadius get dialogRadius => BorderRadius.circular(radiusXl);
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveLayout — The main app shell
//
// Selects the navigation pattern automatically based on screen width:
//
//   Phone      → body fills screen, NavigationBar at bottom
//   Tablet     → compact NavigationRail (80dp) + content column
//   LargeTab   → wide NavigationRail (100dp, all labels) + content column
//   Desktop    → full NavigationDrawer (256dp) + content + optional detail panel
//
// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;
  final Widget? detailPanel; // shown on desktop right side (2-col layout)
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AdaptiveLayout({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.detailPanel,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);

    // ── Phone → bottom NavigationBar ──────────────────────────────
    if (s.isPhoneBp) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
          height: s.bottomNavHeight,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      );
    }

    // ── Tablet / LargeTablet / Desktop → NavigationRail ───────────
    final rail = NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: s.navLabelType,
      minWidth: s.navRailWidth,
      destinations:
          destinations
              .map(
                (d) => NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                  // Enforce touch target on touch devices
                  padding:
                      s.isLargeTabBp
                          ? const EdgeInsets.symmetric(vertical: 4)
                          : EdgeInsets.zero,
                ),
              )
              .toList(),
    );

    // Content — always centred and capped at maxColumnWidth
    Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxColumnWidth),
        child: body,
      ),
    );

    // Desktop + detail panel → two-column split
    if (s.isDesktopBp && detailPanel != null) {
      content = Row(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizing.maxColumnWidth,
                ),
                child: body,
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(flex: 4, child: detailPanel!),
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          rail,
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveGrid — Responsive word card grid
//
//   Phone      → 1-col ListView
//   Tablet     → 2-col GridView
//   LargeTab   → 2-col GridView (wider cards)
//   Desktop    → 3-col GridView
// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? mainAxisExtent;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisExtent,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);

    if (s.gridColumns == 1) {
      return ListView.separated(
        controller: controller,
        padding: padding ?? EdgeInsets.all(s.screenPaddingH),
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(height: s.sm),
        itemBuilder: (_, i) => children[i],
      );
    }

    return GridView.builder(
      controller: controller,
      padding: padding ?? EdgeInsets.all(s.screenPaddingH),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: s.gridColumns,
        crossAxisSpacing: s.gridSpacing,
        mainAxisSpacing: s.gridSpacing,
        childAspectRatio: childAspectRatio ?? 2.8,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveBody — Centres + constrains content on wide screens
// ─────────────────────────────────────────────────────────────────────────────
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = AppSizing.maxColumnWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppSizing.of(context);
    final Widget constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
    return s.isWideBp ? Center(child: constrained) : constrained;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BreakpointBuilder — Different UI per breakpoint without boilerplate
//
// Usage:
//   BreakpointBuilder(
//     phone:      (_) => PhoneWordCard(word: w),
//     tablet:     (_) => TabletWordCard(word: w),
//     largeTablet:(_) => LargeTabWordCard(word: w),
//     desktop:    (_) => DesktopWordRow(word: w),
//   )
// ─────────────────────────────────────────────────────────────────────────────
class BreakpointBuilder extends StatelessWidget {
  final WidgetBuilder phone;
  final WidgetBuilder? tablet;
  final WidgetBuilder? largeTablet;
  final WidgetBuilder? desktop;

  const BreakpointBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.largeTablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return switch (AppSizing.of(context).breakpoint) {
      AppBreakpoint.desktop => (desktop ?? largeTablet ?? tablet ?? phone)(
        context,
      ),
      AppBreakpoint.largeTablet => (largeTablet ?? tablet ?? phone)(context),
      AppBreakpoint.tablet => (tablet ?? phone)(context),
      _ => phone(context),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gap — Adaptive spacing
//
// Gap(16)                                  → scales per breakpoint automatically
// Gap(8, medium: 12, large: 20, xl: 32)   → explicit per-breakpoint values
// Gap.h(12)                                → horizontal
// ─────────────────────────────────────────────────────────────────────────────
class Gap extends StatelessWidget {
  final double small;
  final double? medium;
  final double? large;
  final double? xl;
  final bool horizontal;

  const Gap(
    this.small, {
    super.key,
    this.medium,
    this.large,
    this.xl,
    this.horizontal = false,
  });

  const Gap.h(this.small, {super.key, this.medium, this.large, this.xl})
    : horizontal = true;

  @override
  Widget build(BuildContext context) {
    final size = switch (AppSizing.of(context).breakpoint) {
      AppBreakpoint.compact => small * 0.85,
      AppBreakpoint.mobile => medium ?? small,
      AppBreakpoint.tablet => large ?? medium ?? small * 1.3,
      AppBreakpoint.largeTablet => xl ?? large ?? medium ?? small * 1.6,
      AppBreakpoint.desktop => xl ?? large ?? medium ?? small * 1.9,
    };
    return horizontal ? SizedBox(width: size) : SizedBox(height: size);
  }
}
