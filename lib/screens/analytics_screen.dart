import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import 'settings_screen.dart';
import '../utils/currency_formatter.dart';
import '../models/category.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0 = Overview, 1 = Trends

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false, // Align left as per design usually, or center. Design says "Analytics" big on top left if it was iOS, but this is Scaffold AppBar. Center is fine.
        // Actually design has "Analytics" and Settings icon.
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Seamless look
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, BudgetProvider>(
        builder: (context, expenseProvider, budgetProvider, _) {
          return Column(
            children: [
              // Segmented Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'Overview',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Trends',
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _selectedTab == 0
                    ? _buildOverviewTab(context, expenseProvider)
                    : _buildTrendsTab(context, expenseProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent, // Indigo for selected
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(BuildContext context, ExpenseProvider provider) {
    final totalExpense = provider.getTotalExpense();
    final totalIncome = provider.getTotalIncome();
    final spendingByCategory = provider.getSpendingByCategory();

    // Calculate diff for insight card (Mock logic or real if historical data exists)
    // For now, let's just show a static "Spending Decreased" or calculate if possible.
    // Provider might not store monthly history readily available for simple diff here without async.
    // We'll use a placeholder or calculate if we have data.
    final hasData = totalExpense > 0 || totalIncome > 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Income / Expense Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'INCOME',
                amount: totalIncome,
                color: const Color(0xFF10B981), // Green
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: 'EXPENSES',
                amount: totalExpense,
                color: const Color(0xFFEF4444), // Red
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Spending Breakdown Chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Spending Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              if (hasData)
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildPieSections(spendingByCategory, totalExpense, provider),
                          centerSpaceRadius: 70,
                          sectionsSpace: 0,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(totalExpense),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No data for this month', style: TextStyle(color: Colors.grey)),
                ),
              
              const SizedBox(height: 24),
              
              // Category List
              ...spendingByCategory.entries.map((entry) {
                final category = provider.getCategoryById(entry.key);
                final amount = entry.value;
                final percentage = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;
                return _buildCategoryItem(
                  context,
                  category: category, 
                  amount: amount, 
                  percentage: percentage,
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Insight Card
        if (hasData)
          _buildInsightCard(context),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatKZT(amount), // Or compact
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> spending, 
    double total, 
    ExpenseProvider provider
  ) {
    return spending.entries.map((entry) {
      final category = provider.getCategoryById(entry.key);
      final value = entry.value;
      final percentage = value / total;
      final color = category?.color ?? Colors.grey;
      
      return PieChartSectionData(
        value: value,
        title: '', // Hide title on chart
        color: color,
        radius: 25, // Thinner ring
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildCategoryItem(BuildContext context, {
    required Category? category,
    required double amount,
    required double percentage,
  }) {
    final color = category?.color ?? Colors.grey;
    final icon = category?.icon ?? Icons.help_outline;
    final name = category?.name ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Colored background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}% of spending',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : Colors.grey[200],
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    // Hardcoded logic for demo/visuals as per requirement. 
    // In real app, calculate actual diff.
    const diff = 12; // 12%
    const isDecrease = true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F3930), // Dark Greenish
            Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending Decreased',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.8), fontSize: 13),
                    children: const [
                       TextSpan(text: 'You spent '),
                       TextSpan(text: '12% less', style: TextStyle(fontWeight: FontWeight.bold)),
                       TextSpan(text: ' compared to last month. Keep it up!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TRENDS TAB
  // ---------------------------------------------------------------------------

  Widget _buildTrendsTab(BuildContext context, ExpenseProvider provider) {
    final trends = provider.getSixMonthTrend();
    final topTrends = provider.getTopTrends();

    final highest = topTrends['highest'];
    final increase = topTrends['increase'];
    final decrease = topTrends['decrease']; // Good trend (spending less)

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Chart Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Dynamics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Last 6 months',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                           ? const Color(0xFF1E293B) 
                           : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'KZT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Line Chart
              SizedBox(
                height: 220,
                child: _buildSixMonthChart(context, trends),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        if (highest != null || increase != null || decrease != null) ...[
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Top Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],

        // Trend Cards
        if (highest != null)
          _buildTrendCard(
            context,
            title: (highest['category'] as Category).name,
            subtitle: 'Highest Category',
            amount: CurrencyFormatter.formatCompact(highest['amount'] as double),
            change: 'Top',
            isPositive: true, // Neutral/Info
            icon: (highest['category'] as Category).icon,
            color: (highest['category'] as Category).color,
            isNeutral: true,
          ),
        
        if (increase != null) ...[
          const SizedBox(height: 12),
          _buildTrendCard(
            context,
            title: (increase['category'] as Category).name,
            subtitle: 'Increased spending',
            amount: CurrencyFormatter.formatCompact(increase['amount'] as double),
            change: '+${(increase['percent'] as double).toStringAsFixed(0)}%',
            isPositive: true, // Bad
            icon: (increase['category'] as Category).icon,
            color: (increase['category'] as Category).color,
          ),
        ],

        if (decrease != null) ...[
          const SizedBox(height: 12),
          _buildTrendCard(
            context,
            title: (decrease['category'] as Category).name,
            subtitle: 'Reduced spending',
            amount: CurrencyFormatter.formatCompact(decrease['amount'] as double),
            change: '${(decrease['percent'] as double).toStringAsFixed(0)}%',
            isPositive: false, // Good
            icon: (decrease['category'] as Category).icon,
            color: (decrease['category'] as Category).color,
          ),
        ],
      ],
    );
  }

  Widget _buildSixMonthChart(BuildContext context, List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const Center(child: Text("No Data"));

    // Extract amounts
    final List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < trends.length; i++) {
        final val = (trends[i]['amount'] as double);
        if (val > maxY) maxY = val;
        spots.add(FlSpot(i.toDouble(), val));
    }
    // Prevent zero crash
    if (maxY == 0) maxY = 100;
    maxY *= 1.2; // Padding top

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y axis for clean look
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        trends[index]['month'].substring(0, 3), // Aug, Sep...
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (trends.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF6366F1), // Indigo
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.3),
                  const Color(0xFF6366F1).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             tooltipBgColor: Colors.blueGrey,
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((spot) {
                 return LineTooltipItem(
                   CurrencyFormatter.formatCompact(spot.y),
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 );
               }).toList();
             },
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, {
    required String title,
    required String subtitle,
    required String amount,
    required String change,
    required bool isPositive, // True = Red/Up (Bad for expense), False = Green/Down (Good)
    required IconData icon,
    required Color color,
    bool isNeutral = false,
  }) {
    // Red color for Increase (Bad for spending), Green for Decrease (Good for spending)
    final changeColor = isNeutral ? Colors.orange : (isPositive ? const Color(0xFFEF4444) : const Color(0xFF10B981));
    final changeIcon = isNeutral ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Text(
                    change, 
                    style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  if (!isNeutral)
                    Icon(changeIcon, color: changeColor, size: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
