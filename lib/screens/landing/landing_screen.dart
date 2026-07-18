import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _menuKey = GlobalKey();
  final _galleryKey = GlobalKey();
  final _contactKey = GlobalKey();

  static const facebookUrl = 'https://www.facebook.com/filipeesbistro';
  static const instagramUrl =
      'https://www.instagram.com/filipees_bistro?igshid=MzMyNGUyNmU2YQ==';
  static const phoneNumber = '0956 544 5021';
  static const address =
      '1013 Ylagan St. Poblacion 4, Bauan, Batangas, Philippines, 4204';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _Hero(wide: wide, onOrderTap: () => _scrollTo(_menuKey), onLoginTap: _goToLogin),
                _AboutSection(wide: wide),
                _MenuSection(key: _menuKey, wide: wide),
                _GallerySection(key: _galleryKey, wide: wide),
                _ContactSection(
                  key: _contactKey,
                  wide: wide,
                  onFacebook: () => _open(facebookUrl),
                  onInstagram: () => _open(instagramUrl),
                  onCall: () => _open('tel:$phoneNumber'),
                  onMap: () => _open(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'),
                ),
                _Footer(
                  onFacebook: () => _open(facebookUrl),
                  onInstagram: () => _open(instagramUrl),
                ),
              ],
            ),
          ),
          _NavBar(
            onMenuTap: () => _scrollTo(_menuKey),
            onGalleryTap: () => _scrollTo(_galleryKey),
            onContactTap: () => _scrollTo(_contactKey),
            onLoginTap: _goToLogin,
            wide: wide,
          ),
        ],
      ),
    );
  }
}

