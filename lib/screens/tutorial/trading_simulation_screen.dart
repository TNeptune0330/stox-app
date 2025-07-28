import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/market_asset_model.dart';

class TradingSimulationScreen extends StatefulWidget {
  const TradingSimulationScreen({super.key});

  @override
  State<TradingSimulationScreen> createState() => _TradingSimulationScreenState();
}

class _TradingSimulationScreenState extends State<TradingSimulationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  double _cashBalance = 100000.0;
  int _appleShares = 0;
  double _applePrice = 175.50;
  bool _isTrading = false;
  
  final List<SimulationStep> _steps = [
    SimulationStep(
      title: 'Let\'s Practice Trading!',
      description: 'We\'ll practice buying Apple (AAPL) stock. You start with \$100,000 virtual cash.',
      action: 'Start',
    ),
    SimulationStep(
      title: 'Step 1: Research the Stock',
      description: 'Apple (AAPL) is currently trading at \$175.50. It\'s a technology company that makes iPhones, iPads, and Macs.',
      action: 'Got it',
    ),
    SimulationStep(
      title: 'Step 2: Decide How Much to Buy',
      description: 'Let\'s buy 10 shares of Apple. This will cost: 10 × \$175.50 = \$1,755.00',
      action: 'Buy 10 Shares',
    ),
    SimulationStep(
      title: 'Trade Executed!',
      description: 'Congratulations! You now own 10 shares of Apple. Your cash balance decreased by \$1,755.',
      action: 'Continue',
    ),
    SimulationStep(
      title: 'Stock Price Changed!',
      description: 'Great news! Apple\'s price went up to \$180.25. Your 10 shares are now worth \$1,802.50. You made a \$47.50 profit!',
      action: 'Amazing!',
    ),
    SimulationStep(
      title: 'Step 3: When to Sell',
      description: 'You can sell anytime. Let\'s sell 5 shares to take some profit: 5 × \$180.25 = \$901.25',
      action: 'Sell 5 Shares',
    ),
    SimulationStep(
      title: 'Profit Realized!',
      description: 'You sold 5 shares for \$901.25 and still own 5 shares. Total profit on this trade: \$23.75!',
      action: 'Finish Tutorial',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _isTrading = true;
      });

      // Simulate trade execution
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          if (_currentStep == 2) {
            // Buy 10 shares
            _cashBalance -= 1755.0;
            _appleShares = 10;
          } else if (_currentStep == 4) {
            // Price increase
            _applePrice = 180.25;
          } else if (_currentStep == 5) {
            // Sell 5 shares
            _cashBalance += 901.25;
            _appleShares = 5;
          }
          
          _currentStep++;
          _isTrading = false;
        });
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final currentStep = _steps[_currentStep];
        
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            title: const Text('Trading Tutorial'),
            backgroundColor: themeProvider.background,
            foregroundColor: themeProvider.contrast,
            elevation: 0,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: themeProvider.theme.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Portfolio summary
                  _buildPortfolioCard(themeProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Apple stock card
                  _buildStockCard(themeProvider),
                  
                  const SizedBox(height: 32),
                  
                  // Instruction card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.theme.withOpacity(0.1),
                            themeProvider.themeHigh.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.theme.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school,
                            size: 48,
                            color: themeProvider.theme,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentStep.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.contrast,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentStep.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.contrast.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isTrading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.theme,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isTrading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              currentStep.action,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCard(ThemeProvider themeProvider) {
    final portfolioValue = _cashBalance + (_appleShares * _applePrice);
    final totalGainLoss = portfolioValue - 100000.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.theme.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Portfolio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Balance',
                    style: TextStyle(
                      color: themeProvider.contrast.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '\$${_cashBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      color: themeProvider.contrast.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '\$${portfolioValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (totalGainLoss != 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: totalGainLoss >= 0
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${totalGainLoss >= 0 ? '+' : ''}\$${totalGainLoss.toStringAsFixed(2)}',
                style: TextStyle(
                  color: totalGainLoss >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockCard(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.theme.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeProvider.theme.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.smartphone,
              color: themeProvider.theme,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apple Inc.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.contrast,
                  ),
                ),
                Text(
                  'AAPL',
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_applePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.contrast,
                ),
              ),
              if (_appleShares > 0)
                Text(
                  'Shares: $_appleShares',
                  style: TextStyle(
                    color: themeProvider.theme,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SimulationStep {
  final String title;
  final String description;
  final String action;

  SimulationStep({
    required this.title,
    required this.description,
    required this.action,
  });
}