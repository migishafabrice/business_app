import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'Database_helper.dart';

// Define a proper data structure for sale records
class SaleData {
  final List<SaleItem> items;
  final PaymentInfo paymentInfo;
  final DateTime saleDate;
  final Map<String, dynamic>? debtData;

  SaleData({
    required this.items,
    required this.paymentInfo,
    DateTime? saleDate,
    this.debtData,
  }) : saleDate = saleDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'paymentInfo': paymentInfo.toMap(),
      'saleDate': saleDate.toIso8601String(),
      'debtData': debtData,
    };
  }
}

class SaleItem {
  final String name;
  final String description;
  final int unitPrice;
  final int quantity;
  final int totalPrice;

  SaleItem({
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}

class PaymentInfo {
  final bool cashSelected;
  final bool momoSelected;
  final bool bankSelected;
  final bool otherSelected;
  final bool debtSelected;
  final int cashAmount;
  final int momoAmount;
  final int bankAmount;
  final int otherAmount;
  final int debtAmount;
  final String? otherPaymentName;
  final DateTime? paymentDate;

  PaymentInfo({
    required this.cashSelected,
    required this.momoSelected,
    required this.bankSelected,
    required this.otherSelected,
    required this.debtSelected,
    required this.cashAmount,
    required this.momoAmount,
    required this.bankAmount,
    required this.otherAmount,
    required this.debtAmount,
    this.otherPaymentName,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'cashSelected': cashSelected,
      'momoSelected': momoSelected,
      'bankSelected': bankSelected,
      'otherSelected': otherSelected,
      'debtSelected': debtSelected,
      'cashAmount': cashAmount,
      'momoAmount': momoAmount,
      'bankAmount': bankAmount,
      'otherAmount': otherAmount,
      'debtAmount': debtAmount,
      'otherPaymentName': otherPaymentName,
    };
  }

  // Calculate total paid amount
  int get totalPaidAmount {
    int total = 0;
    if (cashSelected) total += cashAmount;
    if (momoSelected) total += momoAmount;
    if (bankSelected) total += bankAmount;
    if (otherSelected) total += otherAmount;
    if (debtSelected) total += debtAmount;
    return total;
  }

  // Get payment mode string
  String get paymentMode {
    List<String> modes = [];
    if (cashSelected) modes.add('Cash');
    if (momoSelected) modes.add('Mobile Money');
    if (bankSelected) modes.add('Bank Transfer');
    if (otherSelected) modes.add(otherPaymentName ?? 'Other');
    if (debtSelected) modes.add('Debt');
    return modes.join(', ');
  }

  // Check if payment is complete
  bool get isPaymentComplete {
    return totalPaidAmount > 0;
  }
}

class InventoryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _inventory = [];
  double _sales = 0, _purchases = 0, _spents = 0, _debts = 0;

  List<Map<String, dynamic>> get inventory => _inventory;
  double get salesAmount => _sales;
  double get purchasesAmount => _purchases;
  double get spentsAmount => _spents;
  double get debtsAmount => _debts;

  List<Map<String, dynamic>> _purchaseReport = [];
  List<Map<String, dynamic>> _saleReport = [];
  List<Map<String, dynamic>> _expenseReport = [];
  List<Map<String, dynamic>> _debtReport = [];
  List<Map<String, dynamic>> get purchaseReport => _purchaseReport;
  List<Map<String, dynamic>> get saleReport => _saleReport;
  List<Map<String, dynamic>> get expenseReport => _expenseReport;
  List<Map<String, dynamic>> get debtReport => _debtReport;
  Future<void> generatePurchaseReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _purchaseReport = await DatabaseHelper.instance.getPurchaseReportData(
      startDate: startDate,
      endDate: endDate,
    );
    notifyListeners();
  }

