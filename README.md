# 🃏 Texas Hold'em Poker Analyzer

A full-stack Texas Hold'em Poker Hand Analyzer deployed on **Google Kubernetes Engine (GKE)**.

**Live App:** http://34.59.185.221

---

## Features

- **Evaluate Hand** — Enter your hole cards + community cards and get the best hand (e.g. Royal Flush, Full House)
- **Win Probability** — Monte Carlo simulation to calculate your win % against N opponents
- **Compare Hands** — Head-to-head comparison of two players' hands on the same board

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web (CanvasKit renderer) |
| Backend | Go (Gorilla Mux) |
| Container | Docker (multi-stage build) |
| Orchestration | Kubernetes (GKE) |
| Registry | Google Container Registry (GCR) |
| Serving | Nginx (Alpine) |

## Project Structure

```
├── frontend/           # Flutter web app
│   ├── lib/main.dart   # App source code
│   ├── web/index.html  # Custom loading screen + CDN config
│   ├── nginx.conf      # Nginx config with Flutter SPA routing
│   └── Dockerfile      # Multi-stage: Flutter build → Nginx serve
├── backend/            # Go REST API
│   ├── main.go         # HTTP handlers (evaluate, compare, probability)
│   ├── poker/          # Poker hand evaluation logic
│   └── Dockerfile
├── k8s/                # Kubernetes manifests
│   ├── frontend-deployment.yaml
│   └── backend-deployment.yaml
└── deploy.py           # GCP deployment automation script
```

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/evaluate` | Evaluate best hand from hole + board cards |
| POST | `/api/probability` | Monte Carlo win probability simulation |
| POST | `/api/compare` | Compare two hands head-to-head |

### Card Format
Cards are encoded as `<suit><rank>` — e.g.:
- `HA` = Ace of Hearts
- `SK` = King of Spades
- `DT` = Ten of Diamonds
- `C9` = Nine of Clubs

## Local Development

### Backend
```bash
cd backend
go run main.go
# Runs on :8080
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Docker Build

```bash
# Backend
docker build -t texas-backend ./backend

# Frontend
docker build -t texas-frontend ./frontend
```

## Deployment (GKE)

```bash
# 1. Build & push images
docker build -t gcr.io/<PROJECT_ID>/texas-frontend:v1 ./frontend
docker push gcr.io/<PROJECT_ID>/texas-frontend:v1

docker build -t gcr.io/<PROJECT_ID>/texas-backend:v1 ./backend
docker push gcr.io/<PROJECT_ID>/texas-backend:v1

# 2. Get cluster credentials
gcloud container clusters get-credentials poker-cluster --zone us-central1-a

# 3. Deploy
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# 4. Check status
kubectl rollout status deployment/texas-frontend
kubectl get svc texas-frontend  # Get external IP
```

## License

MIT
