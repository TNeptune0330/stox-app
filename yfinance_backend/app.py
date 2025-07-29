#!/usr/bin/env python3
"""
YFinance API Backend for Stox Trading Simulator
================================================
A simple Flask backend that provides Yahoo Finance data via yfinance library.
Deploy this on Render, Railway, or AWS Lambda for reliable stock data.

Usage:
- /price?ticker=AAPL - Get current price
- /historical?ticker=AAPL&period=1mo - Get historical data
- /info?ticker=AAPL - Get company info
- /search?query=apple - Search for stocks
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
import os

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests from Flutter

# Rate limiting (simple in-memory store)
from collections import defaultdict
import time

request_times = defaultdict(list)
RATE_LIMIT = 100  # requests per minute
RATE_WINDOW = 60  # seconds

def is_rate_limited(client_ip):
    """Simple rate limiting"""
    now = time.time()
    # Clean old requests
    request_times[client_ip] = [req_time for req_time in request_times[client_ip] 
                               if now - req_time < RATE_WINDOW]
    
    if len(request_times[client_ip]) >= RATE_LIMIT:
        return True
    
    request_times[client_ip].append(now)
    return False

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "yfinance-api",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/price')
def get_price():
    """Get current stock price"""
    if is_rate_limited(request.remote_addr):
        return jsonify({"error": "Rate limit exceeded"}), 429
    
    ticker = request.args.get('ticker', '').upper()
    if not ticker:
        return jsonify({"error": "Ticker parameter required"}), 400
    
    try:
        stock = yf.Ticker(ticker)
        info = stock.info
        
        if not info or 'regularMarketPrice' not in info:
            # Fallback to history if info fails
            hist = stock.history(period="1d")
            if hist.empty:
                return jsonify({"error": f"No data found for ticker {ticker}"}), 404
            
            price = hist['Close'].iloc[-1]
            prev_close = hist['Close'].iloc[-2] if len(hist) > 1 else price
        else:
            price = info.get('regularMarketPrice', 0)
            prev_close = info.get('previousClose', price)
        
        change = price - prev_close
        change_percent = (change / prev_close * 100) if prev_close != 0 else 0
        
        return jsonify({
            "symbol": ticker,
            "price": round(price, 2),
            "change": round(change, 2),
            "change_percent": round(change_percent, 2),
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/historical')
def get_historical():
    """Get historical stock data"""
    if is_rate_limited(request.remote_addr):
        return jsonify({"error": "Rate limit exceeded"}), 429
        
    ticker = request.args.get('ticker', '').upper()
    period = request.args.get('period', '1mo')  # 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max
    interval = request.args.get('interval', '1d')  # 1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo
    
    if not ticker:
        return jsonify({"error": "Ticker parameter required"}), 400
    
    try:
        stock = yf.Ticker(ticker)
        hist = stock.history(period=period, interval=interval)
        
        if hist.empty:
            return jsonify({"error": f"No historical data found for {ticker}"}), 404
        
        # Convert to list of dictionaries
        data = []
        for date, row in hist.iterrows():
            data.append({
                "date": date.isoformat(),
                "open": round(row['Open'], 2),
                "high": round(row['High'], 2),
                "low": round(row['Low'], 2),
                "close": round(row['Close'], 2),
                "volume": int(row['Volume'])
            })
        
        return jsonify({
            "symbol": ticker,
            "period": period,
            "interval": interval,
            "data": data,
            "count": len(data)
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/info')
def get_stock_info():
    """Get detailed stock information"""
    if is_rate_limited(request.remote_addr):
        return jsonify({"error": "Rate limit exceeded"}), 429
        
    ticker = request.args.get('ticker', '').upper()
    if not ticker:
        return jsonify({"error": "Ticker parameter required"}), 400
    
    try:
        stock = yf.Ticker(ticker)
        info = stock.info
        
        if not info:
            return jsonify({"error": f"No information found for {ticker}"}), 404
        
        # Extract key information
        result = {
            "symbol": ticker,
            "name": info.get('longName', info.get('shortName', ticker)),
            "sector": info.get('sector'),
            "industry": info.get('industry'),
            "description": info.get('longBusinessSummary', ''),
            "market_cap": info.get('marketCap'),
            "pe_ratio": info.get('trailingPE'),
            "dividend_yield": info.get('dividendYield'),
            "52_week_high": info.get('fiftyTwoWeekHigh'),
            "52_week_low": info.get('fiftyTwoWeekLow'),
            "volume": info.get('volume'),
            "avg_volume": info.get('averageVolume'),
            "beta": info.get('beta'),
            "eps": info.get('trailingEps'),
            "currency": info.get('currency'),
            "exchange": info.get('exchange'),
            "website": info.get('website')
        }
        
        # Remove None values
        result = {k: v for k, v in result.items() if v is not None}
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/search')
def search_stocks():
    """Search for stocks by name or ticker"""
    if is_rate_limited(request.remote_addr):
        return jsonify({"error": "Rate limit exceeded"}), 429
        
    query = request.args.get('query', '').strip()
    if not query:
        return jsonify({"error": "Query parameter required"}), 400
    
    try:
        # Simple search using yfinance (limited functionality)
        # In production, you might want to use a proper search API
        
        # Try as direct ticker first
        stock = yf.Ticker(query.upper())
        info = stock.info
        
        results = []
        if info and info.get('longName'):
            results.append({
                "symbol": query.upper(),
                "name": info.get('longName', ''),
                "type": info.get('quoteType', 'EQUITY'),
                "exchange": info.get('exchange', ''),
                "currency": info.get('currency', 'USD')
            })
        
        return jsonify({
            "query": query,
            "results": results,
            "count": len(results)
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/batch')
def get_batch_prices():
    """Get prices for multiple tickers at once"""
    if is_rate_limited(request.remote_addr):
        return jsonify({"error": "Rate limit exceeded"}), 429
        
    tickers_param = request.args.get('tickers', '')
    if not tickers_param:
        return jsonify({"error": "Tickers parameter required (comma-separated)"}), 400
    
    tickers = [t.strip().upper() for t in tickers_param.split(',')]
    
    if len(tickers) > 50:  # Limit batch size
        return jsonify({"error": "Maximum 50 tickers per batch"}), 400
    
    try:
        results = {}
        
        for ticker in tickers:
            try:
                stock = yf.Ticker(ticker)
                hist = stock.history(period="1d")
                
                if not hist.empty:
                    price = hist['Close'].iloc[-1]
                    prev_close = hist['Close'].iloc[-2] if len(hist) > 1 else price
                    change = price - prev_close
                    change_percent = (change / prev_close * 100) if prev_close != 0 else 0
                    
                    results[ticker] = {
                        "price": round(price, 2),
                        "change": round(change, 2),
                        "change_percent": round(change_percent, 2)
                    }
                else:
                    results[ticker] = {"error": "No data available"}
                    
            except Exception as e:
                results[ticker] = {"error": str(e)}
        
        return jsonify({
            "results": results,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    print(f"🚀 YFinance API Server starting on port {port}")
    print(f"📊 Available endpoints:")
    print(f"   GET /health - Health check")
    print(f"   GET /price?ticker=AAPL - Current price")
    print(f"   GET /historical?ticker=AAPL&period=1mo - Historical data")
    print(f"   GET /info?ticker=AAPL - Company information")
    print(f"   GET /search?query=apple - Search stocks")
    print(f"   GET /batch?tickers=AAPL,GOOGL,MSFT - Batch prices")
    
    app.run(host='0.0.0.0', port=port, debug=debug)