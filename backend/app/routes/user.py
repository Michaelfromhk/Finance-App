from fastapi import APIRouter, HTTPException
import httpx
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/user", tags=["user"])

user_currencies = ["EURUSD", "USDJPY", "GBPUSD", "USDCNY"]
user_commodities = ["GOLD", "SILVER", "CRUDE_OIL"]


class CustomItem(BaseModel):
    symbol: str
    name: str
    type: str


@router.get("/currencies", response_model=List[CustomItem])
async def get_user_currencies():
    return [
        CustomItem(symbol=symbol, name=symbol, type="currency")
        for symbol in user_currencies
    ]


@router.get("/commodities", response_model=List[CustomItem])
async def get_user_commodities():
    return [
        CustomItem(symbol=symbol, name=symbol, type="commodity")
        for symbol in user_commodities
    ]


@router.post("/currencies/{symbol}")
async def add_currency(symbol: str):
    upper = symbol.upper()
    if upper in user_currencies:
        return {"status": "already exists"}
    user_currencies.append(upper)
    return {"status": "added", "symbol": upper}


@router.delete("/currencies/{symbol}")
async def remove_currency(symbol: str):
    upper = symbol.upper()
    if upper in user_currencies:
        user_currencies.remove(upper)
        return {"status": "removed"}
    raise HTTPException(status_code=404, detail="Not found")


@router.post("/commodities/{name}")
async def add_commodity(name: str):
    upper = name.upper()
    if upper in user_commodities:
        return {"status": "already exists"}
    user_commodities.append(upper)
    return {"status": "added", "name": upper}


@router.delete("/commodities/{name}")
async def remove_commodity(name: str):
    upper = name.upper()
    if upper in user_commodities:
        user_commodities.remove(upper)
        return {"status": "removed"}
    raise HTTPException(status_code=404, detail="Not found")


@router.get("/all-custom")
async def get_all_custom():
    return {
        "currencies": [
            CustomItem(symbol=symbol, name=symbol, type="currency")
            for symbol in user_currencies
        ],
        "commodities": [
            CustomItem(symbol=symbol, name=symbol, type="commodity")
            for symbol in user_commodities
        ]
    }