import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/category_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_card.dart';

/// Modal dialog for adding or editing a custom financial category
class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? categoryToEdit;

  const CategoryFormDialog({
    super.key,
    this.categoryToEdit,
  });

  static Future<void> show(BuildContext context, {CategoryModel? categoryToEdit}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryFormDialog(categoryToEdit: categoryToEdit),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late IconData _selectedIcon;
  late Color _selectedColor;
  bool _isSubmitting = false;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _selectedIcon = widget.categoryToEdit?.icon ?? CategoryModel.availableIcons.first;
    _selectedColor = widget.categoryToEdit?.color ?? CategoryModel.availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();

      if (_isEditing) {
        final updated = widget.categoryToEdit!.copyWith(
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
        );
        await provider.updateCategory(updated);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Category "$name" updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final newCategory = CategoryModel(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
          isDefault: false,
        );
        await provider.addCategory(newCategory);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Custom category "$name" created successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save category: $e'),
          backgroundColor: AppColors.expenseCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Category' : 'Create Custom Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview Card
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                CustomCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: AppColors.surfaceMuted,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_selectedIcon, color: _selectedColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.trim().isEmpty
                                  ? 'Category Name'
                                  : _nameController.text.trim(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Custom Category',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Name Field
                Text(
                  'Category Name',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Subscriptions, Gaming, Coffee',
                    counterText: '',
                  ),
                  validator: (val) => CategoryModel.validateName(
                    val,
                    provider.allCategories,
                    widget.categoryToEdit?.id,
                  ),
                ),
                const SizedBox(height: 20),

                // Icon Picker
                Text(
                  'Choose Icon',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CategoryModel.availableIcons.map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = icon),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.18)
                              : AppColors.surfaceMuted,
                          border: Border.all(
                            color: isSelected ? _selectedColor : AppColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: isSelected ? _selectedColor : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Color Palette Picker
                Text(
                  'Choose Color',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: CategoryModel.availableColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSave,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isEditing ? 'Save Changes' : 'Create Category'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
