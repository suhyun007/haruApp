import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _calorieGoalController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _targetWeightController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  void _showEditDialog(UserModel user) {
    _nameController.text = user.name;
    _targetWeightController.text = user.targetWeight.toString();
    _calorieGoalController.text = user.dailyCalorieGoal.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 수정'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력하세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _targetWeightController,
                  decoration: const InputDecoration(labelText: '목표 체중 (kg)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '목표 체중을 입력하세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _calorieGoalController,
                  decoration: const InputDecoration(labelText: '하루 칼로리 목표 (kcal)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '칼로리 목표를 입력하세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => _submitProfile(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE6C767),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _submitProfile(UserModel user) {
    if (_formKey.currentState!.validate()) {
      final updatedUser = UserModel(
        id: user.id,
        name: _nameController.text,
        targetWeight: double.parse(_targetWeightController.text),
        currentWeight: user.currentWeight,
        dailyCalorieGoal: int.parse(_calorieGoalController.text),
      );

      Provider.of<UserProvider>(context, listen: false).updateUser(updatedUser);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFE6C767),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.monitor_weight, color: Color(0xFFE6C767)),
                      title: const Text('현재 체중'),
                      trailing: Text(
                        '${user.currentWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.flag, color: Color(0xFFD4AF37)),
                      title: const Text('목표 체중'),
                      trailing: Text(
                        '${user.targetWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.local_fire_department, color: Colors.orange),
                      title: const Text('하루 칼로리 목표'),
                      trailing: Text(
                        '${user.dailyCalorieGoal} kcal',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showEditDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6C767),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '프로필 수정',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

