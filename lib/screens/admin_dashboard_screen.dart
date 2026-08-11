import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'System Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '1,245', Icons.group)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Active Today', '342', Icons.directions_run)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Workouts Logged', '8,901', Icons.fitness_center)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Meals Logged', '12,430', Icons.restaurant)),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.blue),
            title: const Text('Exercise Database'),
            subtitle: const Text('Add, edit, or remove exercises from the global list'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Exercise DB...')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fastfood, color: Colors.orange),
            title: const Text('Food Database'),
            subtitle: const Text('Manage nutrition facts and ingredients'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Food DB...')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.green),
            title: const Text('User Management'),
            subtitle: const Text('View and moderate user accounts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to User Management...')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade700),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
