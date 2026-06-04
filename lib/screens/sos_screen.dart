import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision/providers/auth_provider.dart';
import 'package:vision/providers/sos_provider.dart';
import 'package:vision/screens/profile_screen.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerImmediateSOS() async {
    try {
      await ref.read(sosNotifierProvider.notifier).triggerSOS();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SOS Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deactivateSOS() async {
    try {
      await ref.read(sosNotifierProvider.notifier).deactivateSOS();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SOS deactivated. Streaming stopped.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deactivation Error: $e',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final sosState = ref.watch(sosNotifierProvider);

    final userName = authState.user?.name ?? 'Citizen';
    final isSOSActive = sosState.isSOSActive || (sosState.status == 'ACTIVE');

    // Show error toast if any
    ref.listen<SOSState>(sosNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        ref.read(sosNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'VISION SOS',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Profile Screen Navigation Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient pulsating light behind SOS button when active
          if (isSOSActive)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withOpacity(0.08),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome text & general status banner
                  _buildCitizenBanner(userName, isSOSActive),
                  const SizedBox(height: 24),

                  // coordinates & telemetry card
                  _buildTelemetryCard(sosState),
                  const SizedBox(height: 24),

                  // Smart streetlights & Responder monitoring status
                  _buildLiveStatusCard(sosState),
                  const SizedBox(height: 48),

                  // Big Interactive SOS Trigger Button
                  Center(
                    child: isSOSActive
                        ? ScaleTransition(
                            scale: _pulseScale,
                            child: _buildSOSButtonWidget(
                              isSOSActive: true,
                              onTap: () {}, // Already active, tap does nothing (must use Cancel button below)
                            ),
                          )
                        : _buildSOSButtonWidget(
                            isSOSActive: false,
                            onTap: _triggerImmediateSOS,
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Emergency cancel buttons
                  if (isSOSActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                        label: Text(
                          'DEACTIVATE SOS',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: sosState.isLoading ? null : _deactivateSOS,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenBanner(String name, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFF334155).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
            color: isActive ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CITIZEN PORTAL',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFEF4444).withOpacity(0.2)
                  : const Color(0xFF22C55E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'SOS ACTIVE' : 'READY',
              style: GoogleFonts.outfit(
                color: isActive ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(SOSState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPS COORDINATES & TELEMETRY',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryTile(
                  label: 'Latitude',
                  value: state.latitude.toStringAsFixed(6),
                  icon: Icons.location_on_outlined,
                ),
              ),
              Expanded(
                child: _buildTelemetryTile(
                  label: 'Longitude',
                  value: state.longitude.toStringAsFixed(6),
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF94A3B8), size: 16),
              const SizedBox(width: 8),
              Text(
                'Last Updated:',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.lastUpdated.isEmpty ? 'NEVER' : state.lastUpdated,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11)),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveStatusCard(SOSState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMART DISPATCH & ESP STREETLIGHTS',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Nearest Light',
                  value: state.nearestLight,
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  title: 'Distance',
                  value: '${state.distance.toStringAsFixed(1)} m',
                  color: const Color(0xFF2563EB),
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  title: 'Case Status',
                  value: state.incidentStatus,
                  color: state.incidentStatus == 'ACTIVE' || state.incidentStatus == 'RESPONDING'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Assigned Light',
                  value: state.assignedLight,
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  title: 'Assigned Officer',
                  value: state.assignedOfficer,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  title: 'Case ID',
                  value: state.caseId,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String title, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSOSButtonWidget({required bool isSOSActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isSOSActive
                ? [const Color(0xFFDC2626), const Color(0xFF7F1D1D)]
                : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
          ),
          boxShadow: [
            BoxShadow(
              color: isSOSActive
                  ? const Color(0xFFEF4444).withOpacity(0.5)
                  : Colors.black.withOpacity(0.4),
              blurRadius: isSOSActive ? 30 : 15,
              spreadRadius: isSOSActive ? 6 : 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSOSActive ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
            width: 3,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSOSActive ? Icons.wifi_tethering_rounded : Icons.touch_app_rounded,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'SOS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSOSActive ? 'STREAMING' : 'PRESS NOW',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
