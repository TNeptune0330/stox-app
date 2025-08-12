# YFinance API Backend for Stox

A simple Flask backend that provides Yahoo Finance data using the yfinance library.

## 🚀 Quick Deploy

### Option 1: Render (Recommended)
1. Create account at [render.com](https://render.com)
2. Connect your GitHub repo
3. Create new Web Service
4. Use these settings:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python app.py`
   - **Environment**: Python 3

### Option 2: Railway
1. Create account at [railway.app](https://railway.app)
2. Deploy from GitHub
3. Will auto-detect Python and install dependencies

### Option 3: Local Development
```bash
cd yfinance_backend
pip install -r requirements.txt
python app.py
```

## 📊 API Endpoints

### Current Price
```
GET /price?ticker=AAPL
```
Response:
```json
{
  "symbol": "AAPL",
  "price": 175.43,
  "change": 2.15,
  "change_percent": 1.24,
  "timestamp": "2024-01-15T10:30:00"
}
```

### Historical Data
```
GET /historical?ticker=AAPL&period=1mo&interval=1d
```

### Company Info
```
GET /info?ticker=AAPL
```

### Batch Prices
```
GET /batch?tickers=AAPL,GOOGL,MSFT
```

## 🔧 Flutter Integration

Update your `EnhancedMarketDataService` to use this backend:

```dart
// Add to your API endpoints
static const String _yfinanceApiUrl = 'https://your-backend.render.com';

static Future<bool> _updateStockFromYFinance(String symbol) async {
  try {
    final response = await http.get(
      Uri.parse('$_yfinanceApiUrl/price?ticker=$symbol'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Process the data...
      return true;
    }
    return false;
  } catch (e) {
    print('YFinance API error for $symbol: $e');
    return false;
  }
}
```

## 🛡️ Rate Limiting

- 100 requests per minute per IP
- Automatic cleanup of old requests
- Returns 429 status for exceeded limits

## 📈 Features

- ✅ Real-time stock prices
- ✅ Historical data with flexible periods
- ✅ Company information and fundamentals  
- ✅ Stock search functionality
- ✅ Batch price requests
- ✅ Rate limiting protection
- ✅ CORS enabled for Flutter
- ✅ Error handling and fallbacks

## 🔒 Production Notes

- Add proper authentication if needed
- Consider Redis for rate limiting
- Add logging and monitoring
- Use environment variables for configuration
- Add database caching for frequently requested data