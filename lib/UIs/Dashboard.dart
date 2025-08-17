import 'package:flutter/material.dart';
import 'package:business_app/tools/inventoryProvider.dart';
import 'package:fl_chart/fl_chart.dart';
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
  final _debtAmountController = TextEditingController();
  final _debtProposedDateController = TextEditingController();
  var debtData = <String, dynamic>{};
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

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
      listen: true,
    );
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = [Colors.blue[900]!, Colors.blue[800]!];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Business Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor[0],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/Login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await inventoryProvider.refreshDashboardData(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeSelector(context),
              SizedBox(height: 20),
              _buildSummaryCards(
                inventoryProvider,
                cardColor,
                textColor,
                primaryColor[1],
              ),
              SizedBox(height: 20),
              _buildChartsSection(inventoryProvider, cardColor, textColor),
              SizedBox(height: 20),
              _buildQuickActions(primaryColor[1]),
              SizedBox(height: 20),
              _buildRecentActivity(cardColor, textColor),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionMenu,
        backgroundColor: primaryColor[0],
        child: Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: _buildBottomAppBar(primaryColor[0]),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    onTap: () =>
                        _selectDateForField(context, _startDateController),
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    onTap: () =>
                        _selectDateForField(context, _endDateController),
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _refreshDashboardWithDateRange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    Inventoryprovider provider,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildSummaryCard(
              'Sales',
              '${provider.salesAmount.toStringAsFixed(0)} RWF',
              Icons.shopping_cart,
              cardColor,
              textColor,
              primaryColor,
            ),
            _buildSummaryCard(
              'Purchases',
              '${provider.purchasesAmount.toStringAsFixed(0)} RWF',
              Icons.shopping_bag,
              cardColor,
              textColor,
              primaryColor,
            ),
            _buildSummaryCard(
              'Expenses',
              '${provider.spentsAmount.toStringAsFixed(0)} RWF',
              Icons.money_off,
              cardColor,
              textColor,
              primaryColor,
            ),
            _buildSummaryCard(
              'Debts',
              '${provider.debtsAmount.toStringAsFixed(0)} RWF',
              Icons.credit_card,
              cardColor,
              textColor,
              primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(
    Inventoryprovider provider,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Income vs Expenses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: provider.salesAmount > 0
                              ? provider.salesAmount
                              : 1,
                          title: 'Sales',
                          color: Colors.blue,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: provider.purchasesAmount > 0
                              ? provider.purchasesAmount
                              : 1,
                          title: 'Purchase',
                          color: Colors.green,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: provider.spentsAmount > 0
                              ? provider.spentsAmount
                              : 1,
                          title: 'Spent',
                          color: Colors.orange,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: provider.debtsAmount > 0
                              ? provider.debtsAmount
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
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Monthly Comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(height: 200, child: _buildSummaryBarChart(provider)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 1,
          children: [
            _buildQuickActionButton(
              Icons.point_of_sale,
              'New Sale',
              primaryColor,
              () => showAddSaleForm(context),
            ),
            _buildQuickActionButton(
              Icons.shopping_basket,
              'Purchase',
              primaryColor,
              () => showAddPurchaseForm(context),
            ),
            _buildQuickActionButton(
              Icons.money_off,
              'Expense',
              primaryColor,
              () => showAddSpentForm(context),
            ),
            _buildQuickActionButton(
              Icons.credit_card,
              'Debt',
              primaryColor,
              () => showAddDebtForm(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Color cardColor, Color textColor) {
    final recentActivities = [
      {'type': 'Sale', 'amount': '15,000 RWF', 'time': '2 mins ago'},
      {'type': 'Purchase', 'amount': '25,000 RWF', 'time': '1 hour ago'},
      {'type': 'Expense', 'amount': '5,000 RWF', 'time': '3 hours ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(child: Text('View All'), onPressed: () {}),
          ],
        ),
        SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: recentActivities
                  .map((activity) => _buildActivityItem(activity, textColor))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, String> activity, Color textColor) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'Sale':
        icon = Icons.shopping_cart;
        color = Colors.green;
        break;
      case 'Purchase':
        icon = Icons.shopping_bag;
        color = Colors.blue;
        break;
      default:
        icon = Icons.money_off;
        color = Colors.orange;
    }

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity['type']!,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      subtitle: Text(
        activity['time']!,
        style: TextStyle(color: textColor.withOpacity(0.6)),
      ),
      trailing: Text(
        activity['amount']!,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildBottomAppBar(Color primaryColor) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBarChart(Inventoryprovider provider) {
    final maxAmount = [
      provider.salesAmount,
      provider.purchasesAmount,
      provider.spentsAmount,
      provider.debtsAmount,
    ].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount > 0 ? maxAmount * 1.2 : 1000,
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
                toY: provider.salesAmount > 0 ? provider.salesAmount : 0,
                color: Colors.blue,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: provider.purchasesAmount > 0
                    ? provider.purchasesAmount
                    : 0,
                color: Colors.green,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: provider.spentsAmount > 0 ? provider.spentsAmount : 0,
                color: Colors.orange,
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: provider.debtsAmount > 0 ? provider.debtsAmount : 0,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActionMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + (overlay.size.width / 2) - 85,
        buttonPosition.dy + 613,
        overlay.size.width - buttonPosition.dx,
        overlay.size.height - buttonPosition.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'Sale',
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white),
              SizedBox(width: 10),
              Text('Sale', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Purchase',
          child: Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.white),
              SizedBox(width: 10),
              Text('Purchase', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Expense',
          child: Row(
            children: [
              Icon(Icons.money_off, color: Colors.white),
              SizedBox(width: 10),
              Text('Expense', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Debt',
          child: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.white),
              SizedBox(width: 10),
              Text('Debt', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      color: Theme.of(context).primaryColor,
    ).then((value) {
      if (!mounted) return;
      if (value == 'Sale') showAddSaleForm(context);
      if (value == 'Purchase') showAddPurchaseForm(context);
      if (value == 'Expense') showAddSpentForm(context);
      if (value == 'Debt') showAddDebtForm(context);
    });
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
      final success = await inventoryProvider.refreshDashboardData(
        startDate: startDate,
        endDate: endDate,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final inventoryProvider = Provider.of<Inventoryprovider>(
        context,
        listen: false,
      );
      final success = await inventoryProvider.refreshDashboardData();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // [Keep all your existing form methods like showAddSaleForm, showAddPurchaseForm, etc.]
  // These would be included exactly as they were in your original file
  // I've omitted them here for brevity but they should be included in the actual file
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
    void clearSalesFields() {
      searchController.clear();
      descriptionController.clear();
      quantityController.clear();
      unitPriceController.clear();
      totalPriceController.clear();
      currentPriceController = '';
      currentQuantityController = '';
    }

    void clearPaymentFields() {
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
                              });
                            }
                            clearSalesFields();
                            formKey.currentState?.reset();
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
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showAddDebtForm(context);
                                          },

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                          ),
                                          child: Text(
                                            'Add Debt Information',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
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
                        SizedBox(height: 20),
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
                              debtData: _debtSelected ? debtData : null,
                            );

                            // Call the new addSaleRecord method
                            final success = await inventoryProvider
                                .addSaleRecord(saleData);
                            chartItems.clear();
                            clearSalesFields();
                            clearPaymentFields();
                            Navigator.pop(context);
                            if (success) {
                              // Clear all fields after successful sale
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
                            'Add to List',
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
                          onTap: () => _selectDate(
                            context,
                            setModalState,
                            _dateController,
                          ),
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
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Customer Name
                        TextFormField(
                          controller: _debtCustomerNameController,
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
                          controller: _debtCustomerPhoneController,
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
                          controller: _debtCustomerEmailController,
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
                          controller: _debtCustomerAddressController,
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
                          controller: _debtAmountController,
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
                          controller: _debtProposedDateController,
                          decoration: InputDecoration(
                            labelText: 'Proposed Payment Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(
                            context,
                            setModalState,
                            _debtProposedDateController,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Save Button
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                debtData = {
                                  'names': _debtCustomerNameController.text,
                                  'phone': _debtCustomerPhoneController.text,
                                  'email':
                                      _debtCustomerEmailController
                                          .text
                                          .isNotEmpty
                                      ? _debtCustomerEmailController.text
                                      : null,
                                  'address':
                                      _debtCustomerAddressController
                                          .text
                                          .isNotEmpty
                                      ? _debtCustomerAddressController.text
                                      : null,
                                  'debt_amount': double.parse(
                                    _debtAmountController.text,
                                  ),
                                  'proposed_refund_date':
                                      _debtProposedDateController.text,
                                };
                                Navigator.pop(context);
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
                            backgroundColor: Colors.deepOrange,
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
