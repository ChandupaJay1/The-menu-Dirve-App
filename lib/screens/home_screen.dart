import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().driver?.token;
      if (token != null) {
        context.read<OrderProvider>().fetchLatestOrders(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;
    final orderProvider = context.watch<OrderProvider>();
    final latestOrders = orderProvider.latestOrders;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'THE MENU',
          style: GoogleFonts.lato(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: _AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (driver?.token != null) {
              await orderProvider.fetchLatestOrders(driver!.token!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha((0.3 * 255).toInt()),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${driver?.name.split(' ').first ?? 'Driver'}! 👋',
                              style: GoogleFonts.lato(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ready to deliver today?',
                              style: GoogleFonts.lato(
                                color:
                                    Colors.black.withAlpha((0.7 * 255).toInt()),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.black,
                        size: 50,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Status toggle
                Text(
                  'My Status',
                  style: GoogleFonts.lato(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusToggleCard(),

                const SizedBox(height: 28),

                // Stats row
                Text(
                  "Today's Summary",
                  style: GoogleFonts.lato(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        value: '0',
                        color: AppTheme.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.route_rounded,
                        label: 'Distance',
                        value: '0 km',
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: 'Earnings',
                        value: 'Rs.0',
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Latest Orders Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latest Orders',
                      style: GoogleFonts.lato(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/orders'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (orderProvider.isLoading && latestOrders.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (orderProvider.errorMessage != null &&
                    latestOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.error.withAlpha(50)),
                    ),
                    child: Center(
                      child: Text(
                        orderProvider.errorMessage!,
                        style: GoogleFonts.lato(color: AppTheme.error),
                      ),
                    ),
                  )
                else if (latestOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        'No orders assigned yet',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...latestOrders.map((order) => _OrderCard(order: order)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryAddress,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${order.totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.lato(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color =
        status.toLowerCase() == 'assigned' ? Colors.blue : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.lato(
            color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── App Drawer ────────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.driver;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primary,
            ),
            accountName: Text(
              driver?.name ?? 'Driver Name',
              style: GoogleFonts.lato(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              driver?.email ?? 'driver@email.com',
              style: GoogleFonts.lato(color: Colors.black87),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(Icons.person, color: AppTheme.primary, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: AppTheme.primary),
            title: Text('Dashboard', style: GoogleFonts.lato()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.primary),
            title: Text('My Orders', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: AppTheme.primary),
            title: Text('My Profile', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppTheme.primary),
            title: Text('Order History', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/orders');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
            title:
                Text('Logout', style: GoogleFonts.lato(color: AppTheme.error)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Status Toggle Card ────────────────────────────────────────────────────────
class _StatusToggleCard extends StatefulWidget {
  @override
  State<_StatusToggleCard> createState() => _StatusToggleCardState();
}

class _StatusToggleCardState extends State<_StatusToggleCard> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _isOnline
            ? AppTheme.success.withAlpha((0.12 * 255).toInt())
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOnline ? AppTheme.success : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline
                  ? AppTheme.success
                  : Theme.of(context).colorScheme.onSurface.withAlpha(153),
              boxShadow: _isOnline
                  ? [
                      BoxShadow(
                          color:
                              AppTheme.success.withAlpha((0.5 * 255).toInt()),
                          blurRadius: 8)
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isOnline ? 'You are Online' : 'You are Offline',
              style: GoogleFonts.lato(
                color: _isOnline
                    ? AppTheme.success
                    : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: _isOnline,
            onChanged: (val) => setState(() => _isOnline = val),
            activeThumbColor: AppTheme.success,
            activeTrackColor: AppTheme.success.withAlpha((0.5 * 255).toInt()),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lato(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
