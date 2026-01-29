import 'package:flutter/material.dart';
import '../utils/custom_toast.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/category_dialog.dart';
import '../services/widget_service.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Категории'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Расходы'),
              Tab(text: 'Доходы'),
            ],
          ),
        ),
        body: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final expenseCategories = provider.categories
                .where((c) => c.type == CategoryType.expense)
                .toList();
            final incomeCategories = provider.categories
                .where((c) => c.type == CategoryType.income)
                .toList();

            return TabBarView(
              children: [
                _buildCategoryList(context, provider, expenseCategories),
                _buildCategoryList(context, provider, incomeCategories),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    ExpenseProvider provider,
    List<Category> categories,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Нет категорий',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Dismissible(
          key: Key(category.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, category),
          onDismissed: (_) {
            provider.deleteCategory(category.id);
            CustomToast.show(context, 'Категория "${category.name}" удалена');
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.2),
              child: Icon(category.icon, color: category.color),
            ),
            title: Text(category.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () => _openCategoryDialog(context, category: category),
                  tooltip: 'Редактировать',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'widget') {
                      _setAsWidget(context, category);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'widget',
                      child: Row(
                        children: [
                          Icon(Icons.widgets, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Создать виджет'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _openCategoryDialog(context, category: category),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Category category) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить категорию?'),
            content: Text(
              'Вы уверены, что хотите удалить категорию "${category.name}"? '
              'Все транзакции по этой категории останутся, но будут помечены как "Неизвестно".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openCategoryDialog(BuildContext context, {Category? category}) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        initialType: category?.type ?? CategoryType.expense,
      ),
    );

    if (result != null) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (category != null) {
        // Update
        await provider.updateCategory(result);
      } else {
        // Create
        await provider.addCategory(result);
      }
    }
  }
  Future<void> _setAsWidget(BuildContext context, Category category) async {
    await WidgetService.updateCategoryWidget(category, context);
  }
}
