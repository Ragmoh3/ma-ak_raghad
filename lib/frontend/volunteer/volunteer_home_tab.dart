import 'package:flutter/material.dart';
import '../widgets/current_user_name.dart';
import '../theme/app_theme.dart';
import '../shared/messages_tab.dart';
import 'available_requests_screen.dart';
import 'schedule_tab.dart';
import 'volunteer_profile_tab.dart';

class VolunteerHomeTab extends StatelessWidget {
  const VolunteerHomeTab({super.key});

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
            child: Icon(Icons.notifications_outlined,
                color: AppColors.primaryNavy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Your support makes a real difference.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.selectedCardFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Be the support\nsomeone needs',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('Share your experience, make a positive impact.',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AvailableRequestsScreen()),
                  ),
                  child: const Text('View requests'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _QuickAction(
                icon: Icons.list_alt_outlined,
                title: 'Requests',
                subtitle: 'View new requests',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AvailableRequestsScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.calendar_today_outlined,
                title: 'Schedule',
                subtitle: 'Your upcoming shifts',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScheduleTab()),
                ),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                title: 'Messages',
                subtitle: 'Chat with patients',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MessagesTab()),
                ),
              ),
              _QuickAction(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Your information',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const VolunteerProfileTab()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Your Impact',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _StatCard(value: '2', label: 'Active mentees')),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '6', label: 'Total chats')),
              SizedBox(width: 10),
              Expanded(
                  child: _StatCard(value: '28', label: 'Hours volunteered')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryNavy),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
