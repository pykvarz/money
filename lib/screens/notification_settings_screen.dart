import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/notification_rule.dart';
import '../services/database_helper.dart';
import '../services/notification_parser_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _db = DatabaseHelper();
  
  bool _eurasianEnabled = false;
  bool _kaspiEnabled = false;
  List<NotificationRule> _rules = [];
  List<Category> _categories = [];
  List<String> _customBanks = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final eurasian = await NotificationParserService.isBankEnabled('kz.eurasianbank.mobile');
    final kaspi = await NotificationParserService.isBankEnabled('kz.kaspi.mobile');
    final rules = _db.getAllNotificationRules();
    final categories = _db.getCategoriesByType(CategoryType.expense);
    final customBanks = await NotificationParserService.getCustomBanks();

    setState(() {
      _eurasianEnabled = eurasian;
      _kaspiEnabled = kaspi;
      _rules = rules;
      _categories = categories;
      _customBanks = customBanks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Автопарсинг уведомлений'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPermissionCard(),
          const SizedBox(height: 16),
          _buildBankSelectionCard(),
          const SizedBox(height: 16),
          _buildCustomBanksCard(),
          const SizedBox(height: 16),
          _buildRulesCard(),
          const SizedBox(height: 16),
          _buildDebugPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRuleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доступ к уведомлениям',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Для автоматического создания транзакций требуется доступ к уведомлениям'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                NotificationParserService.openNotificationSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Открыть настройки'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Банки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Eurasian Bank'),
              subtitle: const Text('kz.eurasianbank.mobile'),
              value: _eurasianEnabled,
              onChanged: (value) async {
                await NotificationParserService.setBankEnabled('kz.eurasianbank.mobile', value ?? false);
                await _loadSettings();
              },
            ),
            CheckboxListTile(
              title: const Text('Kaspi Bank'),
              subtitle: const Text('kz.kaspi.mobile'),
              value: _kaspiEnabled,
              onChanged: (value) async {
                await NotificationParserService.setBankEnabled('kz.kaspi.mobile', value ?? false);
                await _loadSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBanksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Пользовательские банки',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showAddBankDialog,
                  tooltip: 'Добавить банк',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_customBanks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Нет пользовательских банков', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._customBanks.map((packageName) => _buildCustomBankItem(packageName)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBankItem(String packageName) {
    return FutureBuilder<bool>(
      future: NotificationParserService.isBankEnabled(packageName),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        
        return CheckboxListTile(
          title: Text(packageName),
          subtitle: const Text('Пользовательский банк'),
          value: enabled,
          onChanged: (value) async {
            await NotificationParserService.setBankEnabled(packageName, value ?? false);
            await _loadSettings();
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить банк?'),
                  content: Text('Удалить "$packageName"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await NotificationParserService.removeCustomBank(packageName);
                await _loadSettings();
              }
            },
          ),
        );
      },
    );
  }

  void _showAddBankDialog() {
    String bankName = '';
    String packageName = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить банк'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Название банка',
                hintText: 'Например: Halyk Bank',
              ),
              onChanged: (value) => bankName = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Package Name',
                hintText: 'Например: kz.halykbank.mobile',
              ),
              onChanged: (value) => packageName = value,
            ),
            const SizedBox(height: 8),
            const Text(
              'Чтобы узнать package name, посмотрите логи в Debug Panel',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (packageName.isNotEmpty) {
                await NotificationParserService.addCustomBank(packageName);
                Navigator.pop(context);
                await _loadSettings();
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Правила маппинга',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_rules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Нет правил'),
              )
            else
              ..._rules.map((rule) => _buildRuleItem(rule)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(NotificationRule rule) {
    final category = _db.getCategoryById(rule.categoryId);
    
    return ListTile(
      leading: Icon(
        category?.icon ?? Icons.help_outline,
        color: category?.color,
      ),
      title: Text(rule.keyword),
      subtitle: Text(category?.name ?? 'Unknown'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await _db.deleteNotificationRule(rule.id);
          await _loadSettings();
        },
      ),
    );
  }

  void _showAddRuleDialog() {
    String keyword = '';
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить правило'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Ключевое слово (uppercase)',
                  hintText: 'SUPERMARKET',
                ),
                onChanged: (value) {
                  keyword = value.toUpperCase();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Категория',
                ),
                value: selectedCategoryId,
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (keyword.isNotEmpty && selectedCategoryId != null) {
                  final rule = NotificationRule(
                    keyword: keyword,
                    categoryId: selectedCategoryId!,
                    isActive: true,
                  );
                  await _db.addNotificationRule(rule);
                  Navigator.pop(context);
                  await _loadSettings();
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    final logs = _db.getRecentNotificationLogs(limit: 10);
    
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report, color: Colors.orange),
        title: const Text('Debug Panel'),
        subtitle: Text('${logs.length} недавних уведомлений'),
        children: [
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет логов. Уведомления появятся здесь после получения.'),
            )
          else
            ...logs.map((log) => _buildLogItem(log)).toList(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await _db.clearNotificationLogs();
                    await _loadSettings(); // Используем _loadSettings вместо setState
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Очистить логи'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await _loadSettings(); // Используем _loadSettings вместо setState
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(log) {
    final timestamp = '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}';
    final success = log.parseSuccess;
    
    return ExpansionTile(
      leading: Icon(
        success ? Icons.check_circle : Icons.error,
        color: success ? Colors.green : Colors.red,
        size: 20,
      ),
      title: Text(
        log.packageName,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        timestamp,
        style: const TextStyle(fontSize: 11),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📦 Package: ${log.packageName}', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text('📄 Text:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(log.text, style: const TextStyle(fontSize: 10)),
              const Divider(),
              if (log.parsedAmount != null && log.parsedKeyword != null) ...[
                Text('✅ Распознано:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text('  Сумма: ${log.parsedAmount} KZT', style: const TextStyle(fontSize: 11)),
                Text('  Ключевое слово: ${log.parsedKeyword}', style: const TextStyle(fontSize: 11)),
              ] else
                Text('❌ Не удалось распознать', style: const TextStyle(fontSize: 11, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
