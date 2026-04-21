from fastapi import APIRouter, HTTPException
import yfinance as yf
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

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
    try:
        ticker = yf.Ticker(symbol)
        info = ticker.info or {}
        
        hist = ticker.history(period="1d")
        if hist.empty:
            raise HTTPException(status_code=404, detail=f"No data found for {symbol}")
        
        current = hist.iloc[-1]
        prev_close = info.get("previousClose") or current["Close"]
        change = float(current["Close"]) - float(prev_close)
        change_percent = (change / float(prev_close) * 100) if prev_close else 0
        
        return {
            "symbol": symbol.upper(),
            "name": info.get("shortName", symbol),
            "price": float(current["Close"]),
            "change": float(change),
            "change_percent": float(change_percent),
            "high": float(current["High"]),
            "low": float(current["Low"]),
            "volume": int(current["Volume"]),
            "timestamp": datetime.now()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history/{symbol}")
async def get_market_history(symbol: str, period: str = "1mo"):
    try:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period=period)
        
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
                    "volume": int(row["Volume"])
                }
                for index, row in hist.iterrows()
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
