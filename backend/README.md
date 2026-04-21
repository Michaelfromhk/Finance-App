# Finance App API

Backend API for financial market data and AI news aggregation.

## Endpoints

- `GET /api/market/{symbol}` - Get stock/ETF data
- `GET /api/market/history/{symbol}` - Get historical data
- `POST /api/ai/news` - Generate AI news summary
- `GET /api/prompts` - List prompts
- `POST /api/prompts` - Create prompt
- `PUT /api/prompts/{id}` - Update prompt
- `DELETE /api/prompts/{id}` - Delete prompt
- `POST /api/prompts/{id}/run` - Run prompt

## Environment Variables

- `OPENAI_API_KEY` - OpenAI API key
- `GOOGLE_AI_API_KEY` - Google AI Studio API key
- `FUTU_API_KEY` - Futu API key
- `FUTU_API_SECRET` - Futu API secret