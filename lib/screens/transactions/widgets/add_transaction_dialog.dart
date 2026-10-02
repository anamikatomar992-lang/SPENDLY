import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/date_helpers.dart';
import '../../categories/widgets/category_form_dialog.dart';

/// Modal bottom sheet for logging or editing a financial transaction
class AddTransactionDialog extends StatefulWidget {
  final TransactionType initialType;
  final TransactionModel? initialTransaction;

  const AddTransactionDialog({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    TransactionModel? initialTransaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTransactionDialog(
        initialType: initialTransaction != null ? initialTransaction.type : initialType,
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late CategoryModel _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;

  bool get isEditMode => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initTx = widget.initialTransaction;
    _type = initTx != null ? initTx.type : widget.initialType;

    _titleController = TextEditingController(text: initTx?.title ?? '');
    _amountController = TextEditingController(
      text: initTx != null ? initTx.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: initTx?.note ?? '');

    _selectedCategory = initTx != null
        ? initTx.category
        : (_type == TransactionType.income ? CategoryModel.salary : CategoryModel.food);

    _selectedPaymentMethod = initTx?.paymentMethod ?? PaymentMethod.card;
    _selectedDate = initTx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    final txProvider = context.read<TransactionProvider>();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (isEditMode) {
      final updated = widget.initialTransaction!.copyWith(
        title: title,
        amount: parsedAmount,
        date: _selectedDate,
        categoryId: _selectedCategory.id,
        type: _type,
        paymentMethod: _selectedPaymentMethod,
        note: note.isNotEmpty ? note : null,
      );
      await txProvider.updateTransaction(updated);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Updated "${updated.title}" successfully!'),
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        title: title,
        amount: parsedAmount,
        date: _selectedDate,
        categoryId: _selectedCategory.id,
        type: _type,
        paymentMethod: _selectedPaymentMethod,
        note: note.isNotEmpty ? note : null,
      );
      await txProvider.addTransaction(newTransaction);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_type.label} "${newTransaction.title}" saved!'),
          backgroundColor: _type == TransactionType.income
              ? AppColors.emeraldDark
              : AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Edit Transaction' : 'New Transaction',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (isEditMode)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseCoral),
                      tooltip: 'Delete Transaction',
                      onPressed: () async {
                        final txProvider = context.read<TransactionProvider>();
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final deletedTitle = widget.initialTransaction!.title;
                        final deletedTx = await txProvider.deleteTransaction(widget.initialTransaction!.id);
                        if (!mounted) return;
                        navigator.pop();
                        if (deletedTx != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Deleted "$deletedTitle"'),
                              duration: const Duration(seconds: 5),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: AppColors.emeraldGreen,
                                onPressed: () {
                                  txProvider.undoDelete();
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Type Selector (Segmented buttons)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeTab(
                        label: 'Expense',
                        isSelected: _type == TransactionType.expense,
                        activeColor: AppColors.expenseCoral,
                        onTap: () {
                          setState(() {
                            _type = TransactionType.expense;
                            if (_selectedCategory == CategoryModel.salary) {
                              _selectedCategory = CategoryModel.food;
                            }
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _TypeTab(
                        label: 'Income',
                        isSelected: _type == TransactionType.income,
                        activeColor: AppColors.emeraldDark,
                        onTap: () {
                          setState(() {
                            _type = TransactionType.income;
                            _selectedCategory = CategoryModel.salary;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Input
              Text(
                'Title',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _type == TransactionType.income ? 'e.g. Freelance Client Payment' : 'e.g. Dinner with Friends',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.textSecondary),
                ),
                validator: TransactionModel.validateTitle,
              ),
              const SizedBox(height: 14),

              // Amount Input
              Text(
                'Amount (\$)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 20, color: AppColors.textSecondary),
                ),
                validator: TransactionModel.validateAmount,
              ),
              const SizedBox(height: 14),

              // Category Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (_type == TransactionType.expense)
                    InkWell(
                      onTap: () async {
                        await CategoryFormDialog.show(context);
                      },
                      child: const Text(
                        '+ New Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _type == TransactionType.income
                      ? 1
                      : txProvider.allCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _type == TransactionType.income
                        ? CategoryModel.salary
                        : txProvider.allCategories[index];
                    final isSelected = _selectedCategory.id.toLowerCase() == cat.id.toLowerCase();

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color.withValues(alpha: 0.15) : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16, color: isSelected ? cat.color : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? cat.color : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Payment Method & Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<PaymentMethod>(
                          initialValue: _selectedPaymentMethod,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: PaymentMethod.values.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(method.label, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentMethod = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  DateHelpers.formatShort(_selectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Optional Note Input
              Text(
                'Note (Optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add context or personal remarks...',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == TransactionType.income
                        ? AppColors.emeraldDark
                        : AppColors.primaryNavy,
                    foregroundColor: AppColors.textInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditMode ? 'Update ${_type.label}' : 'Save ${_type.label}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
