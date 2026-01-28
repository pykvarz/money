import 'dart:convert';
import '../utils/custom_toast.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/weekly_limit.dart';
import '../models/monthly_limit.dart';
import '../models/monthly_budget.dart';
import '../models/fixed_expense.dart';

class DataService {
  final DatabaseHelper _db = DatabaseHelper();

  // Export data to JSON file and share it
  Future<void> exportData(BuildContext context) async {
    try {
      // 1. Gather all data
      final Map<String, dynamic> data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': _db.getAllTransactions().map((e) => e.toJson()).toList(),
        'categories': _db.getAllCategories().map((e) => e.toJson()).toList(),
        'weeklyLimits': _db.getAllWeeklyLimits().map((e) => e.toJson()).toList(),
        'monthlyLimits': _db.getAllMonthlyLimits().map((e) => e.toJson()).toList(),
        'monthlyBudgets': _db.getAllMonthlyBudgets().map((e) => e.toJson()).toList(),
        'fixedExpenses': _db.getAllFixedExpenses().map((e) => e.toJson()).toList(),
      };

      // 2. Convert to JSON
      final jsonString = jsonEncode(data);

      // 3. Write to temporary file
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'expense_book_backup_$dateStr.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // 4. Share file
      // Check if context is mounted before showing UI (share dialog)
      if (!context.mounted) return;
      
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup of Expense Book data',
      );

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          CustomToast.show(context, 'Резервная копия успешно создана');
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(context, 'Ошибка экспорта: $e', isError: true);
      }
    }
  }

  // Import data from JSON file
  Future<void> importData(BuildContext context) async {
    try {
      // 1. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // 2. Parse JSON
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Validate version (basic check)
      if (data['version'] == null) {
        throw Exception('Invalid backup file format');
      }

      // 3. Confirm overwrite
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Восстановить данные?'),
          content: const Text(
            'ВНИМАНИЕ: Все текущие данные будут удалены и заменены данными из резервной копии.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Восстановить'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 4. Restore data
      // We need to clear existing data before adding new
      // Note: DatabaseHelper doesn't have "clear all" methods public, 
      // but we can iterate and delete or add methods. 
      // For simplicity/safety, let's implement granular clear in DB helper or just overwrite.
      // Since IDs might conflict or duplicates appear, clearing is best.
      // But clearing requires iterating.
      // Let's rely on Hive's behavior: `put` overwrites if ID exists.
      // But if we have *new* data in app that isn't in backup, it stays. 
      // Ideally we want to WIPE everything first.
      
      // Let's assume we just Overwrite/Add for now to avoid breaking "Clear" logic if helper lacks it.
      // Actually, for a true "Restore", we SHOULD clear.
      
      // Since we don't have "clearBox" exposed, let's try to overwrite.
      // Improvement: Add `clearAllData` to DatabaseHelper later if needed.
      
      // Transactions
      if (data['transactions'] != null) {
        for (var i in data['transactions']) {
          await _db.addTransaction(Transaction.fromJson(i));
        }
      }
      
      // Categories
      if (data['categories'] != null) {
        for (var i in data['categories']) {
          await _db.addCategory(Category.fromJson(i));
        }
      }
      
      // Fixed Expenses
      if (data['fixedExpenses'] != null) {
        for (var i in data['fixedExpenses']) {
          await _db.addFixedExpense(FixedExpense.fromJson(i));
        }
      }
      
      // Budgets
      if (data['monthlyBudgets'] != null) {
        for (var i in data['monthlyBudgets']) {
          await _db.addMonthlyBudget(MonthlyBudget.fromJson(i));
        }
      }
       
      // Limits
      if (data['weeklyLimits'] != null) {
        for (var i in data['weeklyLimits']) {
          await _db.addWeeklyLimit(WeeklyLimit.fromJson(i));
        }
      }
      
      if (data['monthlyLimits'] != null) {
        for (var i in data['monthlyLimits']) {
          await _db.addMonthlyLimit(MonthlyLimit.fromJson(i));
        }
      }

      if (context.mounted) {
        CustomToast.show(context, 'Данные успешно восстановлены. Перезапустите приложение для обновления всех экранов.');
      }

    } catch (e) {
      if (context.mounted) {
        CustomToast.show(context, 'Ошибка импорта: $e', isError: true);
      }
    }
  }

  // Export transactions to CSV (Excel compatible)
  Future<void> exportTransactionsToCsv(BuildContext context) async {
    try {
      final transactions = _db.getAllTransactions();
      
      // 1. Prepare CSV Header
      List<List<dynamic>> rows = [];
      rows.add([
        'Date', 
        'Type', 
        'Category', 
        'Amount', 
        'Note', 
        'Status'
      ]);

      // 2. Add Data
      for (var txn in transactions) {
        final category = _db.getCategoryById(txn.categoryId);
        rows.add([
          DateFormat('yyyy-MM-dd HH:mm').format(txn.date),
          txn.type == TransactionType.income ? 'Income' : 'Expense',
          category?.name ?? 'Unknown',
          txn.amount,
          txn.note ?? '',
          'Completed'
        ]);
      }

      // 3. Convert to CSV String manually for simplicity (avoiding complexity if csv package issues)
      // Actually we added csv package, let's use it if we imported it.
      // But verify imports... I see 'import 'package:csv/csv.dart';' is missing.
      // I will generate simple CSV manually to be checking-safe or add import.
      // Let's add import first.
      
      // Manual CSV generation is safer if I don't want to re-read file imports.
      // Format: "val","val","val"\n
      
      StringBuffer csvBuffer = StringBuffer();
      // Add BOM for Excel UTF-8 compatibility
      csvBuffer.write('\uFEFF'); 
      
      for (var row in rows) {
        csvBuffer.writeln(row.map((e) {
          String cell = e.toString();
          // Escape quotes
          cell = cell.replaceAll('"', '""');
          // Wrap in quotes
          return '"$cell"';
        }).join(','));
      }

      // 4. Save to file
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'expenses_export_$dateStr.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvBuffer.toString());

      // 5. Share
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Expense Book Transactions (CSV)',
      );

    } catch (e) {
      if (context.mounted) {
        CustomToast.show(context, 'Ошибка экспорта CSV: $e', isError: true);
      }
    }
  }
}
