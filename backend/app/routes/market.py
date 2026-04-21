from fastapi import APIRouter, HTTPException
import yfinance as yf
import pandas as pd
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import time

router = APIRouter(prefix="/api/market", tags=["market"])


class MarketDataResponse(BaseModel):
    symbol: str
    name: str
    price: float
    change: float
    change_percent: float
    high: float
    low: float
    volume: int
    timestamp: datetime


@router.get("/{symbol}", response_model=MarketDataResponse)
async def get_market_data(symbol: str):
    for attempt in range(3):
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period="5d", auto_adjust=True, timeout=10)
            
            if not hist.empty:
                current = hist.iloc[-1]
                prev_close = hist.iloc[-2]["Close"] if len(hist) > 1 else current["Close"]
                
                try:
                    info = ticker.fast_info
                    name = info.short_name or info.long_name or symbol
                except:
                    name = symbol
                
                change = float(current["Close"]) - float(prev_close)
                change_percent = (change / float(prev_close) * 100) if prev_close else 0
                
                return {
                    "symbol": symbol.upper(),
                    "name": name,
                    "price": float(current["Close"]),
                    "change": float(change),
                    "change_percent": float(change_percent),
                    "high": float(current["High"]),
                    "low": float(current["Low"]),
                    "volume": int(current["Volume"]) if "Volume" in current else 0,
                    "timestamp": datetime.now()
                }
            
            if attempt < 2:
                time.sleep(2)
        except Exception as e:
            if attempt == 2:
                raise HTTPException(status_code=503, detail=f"Yahoo Finance unavailable: {str(e)}")
            time.sleep(2)
    
    raise HTTPException(status_code=404, detail=f"No data found for {symbol}. Try again later.")


@router.get("/history/{symbol}")
async def get_market_history(symbol: str, period: str = "1mo"):
    valid_periods = ["1d", "5d", "1wk", "1mo", "3mo", "6mo", "1y", "2y", "5y"]
    if period not in valid_periods:
        period = "1mo"
    
    for attempt in range(3):
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period=period, auto_adjust=True, timeout=15)
            
            if not hist.empty:
                return {
                    "symbol": symbol.upper(),
                    "data": [
                        {
                            "date": str(index.date()),
                            "open": float(row["Open"]),
                            "high": float(row["High"]),
                            "low": float(row["Low"]),
                            "close": float(row["Close"]),
                            "volume": int(row["Volume"]) if "Volume" in row and not pd.isna(row["Volume"]) else 0
                        }
                        for index, row in hist.iterrows()
                    ]
                }
            
            if attempt < 2:
                time.sleep(2)
        except Exception as e:
            if attempt == 2:
                raise HTTPException(status_code=503, detail=f"Yahoo Finance unavailable: {str(e)}")
            time.sleep(2)
    
    raise HTTPException(status_code=404, detail=f"No data found for {symbol}. Try again later.")