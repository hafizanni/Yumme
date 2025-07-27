import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yumme/authentication/database/DatabaseHelper.dart';
import 'package:yumme/authentication/database/AuthenDataHelper.dart';
import 'package:yumme/authentication/database/database.dart';
import 'package:yumme/authentication/login_screen.dart';
import 'package:yumme/admin/Admin_Feedback_Page.dart';
import 'dart:async';
import 'dart:math';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await DatabaseHelper().getUnreadSupportMessageCount();
    setState(() {
      _unreadCount = count;
    });
  }

  void _navigateToFeaturePage(String feature) {
    Widget page;
    switch (feature) {
      case 'User Accounts':
        page = const UserAccountsPage();
        break;
      case 'App Performance':
        page = const AppPerformancePage();
        break;
      case 'Feedback':
        page = const AdminFeedbackPage();
        break;
      case 'Support':
        page = const SupportPage();
        break;
      default:
        page = const Scaffold(
          body: Center(child: Text('Unknown Feature')),
        );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _loadUnreadCount()); // Refresh unread count when returning
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('d MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF6C63FF),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 100,
                    color: Color(0xFF0DAE96),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome, Admin!',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage and monitor the app below.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Last Update: $formattedDate',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    icon: Icons.person,
                    title: 'User Accounts',
                    color: Colors.tealAccent,
                    badgeCount: 0,
                    onTap: () => _navigateToFeaturePage('User Accounts'),
                  ),
                  _buildAdminCard(
                    icon: Icons.bar_chart,
                    title: 'App Performance',
                    color: Colors.lightBlueAccent,
                    badgeCount: 0,
                    onTap: () => _navigateToFeaturePage('App Performance'),
                  ),
                  _buildAdminCard(
                    icon: Icons.feedback,
                    title: 'Feedback',
                    color: Colors.orangeAccent,
                    badgeCount: 0,
                    onTap: () => _navigateToFeaturePage('Feedback'),
                  ),
                  _buildAdminCard(
                    icon: Icons.support_agent,
                    title: 'Support',
                    color: Colors.pinkAccent,
                    badgeCount: _unreadCount,
                    onTap: () => _navigateToFeaturePage('Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.8),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Page to list, edit, delete, block/unblock user accounts.
class UserAccountsPage extends StatefulWidget {
  const UserAccountsPage({Key? key}) : super(key: key);

  @override
  State<UserAccountsPage> createState() => _UserAccountsPageState();
}

class _UserAccountsPageState extends State<UserAccountsPage> {
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = AuthenDataHelper.instance;
    final allUsers = await db.getAllUsers();
    setState(() {
      _users = allUsers;
    });
  }

  Future<void> _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
            'Are you sure you want to delete this user? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthenDataHelper.instance.deleteUser(userId);
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted.')),
      );
    }
  }

  Future<void> _toggleBlockUser(int userId, int currentBlockedValue) async {
    final newBlockedValue = (currentBlockedValue == 1) ? 0 : 1;
    await AuthenDataHelper.instance
        .updateUserBlockStatus(userId, newBlockedValue);
    await _loadUsers();
    final verb = newBlockedValue == 1 ? 'blocked' : 'unblocked';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User $verb.')),
    );
  }

  void _editUser(int userId, String currentUsername, String currentEmail) async {
    final usernameController = TextEditingController(text: currentUsername);
    final emailController = TextEditingController(text: currentEmail);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await AuthenDataHelper.instance.updateUser(userId, {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
      });
      await _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _users.isEmpty
            ? const Center(
                child: Text(
                  'No users found.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final int id = user['id'] as int;
                  final String username = user['username'] as String;
                  final String email = user['email'] as String;
                  final int isBlocked = user['isBlocked'] as int;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              if (isBlocked == 1) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Blocked',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.redAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.blueGrey),
                              tooltip: 'Edit user',
                              onPressed: () =>
                                  _editUser(id, username, email),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Delete user',
                              onPressed: () => _deleteUser(id),
                            ),
                            IconButton(
                              icon: Icon(
                                isBlocked == 1
                                    ? Icons.lock_open
                                    : Icons.block,
                                color: isBlocked == 1
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              tooltip: isBlocked == 1 ? 'Unblock' : 'Block',
                              onPressed: () => _toggleBlockUser(id, isBlocked),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Simple App Performance page (static/demo data)

class AppPerformancePage extends StatefulWidget {
  const AppPerformancePage({Key? key}) : super(key: key);

  @override
  State<AppPerformancePage> createState() => _AppPerformancePageState();
}

class _AppPerformancePageState extends State<AppPerformancePage> {
  bool _isLoading = true;
  late DateTime _lastUpdated;

  // These fields will hold our dynamic data.
  int _dailyActiveUsers = 0;
  int _monthlyVisits = 0;
  double _avgSessionTime = 0;
  int _crashReports = 0;
  double _slowestPageLoad = 0;
  int _apiAvgResponse = 0;
  int _memoryUsage = 0;
  int _feedbackCount = 0;

  // For the weekly bar chart:
  List<int> _weeklyActiveUsers = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _lastUpdated = DateTime.now();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate an asynchronous network/database call:
    await Future.delayed(const Duration(seconds: 1));

    // Generate random data for demonstration.
    // Replace this block with your real API/database fetch logic.
    final random = Random();
    _dailyActiveUsers = 100 + random.nextInt(50);
    _monthlyVisits = 3000 + random.nextInt(1000);
    _avgSessionTime = (3 + random.nextDouble() * 4).clamp(1.0, 10.0);
    _crashReports = random.nextInt(5);
    _slowestPageLoad = (1 + random.nextDouble() * 2).clamp(0.5, 3.0);
    _apiAvgResponse = 200 + random.nextInt(300);
    _memoryUsage = 100 + random.nextInt(100);
    _feedbackCount = 20 + random.nextInt(50);

    // Generate a new 7-day series for weekly active users:
    _weeklyActiveUsers = List.generate(7, (_) => 80 + random.nextInt(80));

    _lastUpdated = DateTime.now();

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Days of the week labels:
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find max so we can scale bar heights:
    final maxValue = _weeklyActiveUsers.fold<int>(0, (prev, e) => max(prev, e));
    final chartHeight = 120.0; // Max height in pixels for the tallest bar.

    return SizedBox(
      height: chartHeight + 30, // extra space for labels
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final value = _weeklyActiveUsers[i];
          final barRatio = maxValue == 0 ? 0.0 : (value / maxValue);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // AnimatedContainer for a smooth height transition.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  height: barRatio * chartHeight,
                  width: 18,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(days[i], style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    // e.g. "2025-06-02 17:45:03"
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Performance')),
      body: RefreshIndicator(
        onRefresh: _fetchMetrics,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              // Show a spinner while fetching data
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Key Metrics',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          _buildMetricRow(
                            '📊 Daily Active Users',
                            _dailyActiveUsers.toString(),
                          ),
                          _buildMetricRow(
                            '📈 Monthly Visits',
                            _monthlyVisits.toString(),
                          ),
                          _buildMetricRow(
                            '⏱ Avg. Session Time',
                            '${_avgSessionTime.toStringAsFixed(1)} mins',
                          ),
                          _buildMetricRow(
                            '💥 Crash Reports',
                            _crashReports.toString(),
                          ),
                          _buildMetricRow(
                            '🕒 Slowest Page Load',
                            '${_slowestPageLoad.toStringAsFixed(2)}s',
                          ),
                          _buildMetricRow(
                            '🔗 API Avg. Response',
                            '${_apiAvgResponse}ms',
                          ),
                          _buildMetricRow(
                            '🧠 Memory Usage',
                            '${_memoryUsage}MB',
                          ),
                          _buildMetricRow(
                            '📝 Feedback Count',
                            _feedbackCount.toString(),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            '📅 Weekly Active Users',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildBarChart(),

                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                '🔄 Live Data',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _fetchMetrics,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated: ${_formatTimestamp(_lastUpdated)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}


/// Support messages page
class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    return await DatabaseHelper().getAllSupportMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Messages')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No support messages.'));
          }
          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isRead = (msg['is_read'] as int) == 1;
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: Text(msg['message'] ?? ''),
                  subtitle: Text(
                    'From: ${msg['user_email'] ?? ''}\n${DateFormat.yMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] ?? 0))}',
                  ),
                  trailing: isRead
                      ? const Icon(Icons.mark_email_read, color: Colors.green)
                      : const Icon(Icons.mark_email_unread,
                          color: Colors.red),
                  onTap: () async {
                    await DatabaseHelper()
                        .markSupportMessageRead(msg['id'] as int);
                    (context as Element).markNeedsBuild();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// In DatabaseHelper (database.dart), ensure you have:
 
 Future<int> getUnreadSupportMessageCount() async {
   final db = await database;
   final result = await db.rawQuery(
       'SELECT COUNT(*) as count FROM support_messages WHERE is_read = 0');
   return Sqflite.firstIntValue(result) ?? 0;
 }
 
 Future<List<Map<String, dynamic>>> getAllSupportMessages() async {
   final db = await database;
   return await db.query('support_messages', orderBy: 'timestamp DESC');
 }
 
 Future<void> markSupportMessageRead(int id) async {
   final db = await database;
   await db.update('support_messages', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
 }
