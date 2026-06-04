import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vision/core/theme/app_theme.dart';
import 'package:vision/providers/auth_provider.dart';
import 'package:vision/providers/sos_provider.dart';
import 'package:vision/widgets/feedback_dialogs.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with TickerProviderStateMixin {
  // Pulse animation for active state
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Ring expanding animation
  late AnimationController _ringController;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  // Press & hold animation for SOS button
  late AnimationController _holdController;
  late Animation<double> _holdProgress;

  bool _isHolding = false;
  bool _holdCompleted = false;

  @override
  void initState() {
    super.initState();

    // Pulsing core
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Expanding rings
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _ring1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _ring2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Press & hold progress (2 seconds)
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _holdProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _holdController, curve: Curves.easeInOut),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isHolding) {
        _holdCompleted = true;
        _triggerSOS();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    final sosState = ref.read(sosNotifierProvider);
    if (!sosState.isIdle) return;
    setState(() {
      _isHolding = true;
      _holdCompleted = false;
    });
    _holdController.forward();
  }

  void _onHoldEnd() {
    if (_holdCompleted) return;
    setState(() => _isHolding = false);
    _holdController.reverse();
  }

  Future<void> _triggerSOS() async {
    try {
      await ref.read(sosNotifierProvider.notifier).activateSOS();
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'SOS Failed',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _cancelSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel SOS Alert?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will stop all emergency notifications, live tracking, and streetlight triggers. Only cancel if you are safe.',
          style: GoogleFonts.outfit(color: AppTheme.textMutedColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Active',
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel SOS',
                style: GoogleFonts.outfit(
                    color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sosNotifierProvider.notifier).cancelSOS();
        setState(() {
          _isHolding = false;
          _holdCompleted = false;
        });
        _holdController.reset();
        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'SOS Cancelled',
            message: 'Emergency alert has been cancelled. All services have been deactivated. Stay safe!',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(context, title: 'Cancel Failed', message: e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.value?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Emergency SOS',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sosState.isActive
                  ? AppTheme.error.withOpacity(0.2)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sosState.isActive
                    ? AppTheme.error.withOpacity(0.5)
                    : AppTheme.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sosState.isActive ? AppTheme.error : AppTheme.success,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sosState.isActive ? 'LIVE' : 'READY',
                  style: GoogleFonts.outfit(
                    color: sosState.isActive ? AppTheme.error : AppTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Status Banner ───────────────────────────────────────────
            _buildStatusBanner(sosState),

            // ─── Main SOS Button Area ─────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (sosState.isActive) ...[
                      _buildActiveInfo(sosState),
                      const SizedBox(height: 40),
                    ],
                    _buildSOSButton(sosState, userName),
                    const SizedBox(height: 32),
                    _buildInstructionText(sosState),
                  ],
                ),
              ),
            ),

            // ─── Bottom Panel ─────────────────────────────────────────────
            _buildBottomPanel(sosState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(SOSState sosState) {
    Color bannerColor;
    String bannerText;
    IconData bannerIcon;

    if (sosState.isActive) {
      bannerColor = AppTheme.error;
      bannerText = 'EMERGENCY ALERT ACTIVE — HELP IS ON THE WAY';
      bannerIcon = Icons.warning_amber_rounded;
    } else if (sosState.isActivating) {
      bannerColor = Colors.orange;
      bannerText = 'ACTIVATING EMERGENCY SYSTEMS...';
      bannerIcon = Icons.sync_rounded;
    } else if (sosState.isCancelling) {
      bannerColor = Colors.orange;
      bannerText = 'DEACTIVATING EMERGENCY ALERT...';
      bannerIcon = Icons.sync_rounded;
    } else {
      bannerColor = AppTheme.success;
      bannerText = 'SYSTEM READY — PRESS & HOLD TO ACTIVATE';
      bannerIcon = Icons.shield_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: bannerColor.withOpacity(0.15),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bannerText,
              style: GoogleFonts.outfit(
                color: bannerColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (sosState.isActivating || sosState.isCancelling)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: bannerColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveInfo(SOSState sosState) {
    final elapsed = sosState.activatedAt != null
        ? DateTime.now().difference(sosState.activatedAt!)
        : Duration.zero;
    final timeStr =
        '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActiveStatTile(
              Icons.timer_outlined, 'Active For', timeStr, AppTheme.error),
          Container(width: 1, height: 40, color: AppTheme.glassBorder),
          _buildActiveStatTile(
              Icons.gps_fixed, 'Live Tracking', 'ON', AppTheme.success),
          Container(width: 1, height: 40, color: AppTheme.glassBorder),
          _buildActiveStatTile(
              Icons.local_police_outlined, 'Police', 'NOTIFIED', AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildActiveStatTile(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(
                color: AppTheme.textMutedColor, fontSize: 10)),
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSOSButton(SOSState sosState, String userName) {
    return GestureDetector(
      onLongPressStart: sosState.isIdle ? (_) => _onHoldStart() : null,
      onLongPressEnd: sosState.isIdle ? (_) => _onHoldEnd() : null,
      onLongPressCancel: sosState.isIdle ? _onHoldEnd : null,
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Expanding rings (active only) ──
            if (sosState.isActive)
              AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRing(_ring1.value, 130, AppTheme.error),
                    _buildRing(_ring2.value, 130, AppTheme.error),
                    _buildRing(_ring3.value, 130, AppTheme.error),
                  ],
                ),
              ),

            // ── Hold progress ring (idle) ──
            if (sosState.isIdle)
              AnimatedBuilder(
                animation: _holdProgress,
                builder: (context, _) => CustomPaint(
                  size: const Size(240, 240),
                  painter: _HoldProgressPainter(
                    progress: _holdProgress.value,
                    color: AppTheme.error,
                  ),
                ),
              ),

            // ── Outer glow ring ──
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.error.withOpacity(
                  sosState.isActive ? 0.12 : 0.06,
                ),
                border: Border.all(
                  color: AppTheme.error.withOpacity(
                    sosState.isActive ? 0.4 : 0.2,
                  ),
                  width: 2,
                ),
              ),
            ),

            // ── Core button ──
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseScale, _pulseOpacity, _holdProgress]),
              builder: (context, _) {
                final scale = sosState.isActive
                    ? _pulseScale.value
                    : (1.0 - (_holdProgress.value * 0.05));

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: sosState.isActivating || sosState.isCancelling
                            ? [
                                Colors.orange.shade700,
                                Colors.orange.shade900,
                              ]
                            : [
                                AppTheme.error,
                                const Color(0xFFB91C1C),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withOpacity(
                            sosState.isActive
                                ? (_pulseOpacity.value * 0.5)
                                : 0.3,
                          ),
                          blurRadius: sosState.isActive ? 40 : 20,
                          spreadRadius: sosState.isActive ? 6 : 2,
                        ),
                      ],
                    ),
                    child: _buildButtonContent(sosState),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonContent(SOSState sosState) {
    if (sosState.isActivating) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(height: 10),
          Text('ACTIVATING',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      );
    }

    if (sosState.isCancelling) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(height: 10),
          Text('STOPPING',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SOS',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sosState.isActive ? 'TAP TO CANCEL' : 'HOLD 2s',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRing(double progress, double maxRadius, Color color) {
    return Opacity(
      opacity: (1.0 - progress).clamp(0.0, 1.0),
      child: Container(
        width: maxRadius * 2 * progress + 160,
        height: maxRadius * 2 * progress + 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: (1.5 * (1.0 - progress)).clamp(0.2, 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText(SOSState sosState) {
    if (sosState.isActive) {
      return GestureDetector(
        onTap: _cancelSOS,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cancel Emergency Alert',
                style: GoogleFonts.outfit(
                    color: AppTheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const Icon(Icons.touch_app_outlined,
            color: AppTheme.textMutedColor, size: 24),
        const SizedBox(height: 8),
        Text(
          'Press and hold the SOS button\nfor 2 seconds to activate',
          style: GoogleFonts.outfit(
            color: AppTheme.textMutedColor,
            fontSize: 13,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomPanel(SOSState sosState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.4),
        border: const Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // System Status Tiles
          Row(
            children: [
              _buildSystemTile(
                icon: Icons.local_police_outlined,
                label: 'Police',
                isActive: sosState.isActive,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildSystemTile(
                icon: Icons.gps_fixed,
                label: 'GPS Track',
                isActive: sosState.isActive,
                color: AppTheme.success,
              ),
              const SizedBox(width: 12),
              _buildSystemTile(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Streetlights',
                isActive: sosState.isActive,
                color: Colors.amber,
              ),
              const SizedBox(width: 12),
              _buildSystemTile(
                icon: Icons.people_outline_rounded,
                label: 'Responders',
                isActive: sosState.isActive,
                color: AppTheme.accent,
              ),
            ],
          ),
          if (sosState.alertId != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: AppTheme.textMutedColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Alert ID: ',
                    style: GoogleFonts.outfit(
                        color: AppTheme.textMutedColor, fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      sosState.alertId!,
                      style: GoogleFonts.outfit(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemTile({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.1)
              : AppTheme.background.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : AppTheme.glassBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : AppTheme.textMutedColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? color : AppTheme.textMutedColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}

// Custom painter for hold-to-activate progress ring
class _HoldProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HoldProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_HoldProgressPainter old) =>
      old.progress != progress || old.color != color;
}
