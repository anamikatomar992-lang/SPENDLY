import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

/// Realistic sample seed data for first-launch and visual portfolio presentation
class SampleData {
  SampleData._();

  static List<TransactionModel> getInitialTransactions() {
    final now = DateTime.now();

    return [
      TransactionModel(
        id: 'tx_01',
        title: 'Tech Internship Stipend',
        amount: 3200.00,
        date: DateTime(now.year, now.month, 1, 10, 0),
        categoryId: CategoryModel.salary.id,
        type: TransactionType.income,
        paymentMethod: PaymentMethod.bankTransfer,
        note: 'Monthly development stipend',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_02',
        title: 'Freelance App Consulting',
        amount: 650.00,
        date: DateTime(now.year, now.month, 2, 14, 30),
        categoryId: CategoryModel.salary.id,
        type: TransactionType.income,
        paymentMethod: PaymentMethod.upi,
        note: 'Flutter UI consultation',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_03',
        title: 'Weekly Grocery Restock',
        amount: 86.40,
        date: DateTime(now.year, now.month, now.day, 16, 20),
        categoryId: CategoryModel.food.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        note: 'Fresh produce & pantry essentials',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_04',
        title: 'Metro Monthly Transit Pass',
        amount: 65.00,
        date: DateTime(now.year, now.month, now.day, 9, 15),
        categoryId: CategoryModel.transportation.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        note: 'Subway & bus card renewal',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_05',
        title: 'Mechanical Keyboard & Desk Mat',
        amount: 129.99,
        date: DateTime(now.year, now.month, (now.day - 1).clamp(1, 28), 19, 45),
        categoryId: CategoryModel.shopping.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        note: 'Workstation upgrade',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_06',
        title: 'Specialty Coffee & Pastry',
        amount: 8.75,
        date: DateTime(now.year, now.month, (now.day - 1).clamp(1, 28), 11, 10),
        categoryId: CategoryModel.food.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.upi,
        note: 'Brewed pour-over at Artisan Roasters',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_07',
        title: 'Algorithms & Data Structures Course',
        amount: 34.99,
        date: DateTime(now.year, now.month, (now.day - 2).clamp(1, 28), 15, 0),
        categoryId: CategoryModel.education.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        note: 'Advanced algorithm certification',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_08',
        title: 'Fiber Gigabit Internet Bill',
        amount: 54.00,
        date: DateTime(now.year, now.month, (now.day - 3).clamp(1, 28), 18, 30),
        categoryId: CategoryModel.bills.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.bankTransfer,
        note: 'Monthly home high-speed broadband',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_09',
        title: 'Pharmacy Vitamins & Supplements',
        amount: 28.50,
        date: DateTime(now.year, now.month, (now.day - 4).clamp(1, 28), 12, 10),
        categoryId: CategoryModel.health.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.upi,
        note: 'Daily multivitamin pack',
        isSample: true,
      ),
      TransactionModel(
        id: 'tx_10',
        title: 'IMAX Movie Tickets',
        amount: 24.50,
        date: DateTime(now.year, now.month, (now.day - 5).clamp(1, 28), 20, 15),
        categoryId: CategoryModel.entertainment.id,
        type: TransactionType.expense,
        paymentMethod: PaymentMethod.card,
        note: 'Weekend sci-fi screening',
        isSample: true,
      ),
    ];
  }

  static BudgetModel getMonthlyBudget() {
    final now = DateTime.now();
    return BudgetModel(
      id: 'budget_overall',
      limitAmount: 2200.00,
      month: now.month,
      year: now.year,
    );
  }
}
