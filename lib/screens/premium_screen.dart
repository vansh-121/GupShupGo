/// GupShupGo Pro — Premium upgrade screen.
///
/// A stunning, Telegram-Premium-inspired screen with animated header,
/// feature comparison, pricing cards, and restore purchase.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/subscription_model.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/premium_badge.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headerScale;
  late final Animation<double> _headerRotation;

  int _selectedPlanIndex = 1; // Default to yearly (best value)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _headerScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _headerRotation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: c.isDark ? const Color(0xFF0A0A14) : c.surface,
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero header ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeroHeader(c, sub)),

          // ── Already Pro banner ────────────────────────────────────────
          if (sub.isPro)
            SliverToBoxAdapter(child: _buildActiveProBanner(c, sub)),

          // ── Features list ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'What you get with Pro',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildFeatureCards(c)),
            ),
          ),

          // ── Pricing cards ─────────────────────────────────────────────
          if (!sub.isPro) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Choose your plan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildPricingCards(c, sub)),
            SliverToBoxAdapter(child: _buildSubscribeButton(c, sub)),
            SliverToBoxAdapter(child: _buildRestoreButton(c, sub)),
          ],

          // ── Bottom padding ────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Hero header with animated Pro badge
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroHeader(AppThemeColors c, SubscriptionProvider sub) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [
                  const Color(0xFF1A1428),
                  const Color(0xFF0F0A1E),
                  const Color(0xFF0A0A14),
                ]
              : [
                  const Color(0xFF6C5CE7),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFA78BFA),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
              ),
            ),

            // Animated Pro icon
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _headerScale.value,
                  child: Transform.rotate(
                    angle: _headerRotation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'GupShupGo Pro',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub.isPro
                  ? 'You\'re a Pro member! 🎉'
                  : 'Unlock the full experience',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Active Pro banner
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActiveProBanner(AppThemeColors c, SubscriptionProvider sub) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.12),
            const Color(0xFFFFA500).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const PremiumBadge(size: PremiumBadgeSize.medium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.subscription.planLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: c.textHigh,
                  ),
                ),
                Text(
                  '${sub.subscription.daysRemaining} days remaining',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: const Color(0xFFFFD700), size: 28),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Feature comparison cards
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildFeatureCards(AppThemeColors c) {
    final features = [
      _FeatureItem(
        icon: Icons.photo_camera_rounded,
        title: 'Media Moments',
        description: 'Share photos & videos as status updates',
        freeLabel: 'Text only',
        proLabel: 'Photos + Videos',
      ),
      _FeatureItem(
        icon: Icons.screen_share_rounded,
        title: 'Screen Sharing',
        description: 'Share your screen live during chats',
        freeLabel: 'Locked',
        proLabel: 'Full access',
      ),
      _FeatureItem(
        icon: Icons.palette_rounded,
        title: 'Exclusive Themes',
        description: 'Premium dark & color themes',
        freeLabel: 'Light / Dark',
        proLabel: '+ AMOLED, Ocean, Sunset, Emerald',
      ),
      _FeatureItem(
        icon: Icons.mic_rounded,
        title: 'Longer Voice Messages',
        description: 'Record longer voice notes',
        freeLabel: '1 minute',
        proLabel: '5 minutes',
      ),
      _FeatureItem(
        icon: Icons.cloud_upload_rounded,
        title: 'Larger File Uploads',
        description: 'Send bigger images and videos',
        freeLabel: '10 MB',
        proLabel: '50 MB',
      ),
      _FeatureItem(
        icon: Icons.local_fire_department_rounded,
        title: 'Bond Restore',
        description: 'Restore broken bonds for free',
        freeLabel: 'Pay with Gup Points',
        proLabel: '1 free restore/week',
      ),
      _FeatureItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Pro Badge',
        description: 'Show off your Pro status',
        freeLabel: 'No badge',
        proLabel: 'Exclusive Pro badge',
      ),
      _FeatureItem(
        icon: Icons.download_rounded,
        title: 'Chat Export',
        description: 'Export conversations as text files',
        freeLabel: 'Not available',
        proLabel: 'Export as TXT',
      ),
    ];

    return features.map((f) => _buildFeatureCard(c, f)).toList();
  }

  Widget _buildFeatureCard(AppThemeColors c, _FeatureItem feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.isDark
            ? const Color(0xFF151525)
            : c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.primary.withOpacity(0.15),
                  c.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: c.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPlanChip(
                      label: feature.freeLabel,
                      color: c.textLow,
                      bgColor: c.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 6),
                    _buildPlanChip(
                      label: feature.proLabel,
                      color: const Color(0xFFFFD700),
                      bgColor: const Color(0xFFFFD700).withOpacity(0.12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanChip({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Pricing cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPricingCards(AppThemeColors c, SubscriptionProvider sub) {
    // Define plans — prices shown are placeholders until products load
    final plans = [
      _PricingPlan(
        title: 'Monthly',
        productId: ProProductIds.monthly,
        fallbackPrice: '₹99/mo',
        period: '/month',
        savings: null,
      ),
      _PricingPlan(
        title: 'Yearly',
        productId: ProProductIds.yearly,
        fallbackPrice: '₹799/yr',
        period: '/year',
        savings: 'Save ~33%',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(plans.length, (index) {
          final plan = plans[index];
          final isSelected = _selectedPlanIndex == index;
          final product = sub.getProduct(plan.productId);
          final price = product?.price ?? plan.fallbackPrice;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 5,
                  right: index == plans.length - 1 ? 0 : 5,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (c.isDark
                          ? const Color(0xFF1E1830)
                          : const Color(0xFFF5F0FF))
                      : (c.isDark
                          ? const Color(0xFF151525)
                          : c.surfaceAlt),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : c.border.withOpacity(0.4),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    if (plan.savings != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan.savings!,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 20),
                    Text(
                      plan.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : c.textHigh,
                      ),
                    ),
                    Text(
                      plan.period,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: c.textMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : c.textLow,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Subscribe button
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubscribeButton(AppThemeColors c, SubscriptionProvider sub) {
    final plans = [ProProductIds.monthly, ProProductIds.yearly];
    final selectedProductId = plans[_selectedPlanIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: sub.isLoading
                  ? null
                  : () async {
                      final product = sub.getProduct(selectedProductId);
                      if (product != null) {
                        await sub.purchase(product);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Product not available. Make sure you have an active '
                              'internet connection and the app is downloaded '
                              'from the Play Store.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: c.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: sub.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black54,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Subscribe Now',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (sub.error != null) ...[
            const SizedBox(height: 8),
            Text(
              sub.error!,
              style: GoogleFonts.poppins(
                color: c.error,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Cancel anytime from Google Play subscriptions.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: c.textLow,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Restore purchases button
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRestoreButton(AppThemeColors c, SubscriptionProvider sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextButton(
        onPressed: sub.isLoading
            ? null
            : () async {
                await sub.restorePurchases();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sub.isPro
                            ? 'Pro subscription restored! 🎉'
                            : 'No active subscription found.',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      backgroundColor: sub.isPro ? c.success : c.textMid,
                    ),
                  );
                }
              },
        child: Text(
          'Restore previous purchase',
          style: GoogleFonts.poppins(
            color: c.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Helper data classes ─────────────────────────────────────────────────────

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final String freeLabel;
  final String proLabel;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.freeLabel,
    required this.proLabel,
  });
}

class _PricingPlan {
  final String title;
  final String productId;
  final String fallbackPrice;
  final String period;
  final String? savings;

  const _PricingPlan({
    required this.title,
    required this.productId,
    required this.fallbackPrice,
    required this.period,
    this.savings,
  });
}
