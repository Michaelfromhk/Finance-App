from fastapi import APIRouter, HTTPException
import httpx
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.config import settings

router = APIRouter(prefix="/api/econ", tags=["economics"])

FRED_URL = "https://api.stlouisfed.org/fred"


def get_fred_key():
    return settings.fred_api_key or "demo"


ECONOMIC_INDICATORS = {
    "GDP": {"id": "GDP", "name": "Gross Domestic Product", "unit": "Billions USD"},
    "UNEMPLOYMENT": {"id": "UNRATE", "name": "Unemployment Rate", "unit": "Percent"},
    "INFLATION": {"id": "CPIAUCSL", "name": "Consumer Price Index", "unit": "Index"},
    "FED_RATE": {"id": "FEDFUNDS", "name": "Federal Funds Rate", "unit": "Percent"},
    "TREASURY_10Y": {"id": "DGS10", "name": "10-Year Treasury Yield", "unit": "Percent"},
    "TREASURY_2Y": {"id": "DGS2", "name": "2-Year Treasury Yield", "unit": "Percent"},
    "INDUSTRIAL_PROD": {"id": "INDPRO", "name": "Industrial Production", "unit": "Index"},
    "RETAIL_SALES": {"id": "RETAILSM", "name": "Retail Sales", "unit": "Millions USD"},
    "HOUSING_STARTS": {"id": "HOUST", "name": "Housing Starts", "unit": "Thousands"},
    "CONSUMER_CONFIDENCE": {"id": "CCI", "name": "Consumer Confidence", "unit": "Index"},
}


def get_fred_observation(series_id: str):
    url = f"{FRED_URL}/series/observations"
    params = {
        "series_id": series_id,
        "api_key": get_fred_key(),
        "file_type": "json",
        "limit": 1,
        "sort_order": "desc"
    }

    try:
        response = httpx.get(url, params=params, timeout=30)
        if response.status_code == 200:
            data = response.json()
            observations = data.get("observations", [])
            if observations:
                latest = observations[0]
                value = latest["value"]
                return {
                    "series_id": series_id,
                    "date": latest["date"],
                    "value": float(value) if value and value != "." else None
                }
        return None
    except Exception:
        return None


@router.get("/indicators")
async def get_economic_indicators():
    results = []
    for key, info in ECONOMIC_INDICATORS.items():
        data = get_fred_observation(info["id"])
        if data:
            results.append({
                "series_id": key,
                "name": info["name"],
                "value": data["value"],
                "date": data["date"],
                "unit": info["unit"]
            })
    return results


@router.get("/indicator/{series_id}")
async def get_indicator(series_id: str):
    upper_id = series_id.upper()
    if upper_id not in ECONOMIC_INDICATORS:
        raise HTTPException(status_code=404, detail=f"Unknown indicator: {series_id}")

    info = ECONOMIC_INDICATORS[upper_id]
    data = get_fred_observation(info["id"])

    if not data:
        raise HTTPException(status_code=404, detail="No data available")

    return {
        "series_id": upper_id,
        "name": info["name"],
        "value": data["value"],
        "date": data["date"],
        "unit": info["unit"]
    }


@router.get("/history/{series_id}")
async def get_indicator_history(series_id: str, limit: int = 52):
    upper_id = series_id.upper()
    if upper_id not in ECONOMIC_INDICATORS:
        raise HTTPException(status_code=404, detail="Unknown indicator")

    info = ECONOMIC_INDICATORS[upper_id]

    url = f"{FRED_URL}/series/observations"
    params = {
        "series_id": info["id"],
        "api_key": get_fred_key(),
        "file_type": "json",
        "limit": limit,
        "sort_order": "desc"
    }

    try:
        response = httpx.get(url, params=params, timeout=30)
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="FRED API error")

        data = response.json()
        observations = data.get("observations", [])

        return {
            "series_id": upper_id,
            "name": info["name"],
            "unit": info["unit"],
            "data": [
                {"date": obs["date"], "value": float(obs["value"]) if obs["value"] and obs["value"] != "." else None}
                for obs in observations
            ]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/bonds")
async def get_bond_yields():
    bonds = {
        "US_10Y": "DGS10",
        "US_2Y": "DGS2",
        "US_5Y": "DGS5",
        "US_30Y": "DGS30",
    }

    results = []
    for name, series_id in bonds.items():
        data = get_fred_observation(series_id)
        if data:
            results.append({
                "name": name,
                "yield": data["value"],
                "date": data["date"]
            })

    return results


CURRENCY_PAIRS = {
    "EURUSD": "EURUSD=X",
    "USDJPY": "USDJPY=X",
    "GBPUSD": "GBPUSD=X",
    "USDCHF": "USDCHF=X",
    "AUDUSD": "AUDUSD=X",
    "USDCAD": "USDCAD=X",
    "NZDUSD": "NZDUSD=X",
    "USDHKD": "USDHKD=X",
    "USDCNY": "USDCNY=X",
    "USDKRW": "USDKRW=X",
}

COMMODITIES = {
    "GOLD": "GC=F",
    "SILVER": "SI=F",
    "CRUDE_OIL": "CL=F",
    "NATURAL_GAS": "NG=F",
    "COPPER": "HG=F",
    "PLATINUM": "PL=F",
}


@router.get("/currency/{pair}")
async def get_currency(pair: str):
    upper_pair = pair.upper()
    if upper_pair not in CURRENCY_PAIRS:
        raise HTTPException(status_code=404, detail="Unknown currency pair")

    symbol = CURRENCY_PAIRS[upper_pair]
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"

    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        response = httpx.get(url, headers=headers, timeout=15)

        if response.status_code != 200:
            return {"symbol": upper_pair, "error": "Yahoo unavailable", "price": None}

        data = response.json()
        result = data.get("chart", {}).get("result", [{}])[0]

        if not result:
            return {"symbol": upper_pair, "error": "No data", "price": None}

        quote = result.get("indicators", {}).get("quote", [{}])[0]
        closes = [p for p in quote.get("close", []) if p is not None]

        if not closes:
            return {"symbol": upper_pair, "error": "No prices", "price": None}

        current = closes[-1]
        previous = closes[-2] if len(closes) > 1 else current
        change = current - previous
        change_percent = (change / previous * 100) if previous else 0

        return {
            "symbol": upper_pair,
            "name": upper_pair,
            "price": current,
            "change": change,
            "change_percent": change_percent,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {"symbol": upper_pair, "error": str(e), "price": None}


@router.get("/commodity/{name}")
async def get_commodity(name: str):
    upper_name = name.upper()
    if upper_name not in COMMODITIES:
        raise HTTPException(status_code=404, detail="Unknown commodity")

    symbol = COMMODITIES[upper_name]
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"

    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        response = httpx.get(url, headers=headers, timeout=15)

        if response.status_code != 200:
            return {"symbol": upper_name, "error": "Yahoo unavailable", "price": None}

        data = response.json()
        result = data.get("chart", {}).get("result", [{}])[0]

        if not result:
            return {"symbol": upper_name, "error": "No data", "price": None}

        quote = result.get("indicators", {}).get("quote", [{}])[0]
        closes = [p for p in quote.get("close", []) if p is not None]

        if not closes:
            return {"symbol": upper_name, "error": "No prices", "price": None}

        current = closes[-1]
        previous = closes[-2] if len(closes) > 1 else current
        change = current - previous
        change_percent = (change / previous * 100) if previous else 0

        return {
            "symbol": upper_name,
            "name": upper_name,
            "price": current,
            "change": change,
            "change_percent": change_percent,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {"symbol": upper_name, "error": str(e), "price": None}