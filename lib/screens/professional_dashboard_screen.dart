import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:async/async.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/utils/stream_extensions.dart';
import 'package:smartexpense/screens/add_expense_screen.dart';
import 'package:smartexpense/screens/add_income_screen.dart';
import 'package:smartexpense/screens/add_loan_screen.dart';
import 'package:smartexpense/screens/settings_screen.dart';
import 'package:smartexpense/screens/profile_screen.dart';
import 'package:smartexpense/screens/recent_expenses_screen.dart';
import 'package:smartexpense/screens/recent_income_screen.dart';
import 'package:smartexpense/widgets/fl_circular_expense_chart.dart';
import 'package:smartexpense/widgets/category_expense_list.dart';
import 'package:smartexpense/widgets/enhanced_yearly_charts_fixed.dart';
import 'package:smartexpense/widgets/month_picker.dart';
import 'package:smartexpense/widgets/loans_tab_content.dart';
import 'package:smartexpense/widgets/categories_tab_content.dart';
import 'package:smartexpense/screens/budgets_screen.dart';
import 'package:smartexpense/services/google_drive_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/services/budget_service.dart';
import 'package:smartexpense/widgets/budget_progress_card.dart';
import 'package:smartexpense/services/recurring_transaction_service.dart';
import 'package:smartexpense/screens/recurring_transactions_screen.dart';

