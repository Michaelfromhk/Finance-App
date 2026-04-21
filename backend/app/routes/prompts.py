from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/prompts", tags=["prompts"])

prompt_store: List[dict] = []


class PromptCreate(BaseModel):
    name: str
    prompt: str
    frequency: str
    enabled: bool = True
    ai_provider: str = "google"


class PromptResponse(BaseModel):
    id: str
    name: str
    prompt: str
    frequency: str
    enabled: bool
    ai_provider: str
    created_at: datetime
    last_run: Optional[datetime] = None


@router.get("/", response_model=List[PromptResponse])
async def get_prompts():
    return prompt_store


@router.post("/", response_model=PromptResponse)
async def create_prompt(prompt: PromptCreate):
    new_prompt = {
        "id": str(uuid.uuid4()),
        "name": prompt.name,
        "prompt": prompt.prompt,
        "frequency": prompt.frequency,
        "enabled": prompt.enabled,
        "ai_provider": prompt.ai_provider,
        "created_at": datetime.now(),
        "last_run": None
    }
    prompt_store.append(new_prompt)
    return new_prompt


@router.put("/{prompt_id}", response_model=PromptResponse)
async def update_prompt(prompt_id: str, prompt: PromptCreate):
    for p in prompt_store:
        if p["id"] == prompt_id:
            p["name"] = prompt.name
            p["prompt"] = prompt.prompt
            p["frequency"] = prompt.frequency
            p["enabled"] = prompt.enabled
            p["ai_provider"] = prompt.ai_provider
            return p
    raise HTTPException(status_code=404, detail="Prompt not found")


@router.delete("/{prompt_id}")
async def delete_prompt(prompt_id: str):
    global prompt_store
    prompt_store = [p for p in prompt_store if p["id"] != prompt_id]
    return {"status": "deleted"}


@router.post("/{prompt_id}/run")
async def run_prompt(prompt_id: str):
    for p in prompt_store:
        if p["id"] == prompt_id:
            p["last_run"] = datetime.now()
            return {"status": "run", "prompt": p}
    raise HTTPException(status_code=404, detail="Prompt not found")