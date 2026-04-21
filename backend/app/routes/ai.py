from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import httpx
from app.config import settings

router = APIRouter(prefix="/api/ai", tags=["ai"])


class NewsRequest(BaseModel):
    prompt: str
    provider: Optional[str] = "google"
    max_sources: Optional[int] = 5


class NewsSource(BaseModel):
    title: str
    url: str
    summary: Optional[str] = None


class NewsResponse(BaseModel):
    prompt: str
    content: str
    sources: List[NewsSource]
    provider: str
    timestamp: datetime


GOOGLE_AI_URL = "https://generativelanguage.googleapis.com/v1beta2/models/gemini-pro:generateContent"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"


@router.post("/news", response_model=NewsResponse)
async def generate_news(request: NewsRequest):
    if request.provider == "google":
        if not settings.google_ai_api_key:
            raise HTTPException(status_code=500, detail="Google AI API key not configured")
        return await _google_generate(request)
    elif request.provider == "openai":
        if not settings.openai_api_key:
            raise HTTPException(status_code=500, detail="OpenAI API key not configured")
        return await _openai_generate(request)
    else:
        raise HTTPException(status_code=400, detail="Invalid provider")


async def _google_generate(request: NewsRequest):
    prompt_text = f"""Based on the following prompt, provide a concise financial news summary:\n\n{request.prompt}\n\n
Format your response with clear sections and cite sources where applicable."""
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{GOOGLE_AI_URL}?key={settings.google_ai_api_key}",
            json={
                "contents": [{"parts": [{"text": prompt_text}]}],
                "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048}
            },
            timeout=60.0
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Google AI API error")
        
        data = response.json()
        content = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        
        return {
            "prompt": request.prompt,
            "content": content,
            "sources": [],
            "provider": "google",
            "timestamp": datetime.now()
        }


async def _openai_generate(request: NewsRequest):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            OPENAI_URL,
            headers={
                "Authorization": f"Bearer {settings.openai_api_key}",
                "Content-Type": "application/json"
            },
            json={
                "model": "gpt-3.5-turbo",
                "messages": [
                    {"role": "system", "content": "You are a financial news analyst. Provide concise, well-sourced summaries."},
                    {"role": "user", "content": request.prompt}
                ],
                "temperature": 0.7,
                "max_tokens": 2048
            },
            timeout=60.0
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="OpenAI API error")
        
        data = response.json()
        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        
        return {
            "prompt": request.prompt,
            "content": content,
            "sources": [],
            "provider": "openai",
            "timestamp": datetime.now()
        }