  Future<void> generateSaleReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _saleReport = await DatabaseHelper.instance.getSaleReportData(
      startDate: startDate,
      endDate: endDate,
    );
    notifyListeners();
  }

  Future<void> generateExpenseReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _expenseReport = await DatabaseHelper.instance.getExpenseReportData(
      startDate: startDate,
      endDate: endDate,
    );
    notifyListeners();
  }

  Future<void> generateDebtReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _debtReport = await DatabaseHelper.instance.getDebtReportData(
      startDate: startDate,
      endDate: endDate,
    );
    print('Debt Report: $_debtReport');
    notifyListeners();
  }

  Future<bool> addPurchaseRecord(List<Map<String, dynamic>> items) async {
    try {
      int row = await DatabaseHelper.instance.insertPurchase(items);
      await getInventoryItems();
      return row > 0;
    } catch (e) {
      return false;
    }
  }

  // New method to handle complete sale data with looping
  Future<bool> addSaleRecord(SaleData saleData) async {
    try {
      return await DatabaseHelper.instance.executeTransaction((txn) async {
        // First, create the invoice
        final invoiceData = {
          'mode': saleData.paymentInfo.paymentMode,
          'paid': saleData.paymentInfo.isPaymentComplete ? 'Yes' : 'No',
          'date_at':
              saleData.paymentInfo.paymentDate?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        };

        // Insert invoice and get invoice ID
        final invoiceId = await txn.insert(
          'invoices',
          invoiceData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Process each sale item
        bool allSuccess = true;
        for (SaleItem item in saleData.items) {
          // Find the product in inventory to get product_id
          final product = _inventory.firstWhere(
            (invItem) => invItem['name'] == item.name,
            orElse: () => {},
          );

          if (product.isNotEmpty) {
            // Prepare sale record data
            final saleRecord = {
              'invoice_id': invoiceId,
              'product_id': product['id'],
              'sale_quantity': item.quantity,
              'unit_sale_price': item.unitPrice,
              'created_at': saleData.saleDate.toIso8601String(),
            };

            // Insert sale record
            final saleResult = await txn.insert(
              'sales',
              saleRecord,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            if (saleResult <= 0) {
              allSuccess = false;
            } else {
              // Update inventory quantity
              final newQuantity = (product['quantity'] as int) - item.quantity;
              final now = DateTime.now().toIso8601String();
              await txn.update(
                'products',
                {'quantity': newQuantity, 'created_at': now},
                where: 'id = ?',
                whereArgs: [product['id']],
              );
            }
          } else {
            allSuccess = false;
          }
        }

        // Create debt record if debt is selected
        if (saleData.debtData != null && saleData.paymentInfo.debtSelected) {
          try {
            final debtRecord = {
              'invoice_id': invoiceId,
              'names': saleData.debtData!['names'],
              'email': saleData.debtData!['email'],
              'phone': saleData.debtData!['phone'],
              'address': saleData.debtData!['address'],
              'debt_amount': saleData.debtData!['debt_amount'],
              'proposed_refund_date':
                  saleData.debtData!['proposed_refund_date'],
              'created_at': saleData.saleDate.toIso8601String(),
            };

            final debtResult = await txn.insert(
              'debt',
              debtRecord,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            if (debtResult <= 0) {
              allSuccess = false;
            }
          } catch (e) {
            allSuccess = false;
          }
        }

        return allSuccess;
      });
    } catch (e) {
      return false;
    } finally {
      // Always refresh data after the operation, regardless of success/failure
      await _refreshAllData(saleData.saleDate);
    }
  }

  // Method to add spent records
  Future<bool> addSpentRecord(Map<String, dynamic> spentData) async {
    try {
      int row = await DatabaseHelper.instance.insertSpent(spentData);
      return row > 0;
    } catch (e) {
      return false;
    }
  }

  // This should return a list of maps, each representing an item
  Future<void> getInventoryItems() async {
    _inventory = await DatabaseHelper.instance.loadItems();
    notifyListeners();
  }

  Future<double> getSalesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final totalSales = await DatabaseHelper.instance.getSalesAmount(
      startDate: startDate,
      endDate: endDate,
    );
    _sales = totalSales;
    notifyListeners();
    return _sales;
  }

  Future<void> getPurchasesAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final totalPurchases = await DatabaseHelper.instance.getPurchasesAmount(
      startDate: startDate,
      endDate: endDate,
    );
    _purchases = totalPurchases;
    notifyListeners();
  }

  Future<void> getSpentsAmount({DateTime? startDate, DateTime? endDate}) async {
    final totalSpents = await DatabaseHelper.instance.getSpentsAmount(
      startDate: startDate,
      endDate: endDate,
    );
    _spents = totalSpents;
    notifyListeners();
  }

  Future<void> getDebtsAmount({DateTime? startDate, DateTime? endDate}) async {
    final totalDebts = await DatabaseHelper.instance.getDebtsAmount(
      startDate: startDate,
      endDate: endDate,
    );
    _debts = totalDebts;
    notifyListeners();
  }

  // Method to refresh all dashboard data
  Future<bool> refreshDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await Future.wait([
        getInventoryItems(),
        getSalesAmount(startDate: startDate, endDate: endDate),
        getPurchasesAmount(startDate: startDate, endDate: endDate),
        getSpentsAmount(startDate: startDate, endDate: endDate),
        getDebtsAmount(startDate: startDate, endDate: endDate),
        getDebts(),
      ]);
      notifyListeners();
      return true;
    } catch (e) {
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshAllData(DateTime saleDate) async {
    try {
      await Future.wait([
        getInventoryItems(),
        getSalesAmount(startDate: saleDate, endDate: saleDate),
        getPurchasesAmount(),
        getSpentsAmount(),
        getDebtsAmount(),
        getDebts(),
      ]);
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getDebts() async {
    try {
      final debts = await DatabaseHelper.instance.getAllDebts();
      return debts;
    } catch (e) {
      return [];
    }
  }

  Future<int> payDebtRecord(Map<String, dynamic> paymentData) async {
    try {
      int row = await DatabaseHelper.instance.payDebtRecord(paymentData);
      return row;
    } catch (e) {
      debugPrint('Error paying debt record: $e');
      return 0;
    }
  }
}
