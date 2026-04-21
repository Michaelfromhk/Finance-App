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


def safe_get_ticker_data(symbol: str):
    try:
        ticker = yf.Ticker(symbol)
        
        try:
            hist = ticker.history(period="1d", auto_adjust=True)
        except Exception as e:
            hist = None
            
        try:
            info = ticker.info or {}
        except Exception as e:
            info = {}
        
        if hist is None or hist.empty:
            hist = yf.download(symbol, period="1d", auto_adjust=True, progress=False)
        
        return hist, info
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch data for {symbol}: {str(e)}")


@router.get("/{symbol}", response_model=MarketDataResponse)
async def get_market_data(symbol: str):
    try:
        ticker = yf.Ticker(symbol)
        
        hist = ticker.history(period="5d", auto_adjust=True)
        
        if hist.empty:
            hist = yf.download(symbol, period="5d", auto_adjust=True, progress=False)
        
        if hist.empty:
            raise HTTPException(status_code=404, detail=f"No data found for {symbol}")
        
        current = hist.iloc[-1]
        
        try:
            info = ticker.info
            name = info.get("shortName", info.get("longName", symbol))
            prev_close = info.get("previousClose") or hist.iloc[-2]["Close"] if len(hist) > 1 else current["Close"]
        except:
            name = symbol
            prev_close = hist.iloc[-2]["Close"] if len(hist) > 1 else current["Close"]
        
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history/{symbol}")
async def get_market_history(symbol: str, period: str = "1mo"):
    try:
        valid_periods = ["1d", "5d", "1wk", "1mo", "3mo", "6mo", "1y", "2y", "5y"]
        if period not in valid_periods:
            period = "1mo"
        
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period=period, auto_adjust=True)
        
        if hist.empty:
            hist = yf.download(symbol, period=period, auto_adjust=True, progress=False)
        
        if hist.empty:
            raise HTTPException(status_code=404, detail=f"No data found for {symbol}")
        
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))