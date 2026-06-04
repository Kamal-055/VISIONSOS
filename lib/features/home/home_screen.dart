import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision/core/theme/app_theme.dart';
import 'package:vision/providers/auth_provider.dart';
import 'package:vision/providers/sos_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final sosState = ref.watch(sosNotifierProvider);
    final user = authState.value;
    final String displayName = user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              await ref.read(authNotifierProvider.notifier).loadUserDetails(user.uid);
            }
          },
          color: AppTheme.primary,
          backgroundColor: AppTheme.cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, displayName),
                const SizedBox(height: 24),
                _buildSafetyStatus(sosState),
                const SizedBox(height: 24),
                _buildSOSModuleCard(context, sosState),
                const SizedBox(height: 20),
                Text(
                  'Safety Modules',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.map_outlined,
                      title: 'Live Tracking',
                      status: sosState.isActive ? 'ACTIVE' : 'GPS Ready',
                      details: 'Real-time GPS broadcast',
                      color: AppTheme.primary,
                      isActive: sosState.isActive,
                    ),
                    _buildFeatureCard(
                      icon: Icons.history_rounded,
                      title: 'Safety Logs',
                      status: 'View History',
                      details: 'Past incidents & alerts',
                      color: AppTheme.accent,
                      isActive: false,
                    ),
                    _buildFeatureCard(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Streetlights',
                      status: sosState.isActive ? 'TRIGGERED' : 'IoT Ready',
                      details: 'Smart zone lighting',
                      color: Colors.amber,
                      isActive: sosState.isActive,
                    ),
                    _buildFeatureCard(
                      icon: Icons.local_police_outlined,
                      title: 'Police',
                      status: sosState.isActive ? 'NOTIFIED' : 'On Standby',
                      details: 'Emergency dispatch channel',
                      color: AppTheme.success,
                      isActive: sosState.isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: GoogleFonts.outfit(
                color: AppTheme.textMutedColor,
                fontSize: 14,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.glassBorder, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyStatus(SOSState sosState) {
    final isActive = sosState.isActive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.error.withOpacity(0.1)
            : AppTheme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.error.withOpacity(0.5)
              : AppTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.error.withOpacity(0.2)
                      : AppTheme.success.withOpacity(0.2),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYSTEM STATUS',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  isActive
                      ? '🚨 SOS Alert Active — Help Dispatched'
                      : 'All Networks Secure',
                  style: GoogleFonts.outfit(
                    color: isActive ? AppTheme.error : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
            color: isActive ? AppTheme.error : AppTheme.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSOSModuleCard(BuildContext context, SOSState sosState) {
    return GestureDetector(
      onTap: () => context.push('/sos'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(sosState.isActive ? 0.3 : 0.2),
              const Color(0x110F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.error.withOpacity(sosState.isActive ? 0.6 : 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMERGENCY SOS',
                    style: GoogleFonts.outfit(
                      color: AppTheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sosState.isActive
                        ? 'Alert Active — Tap to Manage'
                        : 'Press & Hold to Activate',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sosState.isActive
                        ? '✓ GPS  ✓ Police  ✓ Streetlights'
                        : 'GPS · Police · Streetlights · Tracking',
                    style: GoogleFonts.outfit(
                      color: sosState.isActive
                          ? AppTheme.success
                          : AppTheme.textMutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: sosState.isActive
                          ? null
                          : AppTheme.alertGradient,
                      color: sosState.isActive
                          ? AppTheme.cardColor.withOpacity(0.6)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: sosState.isActive
                          ? Border.all(color: AppTheme.error.withOpacity(0.4))
                          : null,
                    ),
                    child: Text(
                      sosState.isActive ? 'MANAGE ALERT →' : 'OPEN SOS →',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Right SOS button visual
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(
                        sosState.isActive ? 0.5 : 0.3),
                    blurRadius: sosState.isActive ? 20 : 12,
                    spreadRadius: sosState.isActive ? 4 : 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'SOS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String status,
    required String details,
    required Color color,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.1)
            : AppTheme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : AppTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : AppTheme.glassBorder,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: GoogleFonts.outfit(
                  color: isActive ? color : AppTheme.textMutedColor,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: GoogleFonts.outfit(
                  color: AppTheme.textMutedColor,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
