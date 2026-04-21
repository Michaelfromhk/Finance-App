# Finance App

Financial market intelligence app with AI-powered news aggregation and market data tracking.

## Project Structure

```
Finance-App/
├── app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API service
│   │   └── models/         # Data models
│   └── pubspec.yaml
├── backend/               # FastAPI backend
│   ├── main.py
│   ├── requirements.txt
│   ├── app/
│   │   ├── routes/        # API endpoints
│   │   └── config.py
│   └── railway.json
└── .github/workflows/    # CI/CD
    └── ios.yml            # iOS build workflow
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter |
| Backend | FastAPI |
| Data | yfinance |
| AI | Google AI Studio + OpenAI |
| Server | Railway |
| iOS Build | GitHub Actions |

## Setup

### Backend (Railway)

1. Create Railway account at railway.app
2. Connect GitHub repo
3. Deploy from `backend/` folder
4. Set environment variables:
   - `OPENAI_API_KEY`
   - `GOOGLE_AI_API_KEY`

### Flutter App

```bash
cd app
flutter pub get
flutter run
```

### iOS Build (GitHub Actions)

1. Set up Apple Developer account ($99/year)
2. Push to main branch to trigger build
3. Download built artifact from Actions

## Features

- Market data from stocks, ETFs, crypto, forex via yfinance
- AI news generation with Google Gemini / OpenAI GPT
- Custom prompts with scheduling
- Market indicators dashboard with charts
- iOS app via TestFlight