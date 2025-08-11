import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../main_navigation.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<PortfolioProvider>(context, listen: false)
            .loadTransactions(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Transaction History'),
            backgroundColor: ModernTheme.backgroundCard,
            foregroundColor: ModernTheme.textPrimary,
          ),
          
          Consumer<PortfolioProvider>(
            builder: (context, portfolioProvider, child) {
              if (portfolioProvider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.accentBlue),
                    ),
                  ),
                );
              }

              if (portfolioProvider.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ModernTheme.accentRed,
                        ),
                        const SizedBox(height: 16),
                        Text(portfolioProvider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.user != null) {
                              portfolioProvider.loadTransactions(authProvider.user!.id);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (portfolioProvider.transactions.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'No Transactions',
                    message: 'Your trading history will appear here',
                    icon: Icons.receipt_long,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = portfolioProvider.transactions[index];
                    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transaction.isBuy ? Colors.green : Colors.red,
                          child: Icon(
                            transaction.isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${transaction.isBuy ? 'Buy' : 'Sell'} ${transaction.symbol}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${transaction.quantity} shares @ ${transaction.formattedPrice}',
                            ),
                            Text(
                              dateFormat.format(transaction.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Text(
                          transaction.formattedTotal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: transaction.isBuy ? Colors.red : Colors.green,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                  childCount: portfolioProvider.transactions.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}