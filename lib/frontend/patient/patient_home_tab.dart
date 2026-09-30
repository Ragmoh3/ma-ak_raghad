import 'package:flutter/material.dart';
import '../widgets/current_user_name.dart';
import '../theme/app_theme.dart';
import 'find_volunteer_screen.dart';
import 'journey_tab.dart';
import 'resources_screen.dart';
import '../shared/messages_tab.dart';
import 'patient_profile_tab.dart';

class PatientHomeTab extends StatelessWidget {
  const PatientHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CurrentUserName(prefix: 'Hello ',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(width: 6),
            const Icon(Icons.favorite, color: AppColors.primaryNavy, size: 18),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.selectedCardFill,
              child: Icon(Icons.person, color: AppColors.primaryNavy, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("You're not alone. We're here with you.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 18),

          // ---- Hero CTA card: subtle navy gradient + soft shadow ----
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.selectedCardFill, Color(0xFFDCE7F0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.volunteer_activism_outlined,
                      color: AppColors.primaryNavy, size: 22),
                ),
                const SizedBox(height: 14),
                const Text('Find the right volunteer\nfor your journey',
                    style: TextStyle(
                        fontSize: 19,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('Get matched with someone who understands you.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(170, 46),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const FindVolunteerScreen()),
                  ),
                  child: const Text('Find a volunteer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text('Quick access',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 15)),
          const SizedBox(height: 12),

          // ---- Quick actions grid ----
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _QuickAction(
                icon: Icons.timeline_outlined,
                iconColor: const Color(0xFF3E6E8E),
                iconBg: const Color(0xFFE6F0F5),
                title: 'My Journey',
                subtitle: 'Track your progress',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JourneyTab()),
                ),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                iconColor: const Color(0xFF4D7C5F),
                iconBg: const Color(0xFFE7F1E9),
                title: 'Messages',
                subtitle: 'Chat with your volunteer',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MessagesTab()),
                ),
              ),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF8A6D1D),
                iconBg: const Color(0xFFF6EFDD),
                title: 'Resources',
                subtitle: 'Helpful articles & tips',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResourcesScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.person_outline,
                iconColor: AppColors.primaryNavy,
                iconBg: AppColors.selectedCardFill,
                title: 'Profile',
                subtitle: 'Your account',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatientProfileTab()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const Text('Upcoming',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 15)),
          const SizedBox(height: 10),

          // ---- Upcoming chat card ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fieldBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.selectedCardFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primaryNavy, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat with your volunteer',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('Today · 4:00 PM',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
