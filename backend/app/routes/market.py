from fastapi import APIRouter
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
    ticker = yf.Ticker(symbol)
    info = ticker.info if ticker.info else {}
    
    hist = ticker.history(period="1d")
    if hist.empty:
        return {"error": "No data found"}
    
    current = hist.iloc[-1]
    prev_close = info.get("previousClose", current["Close"])
    change = current["Close"] - prev_close
    change_percent = (change / prev_close * 100) if prev_close else 0
    
    return {
        "symbol": symbol.upper(),
        "name": info.get("shortName", symbol),
        "price": current["Close"],
        "change": change,
        "change_percent": change_percent,
        "high": current["High"],
        "low": current["Low"],
        "volume": int(current["Volume"]),
        "timestamp": datetime.now()
    }


@router.get("/history/{symbol}")
async def get_market_history(symbol: str, period: str = "1mo"):
    ticker = yf.Ticker(symbol)
    hist = ticker.history(period=period)
    
    if hist.empty:
        return {"error": "No data found"}
    
    return {
        "symbol": symbol.upper(),
        "data": [
            {
                "date": str(index.date()),
                "open": row["Open"],
                "high": row["High"],
                "low": row["Low"],
                "close": row["Close"],
                "volume": int(row["Volume"])
            }
            for index, row in hist.iterrows()
        ]
    }
