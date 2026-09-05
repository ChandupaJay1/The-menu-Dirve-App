import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/side_menu.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _pollingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DateTime? _lastSyncedAt;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _start15MinBackgroundSync();
    });
  }

  // 15-minute automatic background heartbeat sync
  void _start15MinBackgroundSync() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!mounted) return;
      _quietPoll();
    });
  }

  Future<void> _quietPoll() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final driver = auth.driver;
    if (driver?.token != null) {
      await auth.refreshProfile();
      if (mounted) {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.fetchLatestOrders(driver!.token!);
        await orderProvider.fetchAllOrders(driver.token!);
        setState(() {
          _lastSyncedAt = DateTime.now();
        });
      }
    }
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final driver = auth.driver;
    if (driver?.token != null) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await Future.wait([
        auth.refreshProfile(),
        orderProvider.fetchLatestOrders(driver!.token!),
        orderProvider.fetchAllOrders(driver.token!),
      ]);
      if (mounted) {
        setState(() {
          _lastSyncedAt = DateTime.now();
        });
      }
    }
  }

  Future<void> _handleManualRefresh() async {
    if (_isManualRefreshing) return;
    setState(() => _isManualRefreshing = true);
    await _fetchData();
    if (mounted) {
      setState(() => _isManualRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Synced with server (${_formatTime(_lastSyncedAt ?? DateTime.now())})',
                style: GoogleFonts.lato(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _showStatusPicker(BuildContext context, String currentStatus) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Your Status',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusOptionTile(
                  title: 'Available (Online)',
                  subtitle: 'Ready to receive new orders',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  isSelected: currentStatus == 'available',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.setStatus('available');
                    _fetchData();
                  },
                ),
                _StatusOptionTile(
                  title: 'Busy',
                  subtitle: 'Temporarily paused from receiving dispatches',
                  icon: Icons.pause_circle_filled_rounded,
                  color: const Color(0xFFF59E0B),
                  isSelected: currentStatus == 'busy',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.setStatus('busy');
                    _fetchData();
                  },
                ),
                _StatusOptionTile(
                  title: 'Offline',
                  subtitle: 'Not taking any orders right now',
                  icon: Icons.offline_bolt_rounded,
                  color: Colors.grey,
                  isSelected: currentStatus == 'offline',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.setStatus('offline');
                    _fetchData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final driver = authProvider.driver;
    final driverName = (driver?.name != null && driver!.name.trim().isNotEmpty)
        ? driver.name
        : 'Driver';

    final rawStatus = (driver?.status ?? (driver?.isActive == true ? 'available' : 'offline')).toLowerCase();
    final bool isOnline = rawStatus != 'offline';

    final allOrders = orderProvider.allOrders;
    final latestOrders = orderProvider.latestOrders.isNotEmpty
        ? orderProvider.latestOrders
        : allOrders.take(4).toList();

    final totalOrdersCount = allOrders.length;
    final doneOrdersCount = allOrders.where((o) => o.status.toLowerCase() == 'delivered').length;
    final activeOrdersCount = allOrders
        .where((o) => o.status.toLowerCase() == 'assigned' || o.status.toLowerCase() == 'picked_up')
        .length;

    // Status Styling
    Color statusPrimaryColor;
    Color statusSecondaryColor;
    Color statusTextColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (rawStatus == 'on_delivery') {
      statusPrimaryColor = const Color(0xFF2563EB);
      statusSecondaryColor = const Color(0xFF1D4ED8);
      statusTextColor = Colors.white;
      statusTitle = 'On Delivery';
      statusSubtitle = 'Active delivery order in progress';
      statusIcon = Icons.two_wheeler_rounded;
    } else if (rawStatus == 'busy') {
      statusPrimaryColor = const Color(0xFFF59E0B);
      statusSecondaryColor = const Color(0xFFD97706);
      statusTextColor = Colors.black87;
      statusTitle = 'Busy';
      statusSubtitle = 'Paused from new order assignments';
      statusIcon = Icons.pause_circle_rounded;
    } else if (isOnline) {
      statusPrimaryColor = AppTheme.primary;
      statusSecondaryColor = AppTheme.primaryDark;
      statusTextColor = Colors.black;
      statusTitle = 'Online & Available';
      statusSubtitle = 'Ready for new order assignments';
      statusIcon = Icons.electric_bolt_rounded;
    } else {
      statusPrimaryColor = Theme.of(context).colorScheme.surface;
      statusSecondaryColor = Theme.of(context).colorScheme.surface;
      statusTextColor = Theme.of(context).colorScheme.onSurface;
      statusTitle = 'You are Offline';
      statusSubtitle = 'Turn on switch to start receiving orders';
      statusIcon = Icons.power_settings_new_rounded;
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleManualRefresh,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Menu, Manual Refresh & Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: Icon(
                              Icons.menu_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: GoogleFonts.lato(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  driverName,
                                  style: GoogleFonts.lato(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Realtime glowing pulse indicator
                                FadeTransition(
                                  opacity: isOnline ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                      boxShadow: isOnline
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Manual Refresh Button
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: IconButton(
                            tooltip: 'Manual Refresh (Sync Orders & Status)',
                            onPressed: _isManualRefreshing ? null : _handleManualRefresh,
                            icon: _isManualRefreshing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profile Button
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/profile'),
                            icon: Icon(
                              Icons.person_outline_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Sync status indicator bar
                Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastSyncedAt != null
                          ? 'Last updated ${_formatTime(_lastSyncedAt!)} • Auto-syncs every 15 min'
                          : 'Auto-syncs every 15 min • Pull down or tap ⟳ to refresh',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Realtime Status Card
                GestureDetector(
                  onTap: () => _showStatusPicker(context, rawStatus),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusPrimaryColor, statusSecondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: !isOnline
                          ? Border.all(color: Theme.of(context).dividerColor)
                          : null,
                      boxShadow: isOnline
                          ? [
                              BoxShadow(
                                color: statusPrimaryColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? Colors.black.withValues(alpha: 0.12)
                                          : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      color: statusTextColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              statusTitle,
                                              style: GoogleFonts.lato(
                                                color: statusTextColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: statusTextColor,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          statusSubtitle,
                                          style: GoogleFonts.lato(
                                            color: isOnline
                                                ? statusTextColor.withValues(alpha: 0.8)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isOnline,
                              activeThumbColor: Colors.black,
                              activeTrackColor: Colors.black26,
                              onChanged: (value) async {
                                final nextStatus = value ? 'available' : 'offline';
                                final success = await authProvider.setStatus(nextStatus);
                                if (success) {
                                  _fetchData();
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update status on server')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Today's Summary Header
                Text(
                  "Today's Overview",
                  style: GoogleFonts.lato(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Total Orders',
                        value: totalOrdersCount.toString(),
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.delivery_dining_rounded,
                        label: 'Active',
                        value: activeOrdersCount.toString(),
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Delivered',
                        value: doneOrdersCount.toString(),
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Latest Orders Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Assigned Orders',
                          style: GoogleFonts.lato(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (activeOrdersCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$activeOrdersCount Live',
                              style: GoogleFonts.lato(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/orders'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Orders List
                if (orderProvider.isLoading && latestOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (latestOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No orders assigned yet',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnline
                              ? 'Waiting for new orders dispatched by Admin'
                              : 'Turn on online status to become available for dispatches',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latestOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = latestOrders[index];
                      return _OrderCard(
                        order: order,
                        token: driver?.token,
                        onStatusUpdated: _fetchData,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).dividerColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: color)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final String? token;
  final VoidCallback onStatusUpdated;

  const _OrderCard({
    required this.order,
    required this.token,
    required this.onStatusUpdated,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isUpdating = false;

  Future<void> _handleStatusUpdate(String nextStatus) async {
    if (widget.token == null) return;
    setState(() => _isUpdating = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.updateStatus(
      widget.token!,
      widget.order.id,
      nextStatus,
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        widget.onStatusUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.status.toLowerCase();

    Color statusBgColor;
    Color statusTextColor;
    if (status == 'delivered') {
      statusBgColor = AppTheme.success.withValues(alpha: 0.15);
      statusTextColor = AppTheme.success;
    } else if (status == 'picked_up') {
      statusBgColor = Colors.orange.withValues(alpha: 0.15);
      statusTextColor = Colors.orange;
    } else if (status == 'cancelled') {
      statusBgColor = AppTheme.error.withValues(alpha: 0.15);
      statusTextColor = AppTheme.error;
    } else {
      statusBgColor = const Color(0xFF2563EB).withValues(alpha: 0.15);
      statusTextColor = const Color(0xFF2563EB);
    }

    return Container(
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
                  fontSize: 16,
                  color: AppTheme.primaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                order.customerName,
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              if (order.customerPhone.isNotEmpty && order.customerPhone != '-') ...[
                const Spacer(),
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (status == 'assigned')
                ElevatedButton(
                  onPressed: _isUpdating ? null : () => _handleStatusUpdate('picked_up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Pick Up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                )
              else if (status == 'picked_up')
                ElevatedButton(
                  onPressed: _isUpdating ? null : () => _handleStatusUpdate('delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Deliver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.lato(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
