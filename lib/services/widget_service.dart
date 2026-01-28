import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/category_widget_view.dart';
import '../utils/custom_toast.dart';

class WidgetService {
  static const String androidWidgetName = 'CategoryWidgetProvider';

  static Future<void> updateCategoryWidget(Category category, BuildContext context) async {
    try {
        final path = await HomeWidget.renderFlutterWidget(
          CategoryWidgetView(category: category),
          key: 'category_widget_preview', 
          logicalSize: const Size(160, 160),
        );
        
        if (path != null) {
            await HomeWidget.saveWidgetData<String>('filename', path);
            await HomeWidget.saveWidgetData<String>('categoryId', category.id);
            await HomeWidget.updateWidget(
                name: androidWidgetName,
            );
            if (context.mounted) {
                CustomToast.show(context, 'Виджет обновлен: ${category.name}');
            }
        }
    } catch (e) {
        debugPrint('Error updating widget: $e');
        if (context.mounted) {
            CustomToast.show(context, 'Ошибка обновления виджета');
        }
    }
  }
}
