// ignore_for_file: use_build_context_synchronously

import 'package:business_app/tools/inventoryProvider.dart';
import 'package:business_app/tools/Database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  // final TextEditingController _itemController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final _cashController = TextEditingController();
  final _momoController = TextEditingController();
  final _bankController = TextEditingController();
  final _otherController = TextEditingController();
  final _otherPaymentNameController = TextEditingController();
  final _debtController = TextEditingController();
  final _debtCustomerNameController = TextEditingController();
  final _debtCustomerPhoneController = TextEditingController();
  final _debtCustomerEmailController = TextEditingController();
  final _debtCustomerAddressController = TextEditingController();
  final _debtProposedDateController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  // Add these variables to track selected payment methods
  bool _cashSelected = false;
  bool _momoSelected = false;
  bool _bankSelected = false;
  bool _otherSelected = false;
  bool _debtSelected = false;
  String currentPriceController = '';
  String currentQuantityController = '';
  int totalPrice = 0;
  int cashAmount = 0;
  int momoAmount = 0;
  int bankAmount = 0;
  int otherAmount = 0;
  int debtAmount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _endDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Initialize sales and purchases amounts when the dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inventoryProvider = Provider.of<Inventoryprovider>(
        context,
        listen: false,
      );
      await inventoryProvider.refreshDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if this is the first time or if we're returning to the dashboard
    // This prevents excessive refreshing
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startDateController.dispose();
    _endDateController.dispose();
    _debtController.dispose();
    _debtCustomerNameController.dispose();
    _debtCustomerPhoneController.dispose();
    _debtCustomerEmailController.dispose();
    _debtCustomerAddressController.dispose();
    _debtProposedDateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes visible again
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final inventoryProvider = Provider.of<Inventoryprovider>(
          context,
          listen: false,
        );
        await inventoryProvider.refreshDashboardData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<Inventoryprovider>(
      context,
      listen: true, // Changed to true to listen to changes
    );
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Dashboard $inventory'),
      //   backgroundColor: Colors.blue[900],
      //   centerTitle: true,
      // ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 120,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, left: 20),
                      child: Text(
                        'Business Wallet',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final inventoryProvider = Provider.of<Inventoryprovider>(
                    context,
                    listen: false,
                  );
                  await inventoryProvider.refreshDashboardData();
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 370,
                            height: 100,
                            margin: const EdgeInsets.only(
                              top: 5,
                              left: 20,
                              right: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Form(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startDateController,
                                        onTap: () async {
                                          await _selectDateForField(
                                            context,
                                            _startDateController,
                                          );
                                          _onDateChanged();
                                        },
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Start Date of Summary',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ), // Add spacing between fields
                                    Expanded(
                                      child: TextFormField(
                                        controller: _endDateController,
                                        onTap: () async {
                                          await _selectDateForField(
                                            context,
                                            _endDateController,
                                          );
                                          _onDateChanged();
                                        },
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'End Date of Summary',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          final startDate = DateFormat(
                                            'yyyy-MM-dd',
                                          ).parse(_startDateController.text);
                                          final endDate = DateFormat(
                                            'yyyy-MM-dd',
                                          ).parse(_endDateController.text);
                                          final inventoryProvider =
                                              Provider.of<Inventoryprovider>(
                                                context,
                                                listen: false,
                                              );
                                          final success =
                                              await inventoryProvider
                                                  .refreshDashboardData(
                                                    startDate: startDate,
                                                    endDate: endDate,
                                                  );
                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Data refreshed successfully',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // If date parsing fails, refresh with current date
                                          final inventoryProvider =
                                              Provider.of<Inventoryprovider>(
                                                context,
                                                listen: false,
                                              );
                                          final success =
                                              await inventoryProvider
                                                  .refreshDashboardData();
                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Data refreshed successfully',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: Icon(
                                        Icons.refresh,
                                        color: Colors.blue[900],
                                      ),
                                      tooltip: 'Refresh Data',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildBigRow(
                        'Daily Sales',
                        inventoryProvider.salesAmount > 0
                            ? '${inventoryProvider.salesAmount.toStringAsFixed(0)} RWF'
                            : '0 RWF',
                      ),
                      // _buildCardRow([
                      //   {'title': 'Daily Sales', 'amount': '100,000 RWF'},
                      //   {'title': 'Daily Purchase', 'amount': '300,000 RWF'},
                      // ]),
                      _buildCardRow([
                        {
                          'title': 'Daily Spent',
                          'amount': inventoryProvider.spentsAmount > 0
                              ? '${inventoryProvider.spentsAmount.toStringAsFixed(0)} RWF'
                              : '0 RWF',
                          'icon': CupertinoIcons.money_dollar,
                        },
                        {
                          'title': 'Daily Debts',
                          'amount': inventoryProvider.debtsAmount > 0
                              ? '${inventoryProvider.debtsAmount.toStringAsFixed(0)} RWF'
                              : '0 RWF',
                          'icon': CupertinoIcons.money_dollar,
                        },
                      ]),
                      _buildBigRow(
                        'Daily Purchase',
                        inventoryProvider.purchasesAmount > 0
                            ? '${inventoryProvider.purchasesAmount.toStringAsFixed(0)} RWF'
                            : '0 RWF',
                      ),
                      SizedBox(height: 20),
                      _buildSummaryPieChart(inventoryProvider),
                      SizedBox(height: 20),
                      _buildSummaryBarChart(inventoryProvider),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: Colors.blue[900],
        child: Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;

          // Get button's global position
          final Offset buttonPosition = button.localToGlobal(
            Offset.zero,
            ancestor: overlay,
          );

          // Define menu position (above the button)
          final RelativeRect position = RelativeRect.fromLTRB(
            buttonPosition.dx +
                (overlay.size.width / 2) -
                85, // Left = button's left edge
            buttonPosition.dy +
                613, // Top = button's top edge - 100px (to move up)
            overlay.size.width -
                buttonPosition.dx, // Right = screen width - button's left
            overlay.size.height -
                buttonPosition.dy, // Bottom = screen height - button's top
          );

          showMenu(
            context: context,
            position: position,
            items: [
              PopupMenuItem(
                value: 'Sale',
                child: SizedBox(
                  width: 140,
                  height: 20,
                  child: Center(
                    child: Text(
                      'Sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Purchase',
                child: Center(
                  child: Text(
                    'Purchase',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Spent',
                child: Center(
                  child: Text(
                    'Spent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Debt',
                child: Center(
                  child: Text(
                    'Debt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
            color: Colors.blue[900],
          ).then((value) {
            if (!mounted) return;
            if (value == 'Sale') showAddSaleForm(context);
            if (value == 'Purchase') showAddPurchaseForm(context);
            if (value == 'Spent') showAddSpentForm(context);
            if (value == 'Debt') showAddDebtForm(context);
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 50,
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.blue[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_rounded, color: Colors.white, size: 30),
              onPressed: () {
                // Set state to show home/dashboard
              },
            ),
            SizedBox(width: 48), // The FAB sits here
            IconButton(
              icon: Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                // Set state to show stats
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String amount) {
    return Card(
      color: Colors.blue[100],
      child: SizedBox(
        width: 177,
        height: 200,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateForField(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _refreshDashboardWithDateRange() async {
    try {
      final startDate = DateFormat(
        'yyyy-MM-dd',
      ).parse(_startDateController.text);
      final endDate = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
      final inventoryProvider = Provider.of<Inventoryprovider>(
        context,
        listen: false,
      );
      await inventoryProvider.refreshDashboardData(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      // If date parsing fails, refresh with current date
      final inventoryProvider = Provider.of<Inventoryprovider>(
        context,
        listen: false,
      );
      await inventoryProvider.refreshDashboardData();
    }
  }

  void _onDateChanged() {
    // Only refresh if both dates are set
    if (_startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty) {
      _refreshDashboardWithDateRange();
    }
  }

  Widget _buildCardRow(List<Map<String, dynamic>> cards) {
    return Row(
      children: [
        Container(
          width: 370,
          height: 100,
          margin: const EdgeInsets.only(top: 5, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Row(
              children: cards.map((data) {
                return _buildCard(
                  data['title'] as String,
                  data['amount'] as String,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBigRow(String title, String amount) {
    return Row(
      children: [
        Container(
          width: 370,
          height: 100,
          margin: const EdgeInsets.only(top: 5, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Pie Chart Widget
  Widget _buildSummaryPieChart(Inventoryprovider inventoryProvider) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: inventoryProvider.salesAmount > 0
                  ? inventoryProvider.salesAmount
                  : 1,
              title: 'Sales',
              color: Colors.blue,
              radius: 50,
            ),
            PieChartSectionData(
              value: inventoryProvider.purchasesAmount > 0
                  ? inventoryProvider.purchasesAmount
                  : 1,
              title: 'Purchase',
              color: Colors.green,
              radius: 50,
            ),
            PieChartSectionData(
              value: inventoryProvider.spentsAmount > 0
                  ? inventoryProvider.spentsAmount
                  : 1,
              title: 'Spent',
              color: Colors.orange,
              radius: 50,
            ),
            PieChartSectionData(
              value: inventoryProvider.debtsAmount > 0
                  ? inventoryProvider.debtsAmount
                  : 1,
              title: 'Debts',
              color: Colors.red,
              radius: 50,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 30,
        ),
      ),
    );
  }

  // Bar Chart Widget
  Widget _buildSummaryBarChart(Inventoryprovider inventoryProvider) {
    // Calculate max Y value for better chart scaling
    final maxAmount = [
      inventoryProvider.salesAmount,
      inventoryProvider.purchasesAmount,
      inventoryProvider.spentsAmount,
      inventoryProvider.debtsAmount,
    ].reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      width: 350,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount > 0 ? maxAmount * 1.2 : 1000, // Add 20% padding
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final titles = ['Sales', 'Purchase', 'Spent', 'Debts'];
                  return Text(titles[value.toInt()]);
                },
                interval: 1,
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: inventoryProvider.salesAmount > 0
                      ? inventoryProvider.salesAmount
                      : 0,
                  color: Colors.blue,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: inventoryProvider.purchasesAmount > 0
                      ? inventoryProvider.purchasesAmount
                      : 0,
                  color: Colors.green,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: inventoryProvider.spentsAmount > 0
                      ? inventoryProvider.spentsAmount
                      : 0,
                  color: Colors.orange,
                ),
              ],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [
                BarChartRodData(
                  toY: inventoryProvider.debtsAmount > 0
                      ? inventoryProvider.debtsAmount
                      : 0,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showAddSaleForm(BuildContext context) async {
    final inventoryProvider = Provider.of<Inventoryprovider>(
      context,
      listen: false,
    );
    await inventoryProvider.getInventoryItems();
    final inventory = inventoryProvider.inventory;
    final itemNames = inventory.map((item) => item['name'] as String).toList();
    final formKey = GlobalKey<FormState>();
    bool payMethodShow = false;
    // Controllers
    final searchController = TextEditingController();

    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();
    final unitPriceController = TextEditingController();
    final totalPriceController = TextEditingController();
    String currentPriceController = '';
    String currentQuantityController = '';

    List<Map<String, dynamic>> chartItems = [];
    // Clear all input fields
    void clearFields() {
      searchController.clear();
      descriptionController.clear();
      quantityController.clear();
      unitPriceController.clear();
      totalPriceController.clear();
      currentPriceController = '';
      currentQuantityController = '';

      // Clear payment method fields
      _cashController.clear();
      _momoController.clear();
      _bankController.clear();
      _otherController.clear();
      _otherPaymentNameController.clear();
      _debtController.clear();
      _debtCustomerNameController.clear();
      _debtCustomerPhoneController.clear();
      _debtCustomerEmailController.clear();
      _debtCustomerAddressController.clear();
      _debtProposedDateController.clear();

      // Reset payment method selections
      _cashSelected = false;
      _momoSelected = false;
      _bankSelected = false;
      _otherSelected = false;
      _debtSelected = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'New sale Record',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Item selection
                        TypeAheadFormField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: 'Item Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: Icon(Icons.search),
                              hintText: 'Type to search or enter new item',
                            ),
                          ),
                          suggestionsCallback: (pattern) async {
                            currentPriceController = '';
                            currentQuantityController = '';
                            if (pattern.isEmpty) {
                              return itemNames;
                            }
                            return itemNames.where(
                              (name) => name.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                            );
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(title: Text(suggestion));
                          },
                          onSuggestionSelected: (suggestion) {
                            setModalState(() {
                              searchController.text = suggestion;
                              final selectedIndex = itemNames.indexOf(
                                suggestion,
                              );
                              descriptionController.text =
                                  inventory[selectedIndex]['description'];
                              currentPriceController =
                                  'Current Price: ${inventory[selectedIndex]['unit_price'].toString()} RWF';
                              currentQuantityController =
                                  'Current Quantity: ${inventory[selectedIndex]['quantity'].toString()}';
                              final quantity =
                                  int.tryParse(quantityController.text) ?? 0;
                              final unitPrice =
                                  int.tryParse(unitPriceController.text) ?? 0;
                              final total = quantity * unitPrice;
                              totalPriceController.text = total.toString();
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please type and select an item';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Item description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Item Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Quantity
                        TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Item Quantity',
                            suffix: Text(currentQuantityController),
                            suffixStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null) {
                              return 'Please enter numeric value';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final quantity =
                                int.tryParse(quantityController.text) ?? 0;
                            final unitPrice =
                                int.tryParse(unitPriceController.text) ?? 0;
                            final total = quantity * unitPrice;
                            setModalState(() {
                              totalPriceController.text = total.toString();
                            });
                          },
                        ),
                        SizedBox(height: 20),

                        // Unit price
                        TextFormField(
                          controller: unitPriceController,
                          decoration: InputDecoration(
                            labelText: 'Unit Price',
                            prefixText: 'RWF  ',
                            prefixStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            suffix: Text(currentPriceController),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null) {
                              return 'Please enter numeric value';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final quantity =
                                int.tryParse(quantityController.text) ?? 0;
                            final unitPrice =
                                int.tryParse(unitPriceController.text) ?? 0;
                            final total = quantity * unitPrice;
                            setModalState(() {
                              totalPriceController.text = total.toString();
                            });
                          },
                        ),
                        SizedBox(height: 20),

                        // Total price
                        TextFormField(
                          controller: totalPriceController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Total Price',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Add to chart button
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              setModalState(() {
                                chartItems.add({
                                  'name': searchController.text,
                                  'description': descriptionController.text,
                                  'unit_price': int.tryParse(
                                    unitPriceController.text,
                                  ),
                                  'quantity': int.tryParse(
                                    quantityController.text,
                                  ),
                                  'total_price': int.tryParse(
                                    totalPriceController.text,
                                  ),
                                });
                                // Calculate total from chartItems instead of using global totalPrice
                                int currentTotal = chartItems.fold(
                                  0,
                                  (sum, item) =>
                                      sum + (item['total_price'] as int),
                                );
                                totalPrice = currentTotal;

                                clearFields();
                                formKey.currentState?.reset();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[900],
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Add to Chart',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Chart items list
                        if (chartItems.isNotEmpty) ...[
                          Text(
                            'Items in Chart (${chartItems.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: chartItems.length,
                              itemBuilder: (context, index) {
                                final item = chartItems[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(item['name']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Qty: ${item['quantity']}'),
                                        Text(
                                          'Price: RWF ${item['unit_price']}',
                                        ),
                                        Text(
                                          'Total: RWF ${item['total_price']}',
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          chartItems.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              payMethodShow = !payMethodShow;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Center(
                            child: Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        // Add this widget after the chart items list in your bottom sheet
                        if (payMethodShow) ...[
                          if (chartItems.isNotEmpty) ...[
                            Divider(thickness: 2),
                            SizedBox(height: 20),
                            Text(
                              'Payment Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            SizedBox(height: 15),

                            // Total amount reminder
                            Text(
                              'Total Amount: RWF ${chartItems.fold(0, (sum, item) => sum + (item['total_price'] as int))}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),

                            // Payment method checkboxes
                            Column(
                              children: [
                                // Cash payment
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _cashSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _cashSelected = value!;
                                          if (!_cashSelected) {
                                            _cashController.clear();
                                          }
                                          // Auto-fill remaining amount if this is the only selected method
                                          if (_cashSelected &&
                                              !_momoSelected &&
                                              !_bankSelected &&
                                              !_otherSelected) {
                                            int totalAmount = chartItems.fold(
                                              0,
                                              (sum, item) =>
                                                  sum +
                                                  (item['total_price'] as int),
                                            );
                                            _cashController.text = totalAmount
                                                .toString();
                                          }
                                        });
                                      },
                                    ),
                                    Text('Cash'),
                                    if (_cashSelected) ...[
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _cashController,
                                          decoration: InputDecoration(
                                            labelText: 'Amount',
                                            prefixText: 'RWF ',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setModalState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Mobile Money payment
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _momoSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _momoSelected = value!;
                                          if (!_momoSelected) {
                                            _momoController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text('Mobile Money'),
                                    if (_momoSelected) ...[
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _momoController,
                                          decoration: InputDecoration(
                                            labelText: 'Amount',
                                            prefixText: 'RWF ',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setModalState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Bank Transfer payment
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _bankSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _bankSelected = value!;
                                          if (!_bankSelected) {
                                            _bankController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text('Bank Transfer'),
                                    if (_bankSelected) ...[
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _bankController,
                                          decoration: InputDecoration(
                                            labelText: 'Amount',
                                            prefixText: 'RWF ',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            setModalState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Other payment method
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _otherSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _otherSelected = value!;
                                          if (!_otherSelected) {
                                            _otherController.clear();
                                            _otherPaymentNameController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text('Other'),
                                    if (_otherSelected) ...[
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller:
                                                  _otherPaymentNameController,
                                              decoration: InputDecoration(
                                                labelText: 'Method Name',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {},
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller: _otherController,
                                              decoration: InputDecoration(
                                                labelText: 'Amount',
                                                prefixText: 'RWF ',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                setModalState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Debt payment method
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _debtSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _debtSelected = value!;
                                          if (!_debtSelected) {
                                            _debtController.clear();
                                            _debtCustomerNameController.clear();
                                            _debtCustomerPhoneController
                                                .clear();
                                            _debtCustomerEmailController
                                                .clear();
                                            _debtCustomerAddressController
                                                .clear();
                                            _debtProposedDateController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text('Debt'),
                                    if (_debtSelected) ...[
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _debtController,
                                              decoration: InputDecoration(
                                                labelText: 'Debt Amount',
                                                prefixText: 'RWF ',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                setModalState(() {});
                                              },
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  _debtCustomerNameController,
                                              decoration: InputDecoration(
                                                labelText: 'Customer Name',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  _debtCustomerPhoneController,
                                              decoration: InputDecoration(
                                                labelText: 'Customer Phone',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.phone,
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  _debtCustomerEmailController,
                                              decoration: InputDecoration(
                                                labelText: 'Customer Email',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  _debtCustomerAddressController,
                                              decoration: InputDecoration(
                                                labelText: 'Customer Address',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  _debtProposedDateController,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Proposed Payment Date',
                                                border: OutlineInputBorder(),
                                              ),
                                              readOnly: true,
                                              onTap: () => _selectDate(
                                                context,
                                                setModalState,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),

                            // Remaining amount display
                            // SizedBox(height: 20),
                            // Text(
                            //   'Remaining Amount: RWF ${calculateRemainingAmount(chartItems).toStringAsFixed(2)}',
                            //   style: TextStyle(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.bold,
                            //     color: calculateRemainingAmount(chartItems) > 0
                            //         ? Colors.red
                            //         : Colors.green,
                            //   ),
                            // ),
                            // SizedBox(height: 20),

                            // // Validation for payment
                            // if (calculateRemainingAmount(chartItems) < 0)
                            //   Text(
                            //     'Total payments exceed the amount due!',
                            //     style: TextStyle(color: Colors.red),
                            //   ),
                          ],
                        ],
                        // Submit all button
                        ElevatedButton(
                          onPressed: () async {
                            if (chartItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please add items to chart first',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validate payment methods
                            if (!_cashSelected &&
                                !_momoSelected &&
                                !_bankSelected &&
                                !_otherSelected &&
                                !_debtSelected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select at least one payment method',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validate debt information if debt is selected
                            if (_debtSelected) {
                              if (_debtCustomerNameController.text.isEmpty ||
                                  _debtCustomerPhoneController.text.isEmpty ||
                                  _debtProposedDateController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please fill in all debt customer information',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            // Create SaleItem objects from chartItems
                            List<SaleItem> saleItems = chartItems.map((item) {
                              return SaleItem(
                                name: item['name'],
                                description: item['description'],
                                unitPrice: item['unit_price'],
                                quantity: item['quantity'],
                                totalPrice: item['total_price'],
                              );
                            }).toList();

                            // Create PaymentInfo object
                            PaymentInfo paymentInfo = PaymentInfo(
                              cashSelected: _cashSelected,
                              momoSelected: _momoSelected,
                              bankSelected: _bankSelected,
                              otherSelected: _otherSelected,
                              debtSelected: _debtSelected,
                              cashAmount:
                                  int.tryParse(_cashController.text) ?? 0,
                              momoAmount:
                                  int.tryParse(_momoController.text) ?? 0,
                              bankAmount:
                                  int.tryParse(_bankController.text) ?? 0,
                              otherAmount:
                                  int.tryParse(_otherController.text) ?? 0,
                              debtAmount:
                                  int.tryParse(_debtController.text) ?? 0,
                              otherPaymentName:
                                  _otherPaymentNameController.text.isNotEmpty
                                  ? _otherPaymentNameController.text
                                  : null,
                            );

                            // Create SaleData object
                            SaleData saleData = SaleData(
                              items: saleItems,
                              paymentInfo: paymentInfo,
                              debtData: _debtSelected
                                  ? {
                                      'customer_name':
                                          _debtCustomerNameController.text,
                                      'customer_phone':
                                          _debtCustomerPhoneController.text,
                                      'customer_email':
                                          _debtCustomerEmailController.text,
                                      'customer_address':
                                          _debtCustomerAddressController.text,
                                      'debt_amount':
                                          int.tryParse(_debtController.text) ??
                                          0,
                                      'proposed_payment_date':
                                          _debtProposedDateController.text,
                                    }
                                  : null,
                            );

                            // Call the new addSaleRecord method
                            final success = await inventoryProvider
                                .addSaleRecord(saleData);

                            if (success) {
                              Navigator.pop(context);
                              clearFields(); // Clear all fields after successful sale
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Center(
                                    child: Text(
                                      '${chartItems.length} sale records added successfully',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              chartItems.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save sale records'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Save All (${chartItems.length}) sale items',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddPurchaseForm(BuildContext context) async {
    final inventoryprovider = Provider.of<Inventoryprovider>(
      context,
      listen: false,
    );
    await inventoryprovider.getInventoryItems();
    final inventory = inventoryprovider.inventory;
    final itemNames = inventory.map((item) => item['name'] as String).toList();
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> tempSaleItems = [];
    _searchController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _totalPriceController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'New Purchase Record',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TypeAheadFormField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Item Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: Icon(Icons.search),
                              hintText: 'Type to search or enter new item',
                            ),
                          ),
                          suggestionsCallback: (pattern) async {
                            // await Inventoryprovider().getInventoryItems();
                            // final inventory = Inventoryprovider().inventory;
                            currentPriceController = '';
                            currentQuantityController = '';
                            if (pattern.isEmpty) {
                              return itemNames;
                            }
                            return itemNames.where(
                              (name) => name.toLowerCase().contains(
                                pattern.toLowerCase(),
                              ),
                            );
                          },

                          itemBuilder: (context, suggestion) {
                            return ListTile(title: Text(suggestion));
                          },
                          onSuggestionSelected: (suggestion) {
                            setModalState(() {
                              _searchController.text = suggestion;
                              final selectedIndex = itemNames.indexOf(
                                suggestion,
                              );
                              _descriptionController.text =
                                  inventory[selectedIndex]['description'];
                              currentPriceController =
                                  'Current Price: ${inventory[selectedIndex]['unit_price'].toString()} RWF';
                              currentQuantityController =
                                  'Current Quantity: ${inventory[selectedIndex]['quantity'].toString()}';
                              final quantity =
                                  int.tryParse(_quantityController.text) ?? 0;
                              final unitPrice =
                                  int.tryParse(_unitPriceController.text) ?? 0;
                              final total = quantity * unitPrice;

                              _totalPriceController.text = total.toString();
                            });
                          },
                          suggestionsBoxDecoration: SuggestionsBoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            elevation: 4.0,
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select or enter an item';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Item Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Item Quantity',
                            suffix: Text(currentQuantityController),
                            suffixStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null) {
                              return 'Please enter numeric value';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final quantity =
                                int.tryParse(_quantityController.text) ?? 0;
                            final unitPrice =
                                int.tryParse(_unitPriceController.text) ?? 0;
                            final total = quantity * unitPrice;
                            setModalState(() {
                              _totalPriceController.text = total.toString();
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _unitPriceController,
                          decoration: InputDecoration(
                            labelText: 'Unit Price',
                            prefixText: 'RWF  ',
                            prefixStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            suffix: Text(currentPriceController),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null) {
                              return 'Please enter numeric value';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final quantity =
                                int.tryParse(_quantityController.text) ?? 0;
                            final unitPrice =
                                int.tryParse(_unitPriceController.text) ?? 0;
                            final total = quantity * unitPrice;
                            setModalState(() {
                              _totalPriceController.text = total.toString();
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _totalPriceController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Total Price',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || int.tryParse(value) == null) {
                              return 'Please enter numeric value';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              setModalState(() {
                                tempSaleItems.add({
                                  'name': _searchController.text,
                                  'description': _descriptionController.text,
                                  'unit_price': int.tryParse(
                                    _unitPriceController.text,
                                  ),
                                  'quantity': int.tryParse(
                                    _quantityController.text,
                                  ),
                                  'total_price': int.tryParse(
                                    _totalPriceController.text,
                                  ),
                                });
                                // Clear fields for next entry
                                _searchController.clear();
                                _descriptionController.clear();
                                _quantityController.clear();
                                _unitPriceController.clear();
                                _totalPriceController.clear();
                                currentPriceController = '';
                                currentQuantityController = '';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[900],
                          ),
                          child: Text(
                            'Add to Chart',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Map<String, dynamic> item = {
                                'name': _searchController.text,
                                'description': _descriptionController.text,
                                'unit_price': int.tryParse(
                                  _unitPriceController.text,
                                ),
                                'quantity': int.tryParse(
                                  _quantityController.text,
                                ),
                              };
                              if (await Inventoryprovider().addPurchaseRecord(
                                item,
                              )) {
                                formKey.currentState?.reset();
                                _searchController.clear();
                                _descriptionController.clear();
                                _quantityController.clear();
                                _unitPriceController.clear();
                                _totalPriceController.clear();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: Text(
                                        'Purchase record added successfully',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                          ),
                          child: Text(
                            'Save Purchase Record',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddSpentForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    TextEditingController reasonController = TextEditingController();
    TextEditingController spentAmountController = TextEditingController();
    final inventoryprovider = Provider.of<Inventoryprovider>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'New Spent Record',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: reasonController,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: spentAmountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefix: Text('RWF '),
                            prefixStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid numeric value';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _dateController,
                          onTap: () => _selectDate(context, setModalState),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date of Spent Record',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Map<String, dynamic> item = {
                                'reason': reasonController.text,
                                'spent_amount': int.tryParse(
                                  spentAmountController.text,
                                ),
                                'date': _selectedDate?.toIso8601String(),
                              };
                              bool success = await inventoryprovider
                                  .addSpentRecord(item);
                              if (success) {
                                reasonController.clear();
                                spentAmountController.clear();
                                formKey.currentState?.reset();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: Text(
                                        'Spent record added successfully',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                reasonController.clear();
                                spentAmountController.clear();
                                formKey.currentState?.reset();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: Text(
                                        'Error, Spent record not added successfully',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              // Process the form data
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                          ),
                          child: Text(
                            'Save Spent Record',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddDebtForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final customerEmailController = TextEditingController();
    final customerAddressController = TextEditingController();
    final debtAmountController = TextEditingController();
    final proposedDateController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'New Debt Record',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Customer Name
                        TextFormField(
                          controller: customerNameController,
                          decoration: InputDecoration(
                            labelText: 'Customer Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        // Customer Phone
                        TextFormField(
                          controller: customerPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Customer Phone *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter customer phone';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        // Customer Email
                        TextFormField(
                          controller: customerEmailController,
                          decoration: InputDecoration(
                            labelText: 'Customer Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 15),

                        // Customer Address
                        TextFormField(
                          controller: customerAddressController,
                          decoration: InputDecoration(
                            labelText: 'Customer Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        // Debt Amount
                        TextFormField(
                          controller: debtAmountController,
                          decoration: InputDecoration(
                            labelText: 'Debt Amount (RWF) *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter debt amount';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),

                        // Proposed Payment Date
                        TextFormField(
                          controller: proposedDateController,
                          decoration: InputDecoration(
                            labelText: 'Proposed Payment Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context, setModalState),
                        ),
                        SizedBox(height: 20),

                        // Save Button
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final debtData = {
                                  'names': customerNameController.text,
                                  'phone': customerPhoneController.text,
                                  'email':
                                      customerEmailController.text.isNotEmpty
                                      ? customerEmailController.text
                                      : null,
                                  'address':
                                      customerAddressController.text.isNotEmpty
                                      ? customerAddressController.text
                                      : null,
                                  'debt_amount': double.parse(
                                    debtAmountController.text,
                                  ),
                                  'proposed_refund_date':
                                      proposedDateController.text,
                                };

                                final inventoryProvider =
                                    Provider.of<Inventoryprovider>(
                                      context,
                                      listen: false,
                                    );

                                final result = await DatabaseHelper.instance
                                    .insertDebt(debtData);
                                if (result > 0) {
                                  // Refresh debts amount
                                  await inventoryProvider.getDebtsAmount();

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Debt record saved successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to save debt record',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Save Debt Record',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int calculateRemainingAmount(List<Map<String, dynamic>> chartItems) {
    // Calculate total from chartItems
    int totalAmount = chartItems.fold(
      0,
      (sum, item) => sum + (item['total_price'] as int),
    );

    if (_cashSelected) {
      cashAmount =
          (totalAmount -
          (int.tryParse(_momoController.text) ?? 0) -
          (int.tryParse(_bankController.text) ?? 0) -
          (int.tryParse(_otherController.text) ?? 0));
      _cashController.text = cashAmount.toString();
      return cashAmount;
    }
    if (_momoSelected) {
      momoAmount =
          (totalAmount -
          (int.tryParse(_cashController.text) ?? 0) -
          (int.tryParse(_bankController.text) ?? 0) -
          (int.tryParse(_otherController.text) ?? 0));
      _momoController.text = momoAmount.toString();
      return momoAmount;
    }
    if (_bankSelected) {
      bankAmount =
          (totalAmount -
          (int.tryParse(_cashController.text) ?? 0) -
          (int.tryParse(_momoController.text) ?? 0) -
          (int.tryParse(_otherController.text) ?? 0));
      _bankController.text = bankAmount.toString();
      return bankAmount;
    }
    if (_otherSelected) {
      otherAmount =
          (totalAmount -
          (int.tryParse(_cashController.text) ?? 0) -
          (int.tryParse(_momoController.text) ?? 0) -
          (int.tryParse(_bankController.text) ?? 0));
      _otherController.text = otherAmount.toString();
      return otherAmount;
    }
    return totalAmount;
  }

  Future<void> _selectDate(
    BuildContext context, [
    Function? setModalState,
    TextEditingController? nameOfController,
  ]) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      nameOfController?.text = DateFormat('yyyy-MM-dd').format(picked);

      // Update parent state
      setState(() {});

      // Update modal state if provided
      if (setModalState != null) {
        setModalState(() {});
      }
    }
  }
}
