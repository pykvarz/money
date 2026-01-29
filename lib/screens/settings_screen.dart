import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/weekly_limit.dart';
import '../models/fixed_expense.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/weekly_limit_card.dart';
import '../widgets/fixed_expense_dialog.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'categories_screen.dart';
import 'templates_screen.dart';
import 'limits_screen.dart';
import 'fixed_expenses_screen.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import 'package:hive/hive.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          final budget = budgetProvider.currentBudget;
          final expenseProvider = context.watch<ExpenseProvider>();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSectionHeader('FINANCIAL GOALS'),
              _buildGoalCard(
                context,
                title: 'Target Balance',
                amount: budget?.targetRemainingBalance,
                amountColor: const Color(0xFF6366F1), // Indigo
                icon: Icons.flag,
                iconColor: const Color(0xFF6366F1),
                iconBgColor: const Color(0xFFE0E7FF),
                onTap: () => _showSetTargetDialog(context, budgetProvider),
                secondaryLabel: 'Safe Daily Budget',
                secondaryAmount: budgetProvider.getSmartSafeDailyBudget(expenseProvider),
                secondaryColor: const Color(0xFF10B981), // Green
                buttonText: 'Change Goal',
              ),
              const SizedBox(height: 16),
              _buildGoalCard(
                context,
                title: 'Starting Balance',
                amount: budget?.initialBalance,
                amountColor: const Color(0xFF3B82F6), // Blue
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFDBEAFE),
                onTap: () => _showSetInitialBalanceDialog(context, budgetProvider),
                secondaryLabel: 'Balance at start of month:',
                secondaryAmount: budget?.initialBalance ?? 0, // Show same amount as secondary desc
                secondaryColor: const Color(0xFF3B82F6),
                buttonText: 'Change Starting Balance',
                isSimple: true, // Special layout for starting balance if needed, or reuse
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('CATEGORIES & TEMPLATES'),
              _buildSettingsGroup(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.category,
                    iconColor: const Color(0xFFA855F7), // Purple
                    iconBgColor: const Color(0xFFF3E8FF),
                    title: 'Categories',
                    subtitle: 'Manage income & expense categories',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.bookmark,
                    iconColor: const Color(0xFF0EA5E9), // Light Blue
                    iconBgColor: const Color(0xFFE0F2FE),
                    title: 'Templates',
                    subtitle: 'Manage transaction templates',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.speed,
                    iconColor: const Color(0xFFF97316), // Orange
                    iconBgColor: const Color(0xFFFFEDD5),
                    title: 'Spending Limits',
                    subtitle: 'Weekly and monthly budget limits',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LimitsScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.receipt_long,
                    iconColor: const Color(0xFFEF4444), // Red
                    iconBgColor: const Color(0xFFFEE2E2),
                    title: 'Regular Expenses',
                    subtitle: 'Rent, subscriptions, fixed bills',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FixedExpensesScreen()),
                    ),
                  ),
                  _buildDivider(),
                   _buildSettingsTile(
                    context,
                    icon: Icons.notifications_active, // AUTO PARSING
                    iconColor: const Color(0xFFD97706), // Amber
                    iconBgColor: const Color(0xFFFEF3C7),
                    title: 'Bank Notifications',
                    subtitle: 'Auto-parsing transactions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('SYSTEM'),
              _buildSettingsGroup(
                context,
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return _buildSettingsTile(
                        context,
                        icon: Icons.dark_mode,
                        iconColor: const Color(0xFF6366F1), // Indigo
                        iconBgColor: const Color(0xFFE0E7FF),
                        title: 'Appearance',
                        subtitle: themeProvider.themeName,
                        onTap: () => _showThemeDialog(context, themeProvider),
                      );
                    },
                  ),
                  // Notifications Sub-section (integrated directly or separate?)
                  // The mock shows Notifications as a header inside the card, then items.
                  // Let's implement it as expandable or just flat items.
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications,
                    iconColor: const Color(0xFFEAB308), // Yellow
                    iconBgColor: const Color(0xFFFEF9C3),
                    title: 'Notifications',
                    subtitle: 'Reminder schedules',
                    onTap: null, // Just a header-like item
                  ),
                   // Custom embedded items for times
                   Padding(
                     padding: const EdgeInsets.only(left: 60, right: 16, bottom: 8), // Indent to align with text
                     child: Column(
                       children: [
                         FutureBuilder<TimeOfDay>(
                            future: _getDailyReminderTime(),
                            builder: (context, snapshot) {
                              final time = snapshot.data ?? const TimeOfDay(hour: 21, minute: 0);
                              return _buildTimeRow(
                                context, 
                                'Daily Reminder', 
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                () => _pickDailyReminderTime(context)
                              );
                            }
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<TimeOfDay>(
                            future: _getWeeklyReminderTime(),
                            builder: (context, snapshot) {
                              final time = snapshot.data ?? const TimeOfDay(hour: 20, minute: 0);
                              return _buildTimeRow(
                                context, 
                                'Weekly Summary (Sun)', 
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                () => _pickWeeklyReminderTime(context)
                              );
                            }
                          ),
                       ],
                     ),
                   ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('DATA MANAGEMENT'),
               _buildSettingsGroup(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.cloud_download,
                    iconColor: const Color(0xFF10B981), // Teal/Green
                    iconBgColor: const Color(0xFFD1FAE5),
                    title: 'Backup',
                    subtitle: 'Save or restore your data',
                    onTap: null, // Just header
                  ),
                   _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.upload_file,
                    iconColor: const Color(0xFF4B5563), // Grey
                    iconBgColor: const Color(0xFFF3F4F6),
                    title: 'Export Data',
                    subtitle: 'Save to internal file',
                    onTap: () async => await DataService().exportData(context),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.table_chart,
                    iconColor: const Color(0xFF10B981), // Green
                    iconBgColor: const Color(0xFFD1FAE5),
                    title: 'Export to Excel (CSV)',
                    subtitle: 'Download transaction history',
                    onTap: () async => await DataService().exportTransactionsToCsv(context),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    context,
                    icon: Icons.refresh,
                    iconColor: const Color(0xFFEF4444), // Red
                    iconBgColor: const Color(0xFFFEE2E2),
                    title: 'Reset Categories',
                    subtitle: 'Restore default icons and colors',
                    onTap: () => _resetDefaultCategories(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              // Version Info
              Center(
                child: Text(
                  'ExpenseBook v1.0.0',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // UI Helper Methods

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color(0xFF64748B), // Slate 500
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required String title,
    required double? amount,
    required Color amountColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor, // Light shade of icon color
    required VoidCallback onTap,
    required String secondaryLabel,
    required double secondaryAmount,
    required Color secondaryColor,
    required String buttonText,
    bool isSimple = false,
  }) {
    // For Starting Balance, we might want a simpler layout based on the design
    // But adapting "Financial Goals" style for both is cleaner.
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSimple ? 'Balance at start of month:' : 'Current Goal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
                  ),
                ),
                Text(
                  amount != null ? CurrencyFormatter.formatKZT(amount) : 'Not Set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            
            if (!isSimple) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    secondaryLabel,
                    style: TextStyle(
                      fontSize: 14,
                       color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatKZTWithDecimals(secondaryAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(buttonText),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24), // Matches card radius
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64, // Align with text start (16 padding + 42 icon width + 16 gap)
      endIndent: 0,
      color: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildTimeRow(BuildContext context, String title, String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 8),
         child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 14, color: Colors.blue),
              ],
            ),
          ],
             ),
       ),
    );
  }

  Future<void> _showSetTargetDialog(
    BuildContext context,
    BudgetProvider provider,
  ) async {
    final controller = TextEditingController(
      text: provider.currentBudget?.targetRemainingBalance?.toString() ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить целевой баланс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите сумму, которую хотите сохранить к концу месяца',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Целевой остаток',
                suffixText: 'KZT',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.updateTargetBalance(result);
    }

    controller.dispose();
  }

  Future<void> _showSetInitialBalanceDialog(
    BuildContext context,
    BudgetProvider provider,
  ) async {
    final controller = TextEditingController(
      text: provider.currentBudget?.initialBalance.toString() ?? '0',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Установить начальный баланс'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите баланс на начало текущего месяца',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Начальный баланс',
                suffixText: 'KZT',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.updateInitialBalance(result);
    }

    controller.dispose();
  }

  Future<void> _showWeeklyLimitDialog(
    BuildContext context,
    BudgetProvider budgetProvider, {
    WeeklyLimit? existingLimit,
  }) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final result = await showDialog<WeeklyLimit>(
      context: context,
      builder: (context) => WeeklyLimitDialog(
        categories: expenseProvider.categories,
        existingLimit: existingLimit,
      ),
    );

    if (result != null) {
      await budgetProvider.setWeeklyLimit(result, expenseProvider);
    }
  }

  Future<void> _deleteWeeklyLimit(
    BuildContext context,
    BudgetProvider provider,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить лимит?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final expenseProvider = context.read<ExpenseProvider>();
      await provider.deleteWeeklyLimit(id, expenseProvider);
    }
  }
  Future<TimeOfDay> _getDailyReminderTime() async {
    final box = await Hive.openBox('settings');
    final hour = box.get('daily_reminder_hour', defaultValue: 21);
    final minute = box.get('daily_reminder_minute', defaultValue: 0);
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<TimeOfDay> _getWeeklyReminderTime() async {
    final box = await Hive.openBox('settings');
    final hour = box.get('weekly_reminder_hour', defaultValue: 20);
    final minute = box.get('weekly_reminder_minute', defaultValue: 0);
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickDailyReminderTime(BuildContext context) async {
    final initialTime = await _getDailyReminderTime();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final box = await Hive.openBox('settings');
      await box.put('daily_reminder_hour', picked.hour);
      await box.put('daily_reminder_minute', picked.minute);
      
      await NotificationService().scheduleDailyReminder(picked);
      
      // Force rebuild to show new time
      setState(() {});
    }
  }

  Future<void> _pickWeeklyReminderTime(BuildContext context) async {
    final initialTime = await _getWeeklyReminderTime();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final box = await Hive.openBox('settings');
      await box.put('weekly_reminder_hour', picked.hour);
      await box.put('weekly_reminder_minute', picked.minute);
      
      // Reschedule, keeping the content dynamic (it will be updated next time budget status is checked, 
      // or we can explicitly trigger a refresh here if we want immediate content update, 
      // but scheduling with default body is fine for now as it will just confirm the time).
      await NotificationService().scheduleWeeklySummary(picked);
      
      // Force rebuild
      (context as Element).markNeedsBuild();
    }
  }

  Future<void> _showThemeDialog(BuildContext context, ThemeProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите тему'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Системная'),
            value: ThemeMode.system,
            groupValue: provider.themeMode,
            onChanged: (value) {
              provider.setTheme(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Светлая'),
            value: ThemeMode.light,
            groupValue: provider.themeMode,
            onChanged: (value) {
              provider.setTheme(value!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Темная'),
            value: ThemeMode.dark,
            groupValue: provider.themeMode,
            onChanged: (value) {
              provider.setTheme(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resetDefaultCategories(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить категории?'),
        content: const Text(
          'Это восстановит все стандартные категории (Food, Transport и т.д.) '
          'к оригинальным иконкам и цветам.\n\n'
          'Пользовательские категории не пострадают.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().resetDefaultCategories();
        
        // Reload categories in providers
        if (context.mounted) {
          await context.read<ExpenseProvider>().loadCategories();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Категории успешно сброшены'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


}


