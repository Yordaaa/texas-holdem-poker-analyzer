# Texas Hold'em Poker Service

This repository contains a simple Texas Hold'em poker evaluation backend written in Go and a Flutter web frontend.

## Structure

- `backend/` – Go service providing REST API for hand evaluation and probability
- `frontend/` – Flutter web application (to be bootstrapped with `flutter create`)
- `k8s/` – Kubernetes manifests for deployment on GKE
- `k6/` – load test script using k6

## Backend (Go)

### Getting started

```bash
cd backend
go mod tidy
go test ./...  # run unit tests (includes spreadsheet loader)
```

A special test (`poker/spreadsheet_test.go`) opens the workbook
`Texas HoldEm Hand comparison test cases.xlsx` using only the standard
library. It logs every row from the first sheet so you can verify the
cases programmatically or extend the test to assert specific values.


### API endpoints

- `POST /evaluate` – evaluate hole+board cards
- `POST /compare` – compare two hands
- `POST /probability` – Monte Carlo win probability

Requests and responses use JSON (see `main.go` for structures).

### Build and run

```bash
go build -o texas-backend ./
./texas-backend   # listens on :8080
```

### Containerization

A `Dockerfile` is provided; build with:

```bash
docker build -t texas-backend backend
```

## Frontend (Flutter web)

Create the project with flutter:

```bash
cd frontend
flutter create .
flutter build web
```

Modify `lib/main.dart` to add UI for interacting with the backend (e.g. HTTP calls to `/evaluate`, `/probability`).

Dockerize using a multi-stage build (build in `flutter` image and serve via nginx).

## Kubernetes / GKE

1. Install `gcloud`, `kubectl`, `k6`, and ensure `gcloud` is authenticated.
2. Create a GKE cluster (AMD64 nodes):
   ```bash
   gcloud container clusters create texas-cluster \
    --zone=us-central1-c --num-nodes=3 --machine-type=e2-medium
   ```

````
3. Get credentials:
   ```bash
gcloud container clusters get-credentials texas-cluster --zone us-central1-c
````

4. Build and push images to Google Container Registry (GCR):
   ```bash
   gcloud builds submit --tag gcr.io/$PROJECT_ID/texas-backend:latest ./backend
   ```

# similarly for frontend

````
5. Apply manifests:
   ```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
````

6. After services are provisioned, note the external IP of the frontend service and use it to access the web app.

## Load Testing

Run k6 script against backend or frontend URL:

```bash
k6 run k6/probability-test.js
```

## Testing on AMD64 GKE nodes

GKE default nodes are amd64, which matches Go binary built without CGO.

## CI/CD

Add GitHub Actions workflow to build, test and push images whenever code is pushed to `main` branch. (Not yet included.)

---

Follow the step‑by‑step sections above to iteratively implement features, containerize, and deploy.
