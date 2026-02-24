@echo off
REM Quick Setup and Deployment Script for Windows

setlocal enabledelayedexpansion

echo ========================================
echo Texas Hold'em Poker - Quick Setup
echo ========================================
echo.

REM Check for Docker
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Docker not found. Please install Docker Desktop.
    echo Visit: https://docs.docker.com/desktop/install/windows-install/
    exit /b 1
)

REM Check for Docker Compose
where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Docker Compose not found
    exit /b 1
)

echo Choose deployment option:
echo 1. Build locally with Docker Compose
echo 2. Build Docker images only
echo 3. Deploy to Google Cloud
echo.

set /p choice="Enter choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Building and starting with Docker Compose...
    docker-compose build
    docker-compose up -d
    echo.
    echo Services started!
    echo - Frontend: http://localhost
    echo - Backend: http://localhost:8080
    echo.
    echo View logs: docker-compose logs -f
    echo Stop services: docker-compose down
) else if "%choice%"=="2" (
    echo.
    echo Building Docker images...
    cd backend
    docker build -t texas-hold-em-backend:latest .
    cd ..
    cd frontend
    docker build -t texas-hold-em-frontend:latest .
    cd ..
    echo.
    echo Images built successfully!
    echo Run: docker-compose up -d
) else if "%choice%"=="3" (
    echo.
    echo GCP Deployment Setup
    echo.
    set /p project_id="Enter GCP Project ID: "
    set /p region="Enter GCP Region (default: us-central1): "
    if "!region!"=="" set region=us-central1
    
    echo.
    echo Setting up gcloud...
    call gcloud config set project !project_id!
    call gcloud auth configure-docker
    
    echo.
    echo Building images...
    cd backend
    call docker build -t gcr.io/!project_id!/texas-backend:latest .
    cd ..
    cd frontend
    call docker build -t gcr.io/!project_id!/texas-frontend:latest .
    cd ..
    
    echo.
    echo Pushing to Google Container Registry...
    call docker push gcr.io/!project_id!/texas-backend:latest
    call docker push gcr.io/!project_id!/texas-frontend:latest
    
    echo.
    echo Images pushed successfully!
    echo Next steps:
    echo 1. Run: bash deploy-gcp.sh
    echo 2. Or follow manual steps in DEPLOYMENT.md
) else (
    echo Invalid choice
    exit /b 1
)

echo.
echo Done!
pause
