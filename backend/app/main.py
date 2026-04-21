from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import market, ai, prompts

app = FastAPI(
    title="Finance App API",
    description="Backend API for financial market data and AI news",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(market.router)
app.include_router(ai.router)
app.include_router(prompts.router)


@app.get("/")
async def root():
    return {"message": "Finance App API", "status": "running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}