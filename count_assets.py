#!/usr/bin/env python3

# Count the assets from the Dart file
with open('lib/services/enhanced_market_data_service.dart', 'r') as f:
    content = f.read()

# Extract stocks list
stocks_start = content.find('static const List<String> _essentialStocks = [')
stocks_end = content.find('];', stocks_start)
stocks_section = content[stocks_start:stocks_end]

# Extract cryptos list  
cryptos_start = content.find('static const List<String> _essentialCryptos = [')
cryptos_end = content.find('];', cryptos_start)
cryptos_section = content[cryptos_start:cryptos_end]

# Count single quotes within each section (each asset has 2 quotes)
stocks_count = stocks_section.count("'") // 2
cryptos_count = cryptos_section.count("'") // 2

print(f"📈 Stocks/ETFs: {stocks_count}")
print(f"🪙 Cryptocurrencies: {cryptos_count}")
print(f"📊 Total Assets: {stocks_count + cryptos_count}")