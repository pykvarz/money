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
import 'limits_screen.dart';
import 'fixed_expenses_screen.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import 'package:hive/hive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          final budget = budgetProvider.currentBudget;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Target Balance Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Целевой баланс',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (budget?.targetRemainingBalance != null)
                        Column(
                          key: const ValueKey('settings_target_set'),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Текущая цель:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatKZT(
                                    budget!.targetRemainingBalance!,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Безопасный дневной бюджет:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatKZTWithDecimals(
                                    budgetProvider.getSmartSafeDailyBudget(context.read<ExpenseProvider>()),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      else
                        Padding(
                          key: const ValueKey('settings_target_unset'),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Цель не установлена',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: () => _showSetTargetDialog(context, budgetProvider),
                        icon: const Icon(Icons.edit),
                        label: Text(
                          budget?.targetRemainingBalance != null
                              ? 'Изменить цель'
                              : 'Установить цель',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Initial Balance Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Начальный баланс',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Баланс на начало месяца:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatKZT(
                              budget?.initialBalance ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            _showSetInitialBalanceDialog(context, budgetProvider),
                        icon: const Icon(Icons.edit),
                        label: const Text('Изменить начальный баланс'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.category, color: Colors.purple),
                  title: const Text('Категории'),
                  subtitle: const Text('Управление категориями расходов и доходов'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Limits Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.speed, color: Colors.orange),
                  title: const Text('Лимиты трат'),
                  subtitle: const Text('Недельные и месячные лимиты'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LimitsScreen()),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fixed Expenses Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: Colors.red.shade700),
                  title: const Text('Обязательные расходы'),
                  subtitle: const Text('Регулярные платежи (аренда, подписки)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FixedExpensesScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),

              // Appearance Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return ListTile(
                      leading: const Icon(Icons.brightness_6, color: Colors.indigo),
                      title: const Text('Тема оформления'),
                      subtitle: Text(themeProvider.themeName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeDialog(context, themeProvider),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Notifications Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.amber),
                      title: const Text('Уведомления'),
                      subtitle: const Text('Настройка времени напоминаний'),
                    ),
                    const Divider(height: 1),
                    FutureBuilder<TimeOfDay>(
                      future: _getDailyReminderTime(),
                      builder: (context, snapshot) {
                        final time = snapshot.data ?? const TimeOfDay(hour: 21, minute: 0);
                        return ListTile(
                          title: const Text('Ежедневное напоминание'),
                          subtitle: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.edit, size: 20),
                          onTap: () => _pickDailyReminderTime(context),
                        );
                      }
                    ),
                    const Divider(height: 1),
                    FutureBuilder<TimeOfDay>(
                      future: _getWeeklyReminderTime(),
                      builder: (context, snapshot) {
                        final time = snapshot.data ?? const TimeOfDay(hour: 20, minute: 0);
                        return ListTile(
                          title: const Text('Итоги недели (Вс)'),
                          subtitle: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.edit, size: 20),
                          onTap: () => _pickWeeklyReminderTime(context),
                        );
                      }
                    ),


                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Backup & Reset Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_download, color: Colors.teal),
                      title: const Text('Резервная копия'),
                      subtitle: const Text('Сохранить или восстановить данные'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('Экспорт данных'),
                      subtitle: const Text('Сохранить в файл'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                         await DataService().exportData(context);
                      },
                    ),
                    const Divider(height: 1),

                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('Импорт данных'),
                      subtitle: const Text('Восстановить из файла'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                         await DataService().importData(context);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined, color: Colors.green),
                      title: const Text('Экспорт в Excel (CSV)'),
                      subtitle: const Text('Скачать историю транзакций'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                         await DataService().exportTransactionsToCsv(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Установите целевой баланс для активации умного планирования бюджета',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'ExpenseBook',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatMonthYear(
                        budget?.month ?? DateTime.now().month,
                        budget?.year ?? DateTime.now().year,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      await budgetProvider.setWeeklyLimit(result);
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
      await provider.deleteWeeklyLimit(id);
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


}


