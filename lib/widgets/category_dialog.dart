import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class CategoryDialog extends StatefulWidget {
  final Category? category; // null for new
  final CategoryType initialType;

  const CategoryDialog({
    super.key,
    this.category,
    this.initialType = CategoryType.expense,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uuid = const Uuid();

  late CategoryType _type;
  late int _selectedColorValue;
  late int _selectedIconCode;

  // Predefined colors
  final List<Color> _colors = [
    Colors.deepPurple, Colors.red, Colors.pink, Colors.purple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
  ];

  // Predefined icons
  final List<IconData> _icons = [
    Icons.restaurant, Icons.directions_car, Icons.lightbulb, Icons.movie,
    Icons.medical_services, Icons.shopping_bag, Icons.attach_money, Icons.home,
    Icons.school, Icons.fitness_center, Icons.pets, Icons.flight,
    Icons.videogame_asset, Icons.music_note, Icons.book, Icons.work,
    Icons.child_care, Icons.local_cafe, Icons.local_bar, Icons.local_pizza,
    Icons.local_grocery_store, Icons.local_gas_station, Icons.local_hospital, Icons.local_pharmacy,
    Icons.phone_android, Icons.computer, Icons.wifi, Icons.build,
    Icons.brush, Icons.camera_alt,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
      _selectedColorValue = widget.category!.colorValue;
      _selectedIconCode = widget.category!.iconCodePoint;
    } else {
      _type = widget.initialType;
      _selectedColorValue = Colors.deepPurple.value;
      _selectedIconCode = Icons.category.codePoint;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   Text(
                    isEdit ? 'Редактировать категорию' : 'Новая категория',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  if (!isEdit) // Only allow changing type for new categories
                    SegmentedButton<CategoryType>(
                      segments: const [
                        ButtonSegment(
                          value: CategoryType.expense,
                          label: Text('Расходы'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: CategoryType.income,
                          label: Text('Доходы'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<CategoryType> newSelection) {
                        setState(() {
                          _type = newSelection.first;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Цвет', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colors.map((color) {
                      final isSelected = color.value == _selectedColorValue;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorValue = color.value;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  Text('Иконка', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                   Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _icons.map((icon) {
                      final isSelected = icon.codePoint == _selectedIconCode;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIconCode = icon.codePoint;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColorValue).withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Color(_selectedColorValue), width: 2)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Color(_selectedColorValue) : Colors.grey,
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Сохранить' : 'Создать'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: widget.category?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIconCode,
        colorValue: _selectedColorValue,
        type: _type,
        isCustom: true,
      );

      Navigator.pop(context, category);
    }
  }
}
