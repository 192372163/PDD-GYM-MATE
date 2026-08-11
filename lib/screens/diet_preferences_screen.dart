import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class DietPreferencesScreen extends StatefulWidget {
  const DietPreferencesScreen({super.key});

  @override
  State<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends State<DietPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController(text: 'India');
  final _medicalController = TextEditingController();

  String? _selectedFoodPref;
  String? _selectedActivity;
  String? _selectedBudget;

  bool _isLoading = false;

  final List<String> _foodPrefs = ['Vegetarian', 'Vegan', 'Non-Vegetarian', 'Pescatarian'];
  final List<String> _activities = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'];
  final List<String> _budgets = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _countryController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFoodPref == null || _selectedActivity == null || _selectedBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all dropdown options'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = AuthService().currentUser!.uid;

      final fieldsToUpdate = {
        'foodPreference': _selectedFoodPref,
        'dailyActivity': _selectedActivity,
        'country': _countryController.text.trim(),
        'budget': _selectedBudget,
        'medicalConditions': _medicalController.text.isNotEmpty
            ? _medicalController.text.split(',').map((e) => e.trim()).toList()
            : [],
      };

      await FirestoreService().updateUserProfile(uid, fieldsToUpdate);

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown(String label, IconData icon, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF06B6D4)),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool optional = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF06B6D4)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: optional ? null : (val) {
        if (val == null || val.trim().isEmpty) return 'This field is required';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Diet Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tailor Your Nutrition',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'To generate an accurate AI diet plan, we need a few more details to customize meals to your lifestyle.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 32),

                _buildDropdown(
                  'Food Preference',
                  Icons.restaurant,
                  _selectedFoodPref,
                  _foodPrefs,
                  (val) => setState(() => _selectedFoodPref = val),
                ),
                const SizedBox(height: 20),

                _buildDropdown(
                  'Daily Activity Level',
                  Icons.directions_run,
                  _selectedActivity,
                  _activities,
                  (val) => setState(() => _selectedActivity = val),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  'Country / Cuisine Preference',
                  Icons.public,
                  _countryController,
                ),
                const SizedBox(height: 20),

                _buildDropdown(
                  'Budget',
                  Icons.attach_money,
                  _selectedBudget,
                  _budgets,
                  (val) => setState(() => _selectedBudget = val),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  'Medical Conditions (Optional)',
                  Icons.medical_services,
                  _medicalController,
                  optional: true,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'E.g. Diabetes, Hypertension (comma separated)',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save & Generate Plan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