import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/widgets/glass_container.dart';
import 'package:smartexpense/widgets/financial_radial_shield.dart';
import 'package:smartexpense/widgets/orbital_speed_dial.dart';
import 'package:smartexpense/widgets/smart_insights.dart';
import 'package:smartexpense/widgets/advanced_filter_dialog.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  TimeRange _selectedRange = TimeRange.monthly;
  DateTime _selectedDate = DateTime.now();
  bool _isSyncing = false;
  bool _isRefreshing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  Map<String, dynamic> _appliedFilters = {};

  Map<String, double> _getCategoryData(List<Expense> expenses) {
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _summaryAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _summarySlideAnimation;

  // Error handling
  String? _errorMessage;

  // Keep alive to maintain state when switching tabs

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _setupSearchListener();
    _checkForRecurringTransactions();
  }

  void _checkForRecurringTransactions() {
    final recurringTransactionService = context
        .read<RecurringTransactionService>();
    final expenseService = context.read<ExpenseService>();
    final incomeService = context.read<IncomeService>();
    recurringTransactionService.checkForRecurringTransactions(
      expenseService,
      incomeService,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    _summaryAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _summaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _summarySlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _summaryAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fabAnimationController.forward();
    _summaryAnimationController.forward();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
  }

  // Helper to combine expense and income streams
  Stream<Map<String, dynamic>> _getCombinedFinancialStream(
    ExpenseService expenseService,
    IncomeService incomeService,
  ) {
    return StreamZip([
      expenseService.getExpensesStream(
        _selectedRange,
        _selectedDate,
        filters: _appliedFilters,
      ),
      incomeService.getIncomesStream(
        _selectedRange,
        _selectedDate,
        filters: _appliedFilters,
      ),
    ]).map(
      (values) => {
        'expenses': values[0] as List<Expense>,
        'incomes': values[1] as List<Income>,
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge!.color!;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBodyWithErrorHandling(textColor),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBodyWithErrorHandling(Color textColor) {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildTimeRangeSelector(textColor),
        const SizedBox(height: 20),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _refreshData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          tooltip: 'Sync to Google Drive',
          onPressed: _isSyncing ? null : () => _syncToGoogleDrive(context),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        ),
        IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () async {
                  final filters = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => AdvancedFilterDialog(
                      onApplyFilter: (filters) {
                        setState(() {
                          _appliedFilters = filters;
                        });
                      },
                    ),
                  );
                  if (filters != null) {
                    setState(() {
                      _appliedFilters = filters;
                    });
                  }
                },
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onSubmitted: (_) => _searchFocusNode.unfocus(),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _buildFinancialOverview(),
    );
  }

  Widget _buildFinancialOverview() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _summarySlideAnimation,
            child: _buildSummaryCards(
              theme.cardColor,
              theme.textTheme.bodyLarge!.color!,
            ),
          ),
          const SizedBox(height: 20),
          SmartInsights(
            selectedRange: _selectedRange,
            selectedDate: _selectedDate,
          ),
          const SizedBox(height: 20),
          _buildBudgets(),
          const SizedBox(height: 20),
          _buildExpenseChart(
            theme.cardColor,
            theme.textTheme.bodyLarge!.color!,
          ),
          const SizedBox(height: 20),
          _buildRecentExpensesCard(
            theme.cardColor,
            theme.textTheme.bodyLarge!.color!,
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildBudgets() {
    return StreamBuilder<List<Budget>>(
      stream: context.watch<BudgetService>().getBudgetsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final budgets = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budgets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return BudgetProgressCard(budget: budget);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpensesCard(Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecentExpensesScreen(
              selectedDate: _selectedDate,
              selectedRange: _selectedRange,
            ),
          ),
        );
      },
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.red),
              const SizedBox(width: 16),
              Text('Recent Expenses', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: () {
          OrbitalSpeedDialOverlay.show(
            context,
            onAddIncome: () => _navigateToAddIncome(context),
            onAddExpense: () => _navigateToAddExpense(context),
            onAddLoan: () => _navigateToAddLoan(context),
          );
        },
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      height: 65,
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF1E293B).withAlpha(204) 
              : Colors.white.withAlpha(204),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withAlpha(20) 
                : Colors.black.withAlpha(13),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDarkMode ? 77 : 15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                      onPressed: () => _handleMenuSelection('settings'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.category),
                      tooltip: 'Categories',
                      onPressed: _showCategoriesDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.wallet),
                      tooltip: 'Budgets',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BudgetsScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 48), // Space for FAB
                    IconButton(
                      icon: const Icon(Icons.account_balance),
                      tooltip: 'Loans',
                      onPressed: _showLoansDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.import_export),
                      tooltip: 'Import/Export',
                      onPressed: _showImportExportDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.autorenew),
                      tooltip: 'Recurring',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecurringTransactionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTimeRangeSelector(Color textColor) {
    final theme = Theme.of(context);
    const ranges = [
      ('Daily', TimeRange.daily),
      ('Monthly', TimeRange.monthly),
      ('Yearly', TimeRange.yearly),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha(128),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ranges
            .map((range) => _buildRangeButton(range.$1, range.$2, textColor))
            .toList(),
      ),
    );
  }

  Widget _buildRangeButton(String label, TimeRange range, Color textColor) {
    final isSelected = _selectedRange == range;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedRange = range);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Color cardColor, Color textColor) {
    final expenseService = context.watch<ExpenseService>();
    final incomeService = context.watch<IncomeService>();
    final budgetService = context.watch<BudgetService>();

    return StreamBuilder<Map<String, dynamic>>(
      stream: _getCombinedFinancialStream(expenseService, incomeService),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final expenses = snapshot.data?['expenses'] as List<Expense>? ?? [];
        final incomes = snapshot.data?['incomes'] as List<Income>? ?? [];

        final filteredExpenses = _filterExpenses(expenses);
        final filteredIncomes = _filterIncomes(incomes);

        return FutureBuilder<double>(
          future: expenseService.calculateTotalInPrimaryCurrency(filteredExpenses),
          builder: (context, expenseSnapshot) {
            return FutureBuilder<double>(
              future: incomeService.calculateTotalInPrimaryCurrency(filteredIncomes),
              builder: (context, incomeSnapshot) {
                return StreamBuilder<List<Budget>>(
                  stream: budgetService.getBudgetsStream(),
                  builder: (context, budgetSnapshot) {
                    final totalExpenses = expenseSnapshot.data ?? 0.0;
                    final totalIncome = incomeSnapshot.data ?? 0.0;
                    
                    final budgets = budgetSnapshot.data ?? [];
                    final totalBudget = budgets.fold<double>(0.0, (sum, b) => sum + b.amount);

                    return Column(
                      children: [
                        FinancialRadialShield(
                          totalIncome: totalIncome,
                          totalExpenses: totalExpenses,
                          totalBudget: totalBudget > 0 ? totalBudget : 1000.0,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Expenses',
                                Provider.of<CurrencyService>(context, listen: false)
                                    .formatAmountWithDecimal(totalExpenses),
                                Icons.trending_down,
                                AppColors.error,
                                cardColor,
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecentExpensesScreen(
                                        selectedDate: _selectedDate,
                                        selectedRange: _selectedRange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                'Income',
                                Provider.of<CurrencyService>(context, listen: false)
                                    .formatAmountWithDecimal(totalIncome),
                                Icons.trending_up,
                                AppColors.success,
                                cardColor,
                                textColor,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecentIncomeScreen(
                                        selectedDate: _selectedDate,
                                        selectedRange: _selectedRange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }


  List<Income> _filterIncomes(List<Income> incomes) {
    List<Income> filteredIncomes = incomes;

    if (_searchQuery.isNotEmpty) {
      filteredIncomes = filteredIncomes
          .where(
            (income) =>
                income.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                income.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                income.notes?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ==
                    true,
          )
          .toList();
    }

    if (_appliedFilters.isNotEmpty) {
      if (_appliedFilters['startDate'] != null) {
        filteredIncomes = filteredIncomes
            .where(
              (income) => income.date.isAfter(
                (_appliedFilters['startDate'] as DateTime).subtract(
                  const Duration(days: 1),
                ),
              ),
            )
            .toList();
      }
      if (_appliedFilters['endDate'] != null) {
        filteredIncomes = filteredIncomes
            .where(
              (income) => income.date.isBefore(
                (_appliedFilters['endDate'] as DateTime).add(
                  const Duration(days: 1),
                ),
              ),
            )
            .toList();
      }
      if (_appliedFilters['categories'] != null &&
          (_appliedFilters['categories'] as List).isNotEmpty) {
        filteredIncomes = filteredIncomes
            .where(
              (income) => (_appliedFilters['categories'] as List).contains(
                income.category,
              ),
            )
            .toList();
      }
      if (_appliedFilters['minAmount'] != null) {
        filteredIncomes = filteredIncomes
            .where(
              (income) =>
                  income.amount >= (_appliedFilters['minAmount'] as double),
            )
            .toList();
      }
      if (_appliedFilters['maxAmount'] != null) {
        filteredIncomes = filteredIncomes
            .where(
              (income) =>
                  income.amount <= (_appliedFilters['maxAmount'] as double),
            )
            .toList();
      }
      if (_appliedFilters['tags'] != null &&
          (_appliedFilters['tags'] as List).isNotEmpty) {
        filteredIncomes = filteredIncomes
            .where(
              (income) => income.tags.any(
                (tag) => (_appliedFilters['tags'] as List).contains(tag),
              ),
            )
            .toList();
      }
    }

    return filteredIncomes;
  }




  List<Expense> _filterExpenses(List<Expense> expenses) {
    List<Expense> filteredExpenses = expenses;

    if (_searchQuery.isNotEmpty) {
      filteredExpenses = filteredExpenses
          .where(
            (expense) =>
                expense.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                expense.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                expense.notes?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ==
                    true,
          )
          .toList();
    }

    if (_appliedFilters.isNotEmpty) {
      if (_appliedFilters['startDate'] != null) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) => expense.date.isAfter(
                (_appliedFilters['startDate'] as DateTime).subtract(
                  const Duration(days: 1),
                ),
              ),
            )
            .toList();
      }
      if (_appliedFilters['endDate'] != null) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) => expense.date.isBefore(
                (_appliedFilters['endDate'] as DateTime).add(
                  const Duration(days: 1),
                ),
              ),
            )
            .toList();
      }
      if (_appliedFilters['categories'] != null &&
          (_appliedFilters['categories'] as List).isNotEmpty) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) => (_appliedFilters['categories'] as List).contains(
                expense.category,
              ),
            )
            .toList();
      }
      if (_appliedFilters['minAmount'] != null) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) =>
                  expense.amount >= (_appliedFilters['minAmount'] as double),
            )
            .toList();
      }
      if (_appliedFilters['maxAmount'] != null) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) =>
                  expense.amount <= (_appliedFilters['maxAmount'] as double),
            )
            .toList();
      }
      if (_appliedFilters['tags'] != null &&
          (_appliedFilters['tags'] as List).isNotEmpty) {
        filteredExpenses = filteredExpenses
            .where(
              (expense) => expense.tags.any(
                (tag) => (_appliedFilters['tags'] as List).contains(tag),
              ),
            )
            .toList();
      }
    }

    return filteredExpenses;
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final horizontalPadding = isCompact ? 12.0 : 20.0;
        final verticalPadding = isCompact ? 16.0 : 20.0;

        return GestureDetector(
          onTap: onTap,
          child: GlassContainer(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            color: cardColor,
            borderColor: color.withAlpha(40),
            shadows: [
              BoxShadow(
                color: color.withAlpha(20),
                spreadRadius: 0,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: isCompact ? 20 : 24),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: textColor.withAlpha(80),
                      size: isCompact ? 16 : 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor.withAlpha(150),
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Expense>> _convertExpensesToPrimary(
    List<Expense> expenses,
  ) async {
    final expenseService = context.read<ExpenseService>();
    final currencyService = context.read<CurrencyService>();
    final primaryCurrency = currencyService.primaryCurrency;

    return Future.wait(
      expenses.map((e) async {
        if (e.currency == primaryCurrency) return e;
        final convertedAmount = await expenseService
            .getExpenseInPrimaryCurrency(e);
        return Expense(
          id: e.id,
          title: e.title,
          amount: convertedAmount,
          date: e.date,
          category: e.category,
          notes: e.notes,
          currency: primaryCurrency,
          tags: e.tags,
        );
      }),
    );
  }

  Widget _buildExpenseChart(Color cardColor, Color textColor) {
    if (_selectedRange == TimeRange.yearly) {
      final expenseService = context.watch<ExpenseService>();
      final incomeService = context.watch<IncomeService>();

      return StreamBuilder<Map<String, dynamic>>(
        stream: _getCombinedFinancialStream(expenseService, incomeService),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildChartErrorState(cardColor, textColor);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildChartLoadingState(cardColor);
          }

          final expenses = snapshot.data?['expenses'] as List<Expense>? ?? [];
          final incomes = snapshot.data?['incomes'] as List<Income>? ?? [];

          final filteredExpenses = _filterExpenses(expenses);
          final filteredIncomes = _filterIncomes(incomes);

          return FutureBuilder<List<Expense>>(
            future: _convertExpensesToPrimary(filteredExpenses),
            builder: (context, convertedSnapshot) {
              if (!convertedSnapshot.hasData) {
                return _buildChartLoadingState(cardColor);
              }

              final convertedExpenses = convertedSnapshot.data!;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildDateSelector(cardColor, textColor),
                  ),
                  EnhancedYearlyCharts(
                    expenses: convertedExpenses,
                    incomes: filteredIncomes,
                    selectedYear: _selectedDate,
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return Consumer<ExpenseService>(
      builder: (context, expenseService, child) {
        return StreamBuilder<List<Expense>>(
          stream: expenseService.getExpensesStream(
            _selectedRange,
            _selectedDate,
            filters: _appliedFilters,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildChartErrorState(cardColor, textColor);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildChartLoadingState(cardColor);
            }

            final expenses = snapshot.data ?? [];
            final filteredExpenses = _filterExpenses(expenses);

            return FutureBuilder<List<Expense>>(
              future: _convertExpensesToPrimary(filteredExpenses),
              builder: (context, convertedSnapshot) {
                if (!convertedSnapshot.hasData) {
                  return _buildChartLoadingState(cardColor);
                }

                final convertedExpenses = convertedSnapshot.data!;
                final totalAmount = convertedExpenses.fold(
                  0.0,
                  (sum, e) => sum + e.amount,
                );

                return Column(
                  children: [
                    if (_selectedRange == TimeRange.monthly ||
                        _selectedRange == TimeRange.yearly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDateSelector(cardColor, textColor),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(25),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_getRangeTitle()} Overview',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.analytics_outlined,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              FlCircularExpenseChart(
                                categoryData: _getCategoryData(
                                  convertedExpenses,
                                ),
                                total: totalAmount,
                              ),
                              const SizedBox(height: 20),
                              CategoryExpenseList(
                                categoryData: _getCategoryData(
                                  convertedExpenses,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChartLoadingState(Color cardColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildChartErrorState(Color cardColor, Color textColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text('Chart data unavailable', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildDateSelector(Color cardColor, Color textColor) {
    if (_selectedRange == TimeRange.monthly) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MonthYearPicker(
          initialDate: _selectedDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      );
    } else if (_selectedRange == TimeRange.yearly) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Year',
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year - 1,
                    _selectedDate.month,
                    1,
                  );
                });
              },
            ),
            Text(
              _selectedDate.year.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Year',
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year + 1,
                    _selectedDate.month,
                    1,
                  );
                });
              },
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _handleError(String error) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      });
    }
  }

  String _getRangeTitle() {
    switch (_selectedRange) {
      case TimeRange.daily:
        return 'Daily';
      case TimeRange.weekly:
        return 'Weekly';
      case TimeRange.monthly:
        return 'Monthly';
      case TimeRange.yearly:
        return 'Yearly';
      case TimeRange.loans:
        return 'Loans';
      case TimeRange.categories:
        return 'Categories';
      case TimeRange.custom:
        return 'Custom';
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Simulate data refresh

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _errorMessage = null;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _handleError(e.toString());
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  void _navigateToAddIncome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
  }

  void _navigateToAddLoan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLoanScreen()),
    );
  }

  void _showCategoriesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Categories')),
          body: CategoriesTabContent(
            selectedDate: _selectedDate,
            selectedRange: _selectedRange,
          ),
        ),
      ),
    );
  }

  void _showLoansDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Loans')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: LoansTabContent(),
          ),
        ),
      ),
    );
  }

  void _showImportExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Import from CSV'),
                subtitle: const Text('Import expenses from CSV file'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Current Month'),
                subtitle: const Text('Export expenses for current month'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Export Any Month'),
                subtitle: const Text('Export expenses for any month'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExportAnyMonth();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Export Year'),
                subtitle: const Text('Export expenses for any year'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExportYear();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Download Template'),
                subtitle: const Text('Get sample CSV templates'),
                onTap: () {
                  Navigator.pop(context);
                  _handleDownloadTemplate();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      if (!mounted) return;

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();

      if (!mounted) return;

      final rows = Csv().decode(csvString);
      if (rows.isEmpty) {
        _showSnackBar('The selected file is empty.', Colors.orange);
        return;
      }

      final expenseService = context.read<ExpenseService>();
      final categorizer = context.read<CategorizerService>();

      await _showLoadingDialog();
      int successCount = 0;
      int failCount = 0;

      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final title = row[0].toString();
          final amount = double.parse(row[1].toString());
          final date = DateTime.parse(row[2].toString());
          final category = row[3].toString();

          // Auto-categorize if category is not provided or 'Uncategorized'
          String finalCategory = category;
          if (finalCategory.isEmpty ||
              finalCategory.toLowerCase() == 'uncategorized') {
            finalCategory = categorizer.categorizeExpense(title);
          }

          final expense = Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            title: title,
            amount: amount,
            date: date,
            category: finalCategory,
          );
          await expenseService.addExpense(expense);
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('Error importing row $i: $e');
        }
      }

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Import complete: $successCount succeeded, $failCount failed.',
          Colors.blue,
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Import failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExport() async {
    try {
      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();

      await _showLoadingDialog();

      final now = DateTime.now();
      final expenses = await expenseService
          .getExpensesStream(TimeRange.monthly, now)
          .firstOrDefault([]);

      if (expenses.isEmpty) {
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar(
            'No expenses found for the current month',
            Colors.orange,
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(['ID', 'Title', 'Amount', 'Date', 'Category']);
      for (var expense in expenses) {
        rows.add([
          expense.id,
          expense.title,
          expense.amount,
          expense.date.toIso8601String(),
          expense.category,
        ]);
      }

      String csvData = Csv().encode(rows);

      final directory = await getDownloadsDirectory();
      final path = directory!.path;
      final file = File('$path/expenses_${now.year}-${now.month}.csv');
      await file.writeAsString(csvData);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Exported to ${file.path}',
          Colors.green,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExportAnyMonth() async {
    try {
      if (!mounted) return;

      // Show month picker dialog
      final selectedMonth = await _showMonthPickerDialog();
      if (selectedMonth == null) return;

      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();

      await _showLoadingDialog();
      final expenses = await expenseService
          .getExpensesStream(TimeRange.monthly, selectedMonth)
          .firstOrDefault([]);

      if (expenses.isEmpty) {
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar(
            'No expenses found for the selected month',
            Colors.orange,
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(['ID', 'Title', 'Amount', 'Date', 'Category']);
      for (var expense in expenses) {
        rows.add([
          expense.id,
          expense.title,
          expense.amount,
          expense.date.toIso8601String(),
          expense.category,
        ]);
      }

      String csvData = Csv().encode(rows);

      final directory = await getDownloadsDirectory();
      final path = directory!.path;
      final file = File(
        '$path/expenses_${selectedMonth.year}-${selectedMonth.month}.csv',
      );
      await file.writeAsString(csvData);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Exported to ${file.path}',
          Colors.green,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleExportYear() async {
    try {
      if (!mounted) return;

      // Show year picker dialog
      final selectedYear = await _showYearPickerDialog();
      if (selectedYear == null) return;

      if (!mounted) return;
      final expenseService = context.read<ExpenseService>();

      await _showLoadingDialog();
      final yearDate = DateTime(selectedYear, 1, 1);
      final expenses = await expenseService
          .getExpensesStream(TimeRange.yearly, yearDate)
          .firstOrDefault([]);

      if (expenses.isEmpty) {
        if (mounted) {
          _hideLoadingDialog();
          _showSnackBar(
            'No expenses found for the selected year',
            Colors.orange,
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(['ID', 'Title', 'Amount', 'Date', 'Category']);
      for (var expense in expenses) {
        rows.add([
          expense.id,
          expense.title,
          expense.amount,
          expense.date.toIso8601String(),
          expense.category,
        ]);
      }

      String csvData = Csv().encode(rows);

      final directory = await getDownloadsDirectory();
      final path = directory!.path;
      final file = File('$path/expenses_$selectedYear.csv');
      await file.writeAsString(csvData);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Exported to ${file.path}',
          Colors.green,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Export failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _handleDownloadTemplate() async {
    try {
      if (!mounted) return;

      await _showLoadingDialog();

      List<List<dynamic>> rows = [];
      rows.add(['Title', 'Amount', 'Date (YYYY-MM-DD)', 'Category']);

      String csvData = Csv().encode(rows);

      final directory = await getDownloadsDirectory();
      final path = directory!.path;
      final file = File('$path/expense_template.csv');
      await file.writeAsString(csvData);

      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar(
          'Template saved to ${file.path}',
          Colors.green,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showSnackBar('Template download failed: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<DateTime?> _showMonthPickerDialog() async {
    if (!mounted) return null;

    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month);

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Month to Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed:
                        selectedDate.isBefore(DateTime(now.year, now.month))
                        ? () {
                            setState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month + 1,
                              );
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select any month up to ${_getMonthName(now.month)} ${now.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedDate),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  Future<int?> _showYearPickerDialog() async {
    if (!mounted) return null;

    final now = DateTime.now();
    int selectedYear = now.year;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Year to Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text(
                    selectedYear.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedYear < now.year
                        ? () {
                            setState(() {
                              selectedYear++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select any year up to ${now.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (selectedYear == now.year)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Note: This will export all expenses for $selectedYear (including partial year)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedYear),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _showSnackBar(
    String message,
    Color backgroundColor, {
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  Future<void> _showLoadingDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please wait...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _syncToGoogleDrive(BuildContext context) async {
    setState(() => _isSyncing = true);

    final googleDriveService = Provider.of<GoogleDriveService>(
      context,
      listen: false,
    );

    try {
      final success = await googleDriveService.backupAllData();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                success
                    ? 'Successfully synced to Google Drive!'
                    : 'Failed to sync.',
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Sync error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _handleMenuSelection(String selection) {
    switch (selection) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      default:
        break;
    }
  }
}
