import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  // Responsive text size calculator
  double responsiveFontSize(BuildContext context, double baseSize) {
    double width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 400) return baseSize * 0.9;
    if (width > 600) return baseSize * 1.2;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with Gradient
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageIcon(
                  const AssetImage('assets/icon/app_icon.png'),
                  size: responsiveFontSize(context, 40),
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Text(
                  'Eye Care',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsiveFontSize(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Digital Eye Strain Protection',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: responsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: responsiveFontSize(context, 14),
                horizontal: responsiveFontSize(context, 12),
              ),
              children: [
                // Menu Items
                _drawerItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings (Comming Soon)',
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.insights_outlined,
                  title: 'Statistics (Comming Soon)',
                  onTap: () {
                    // Navigate to statistics
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support (Comming Soon)',
                  onTap: () {
                    // Navigate to help
                  },
                ),

                // Divider
                Padding(
                  padding: EdgeInsets.only(
                    bottom: responsiveFontSize(context, 10),
                  ),
                  child: const Divider(
                    color: Color(0xFFE0E0E0),
                    thickness: 1,
                  ),
                ),

                // Info Container
                Container(
                  padding: EdgeInsets.all(responsiveFontSize(context, 16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF388E3C),
                            size: responsiveFontSize(context, 20),
                          ),
                          SizedBox(width: responsiveFontSize(context, 8)),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              fontSize: responsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsiveFontSize(context, 12)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoItem(context, 'Works in background even when app is closed'),
                          _infoItem(context, 'Tracks time only when screen is ON'),
                          _infoItem(context, 'Resets timer when screen turns OFF'),
                          _infoItem(context, 'Reminds you every 20 minutes'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(responsiveFontSize(context, 16)),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: const Color(0xFF9E9E9E),
                    fontSize: responsiveFontSize(context, 12),
                  ),
                ),
                Text(
                  '© 2024 Eye Care',
                  style: TextStyle(
                    color: const Color(0xFF9E9E9E),
                    fontSize: responsiveFontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        bool isSelected = false,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: responsiveFontSize(context, 1),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF999999),
          size: responsiveFontSize(context, 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF999999),
          ),
        ),
        trailing: isSelected
            ? Icon(
          Icons.circle,
          size: responsiveFontSize(context, 8),
          color: const Color(0xFF2196F3),
        )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsiveFontSize(context, 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: isSelected
            ? const Color(0xFF2196F3).withOpacity(0.08)
            : Colors.transparent,
        onTap: onTap,
      ),
    );
  }

  Widget _infoItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsiveFontSize(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: responsiveFontSize(context, 6),
            color: const Color(0xFF4CAF50),
          ),
          SizedBox(width: responsiveFontSize(context, 8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsiveFontSize(context, 14),
                color: const Color(0xFF616161),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}