// ── Sticky nav bar ──────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final VoidCallback onMenuTap, onGalleryTap, onContactTap, onLoginTap;
  final bool wide;
  const _NavBar({
    required this.onMenuTap,
    required this.onGalleryTap,
    required this.onContactTap,
    required this.onLoginTap,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.jpg', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Text("Filipee's Bistro",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: wide ? 18 : 15)),
            const Spacer(),
            if (wide) ...[
              _NavLink('Menu', onMenuTap),
              _NavLink('Gallery', onGalleryTap),
              _NavLink('Visit Us', onContactTap),
              const SizedBox(width: 8),
            ],
            SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: onLoginTap,
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Staff Login'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavLink(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final bool wide;
  final VoidCallback onOrderTap;
  final VoidCallback onLoginTap;
  const _Hero({required this.wide, required this.onOrderTap, required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    final textCol = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Text('SINCE 2014 · POBLACION, BAUAN',
                style: TextStyle(
                    color: AppColors.accent2,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 18),
          Text('Savory. Satisfying.\nUnforgettable Lomi.',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: wide ? 44 : 32, height: 1.15)),
          const SizedBox(height: 16),
          const Text(
            "Filipee's Bistro serves Batangas-style comfort food — hearty lomi, "
            "goto, and homestyle favorites made fresh, hot, and with love. "
            "Two branches, one unforgettable taste.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GradientButton(
                text: 'See Our Menu',
                icon: Icons.restaurant_menu,
                onPressed: onOrderTap,
              ),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onLoginTap,
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text('Staff / POS Login'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final imageCol = _HeroCarousel(wide: wide);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, wide ? 130 : 110, 24, 48),
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: textCol),
                    const SizedBox(width: 48),
                    Expanded(child: imageCol),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textCol,
                    const SizedBox(height: 32),
                    imageCol,
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Hero image carousel — auto-plays through shots of the shop and menu ───
class _HeroSlide {
  final String image;
  final String caption;
  const _HeroSlide(this.image, this.caption);
}

class _HeroCarousel extends StatefulWidget {
  final bool wide;
  const _HeroCarousel({required this.wide});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  static const _slides = [
    _HeroSlide('assets/images/shop.jpg', 'Our Bistro'),
    _HeroSlide('assets/images/gallery_5.jpg', 'Lomi Special Bowl'),
    _HeroSlide('assets/images/promo_poster.jpg', 'Menu'),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _slides.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.wide ? 460.0 : 280.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final slide = _slides[i];
                return Image.asset(
                  slide.image,
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.bgPrimary.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent2, size: 18),
                  const SizedBox(width: 6),
                  const Text('Crowd favorite',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_slides[_page].caption,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent2 : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── About ────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final bool wide;
  const _AboutSection({required this.wide});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('11+', 'Years serving Bauan'),
      ('2', 'Branches'),
      ('100+', 'Guests daily'),
      ('4.8★', 'Customer rating'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SectionHeading(
                eyebrow: 'Our Story',
                title: 'A Batangas favorite,\nbowl by bowl.',
                subtitle:
                    "What started as a small carinderia in Poblacion has grown into a "
                    "beloved local bistro — known for generous servings of lomi, goto, "
                    "and fried rice cooked the traditional way.",
              ),
              const SizedBox(height: 40),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: stats
                    .map((s) => SizedBox(
                          width: wide ? 240 : 150,
                          child: BistroCard(
                            child: Column(
                              children: [
                                Text(s.$1,
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(s.$2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu highlights (pulled live from local DB) ─────────────────────────
class _MenuSection extends StatefulWidget {
  final bool wide;
  const _MenuSection({super.key, required this.wide});

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
  List<MenuItem> _all = [];
  bool _loading = true;
  String _category = 'All';

  static const _categories = ['All', 'Lomi', 'Pancit', 'Drinks', 'Others'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DBHelper.instance.getMenuItems();
    if (mounted) setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<MenuItem> get _filtered =>
      _category == 'All' ? _all : _all.where((i) => i.category == _category).toList();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.wide ? 4 : (isTablet(context) ? 3 : 2);
    final items = _filtered;
    return Container(
      width: double.infinity,
      color: AppColors.bgCard.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SectionHeading(
                eyebrow: 'Best Sellers',
                title: 'From our kitchen to your table',
                subtitle: 'A taste of what regulars order every single day.',
              ),
              const SizedBox(height: 28),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                              selectedColor: AppColors.accent,
                              backgroundColor: AppColors.bgInput,
                              labelStyle: TextStyle(
                                  color: _category == c ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 28),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No items in this category yet.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return _MenuPhotoCard(item: item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuPhotoCard extends StatelessWidget {
  final MenuItem item;
  const _MenuPhotoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MenuItemPhoto(name: item.name, category: item.category),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(peso(item.price),
                    style: const TextStyle(
                        color: AppColors.accent2,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gallery ─────────────────────────────────────────────────────────────
class _GallerySection extends StatelessWidget {
  final bool wide;
  const _GallerySection({super.key, required this.wide});

  static const _images = [
    'assets/images/gallery_1.jpg',
    'assets/images/gallery_2.jpg',
    'assets/images/gallery_3.jpg',
    'assets/images/gallery_4.jpg',
    'assets/images/gallery_5.jpg',
    'assets/images/promo_poster.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = wide ? 3 : 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SectionHeading(
                eyebrow: 'Gallery',
                title: 'Hot, fresh & made with love',
                subtitle: 'A peek at what\'s cooking at Filipee\'s Bistro.',
              ),
              const SizedBox(height: 36),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(_images[i], fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact & Location ──────────────────────────────────────────────────
class _ContactSection extends StatelessWidget {
  final bool wide;
  final VoidCallback onFacebook, onInstagram, onCall, onMap;
  const _ContactSection({
    super.key,
    required this.wide,
    required this.onFacebook,
    required this.onInstagram,
    required this.onCall,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ContactTile(
        icon: Icons.location_on,
        title: 'Visit Us',
        subtitle: '1013 Ylagan St. Poblacion 4,\nBauan, Batangas 4204',
        onTap: onMap,
        actionLabel: 'Open in Maps',
      ),
      _ContactTile(
        icon: Icons.phone,
        title: 'Call / Text',
        subtitle: '0956 544 5021',
        onTap: onCall,
        actionLabel: 'Call Now',
      ),
      _ContactTile(
        icon: Icons.facebook,
        title: 'Facebook',
        subtitle: 'facebook.com/filipeesbistro',
        onTap: onFacebook,
        actionLabel: 'Follow Us',
      ),
      _ContactTile(
        icon: Icons.camera_alt,
        title: 'Instagram',
        subtitle: '@filipees_bistro',
        onTap: onInstagram,
        actionLabel: 'Follow Us',
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgCard.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const SectionHeading(
                eyebrow: 'Get In Touch',
                title: 'Come hungry, leave happy',
                subtitle: 'Find us, follow us, or just give us a call.',
              ),
              const SizedBox(height: 36),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : (isTablet(context) ? 2 : 1),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: wide ? 0.95 : (isTablet(context) ? 1.3 : 1.6),
                children: cards,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, actionLabel;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: BistroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accent2, size: 22),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(actionLabel,
                      style: const TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: AppColors.accent, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final VoidCallback onFacebook, onInstagram;
  const _Footer({required this.onFacebook, required this.onInstagram});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/logo.jpg', width: 22, height: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text("Filipee's Bistro",
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: onFacebook, icon: const Icon(Icons.facebook, color: AppColors.textSecondary)),
                  IconButton(onPressed: onInstagram, icon: const Icon(Icons.camera_alt, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('© 2026 Filipee\'s Bistro · Poblacion Branch, Bauan, Batangas',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
