package main

import (
    "encoding/json"
    "log"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/example/texas-poker/poker"
)

// CORS middleware to allow browser requests from different origins
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
        
        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }
        
        next.ServeHTTP(w, r)
    })
}

func main() {
    r := mux.NewRouter()
    r.HandleFunc("/evaluate", evaluateHandler).Methods("POST")
    r.HandleFunc("/compare", compareHandler).Methods("POST")
    r.HandleFunc("/probability", probabilityHandler).Methods("POST")

    http.Handle("/", corsMiddleware(r))
    log.Println("starting server on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}

type evalRequest struct {
    Hole  []string `json:"hole"`  // two cards
    Board []string `json:"board"` // 0..5 cards
}

type evalResponse struct {
    Hand  string `json:"hand"`
    Value int    `json:"value"` // numeric rank for tie-breaking
}

func evaluateHandler(w http.ResponseWriter, r *http.Request) {
    var req evalRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        log.Printf("ERROR decoding request: %v", err)
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    log.Printf("Evaluate request: hole=%v board=%v", req.Hole, req.Board)
    hand, value, err := poker.Evaluate(req.Hole, req.Board)
    if err != nil {
        log.Printf("ERROR evaluating hand: %v", err)
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    log.Printf("Result: %s (value=%d)", hand, value)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(evalResponse{Hand: hand, Value: value})
}

type compareRequest struct {
    Hands []evalRequest `json:"hands"` // expect length 2
}

type compareResponse struct {
    Winner int `json:"winner"` // index of winning hand, -1 if tie
}

func compareHandler(w http.ResponseWriter, r *http.Request) {
    var req compareRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    if len(req.Hands) != 2 {
        http.Error(w, "need exactly two hands to compare", http.StatusBadRequest)
        return
    }
    w1, v1, err := poker.Evaluate(req.Hands[0].Hole, req.Hands[0].Board)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    w2, v2, err := poker.Evaluate(req.Hands[1].Hole, req.Hands[1].Board)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    winner := poker.CompareValues(v1, v2)
    // winner returns 1 if first better, -1 if second better, 0 tie
    var idx int
    if winner > 0 {
        idx = 0
    } else if winner < 0 {
        idx = 1
    } else {
        idx = -1
    }
    log.Printf("hand1=%s (%d) hand2=%s (%d) winner=%d", w1, v1, w2, v2, idx)
    json.NewEncoder(w).Encode(compareResponse{Winner: idx})
}

// probability request

type probRequest struct {
    Hole        []string `json:"hole"`
    Board       []string `json:"board"`
    Players     int      `json:"players"`
    Simulations int      `json:"simulations"`
}

type probResponse struct {
    WinProbability float64 `json:"winProbability"` // fraction 0..1
}

func probabilityHandler(w http.ResponseWriter, r *http.Request) {
    var req probRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        log.Printf("ERROR decoding probability request: %v", err)
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    log.Printf("Probability request: hole=%v board=%v players=%d sims=%d", req.Hole, req.Board, req.Players, req.Simulations)
    prob, err := poker.Probability(req.Hole, req.Board, req.Players, req.Simulations)
    if err != nil {
        log.Printf("ERROR calculating probability: %v", err)
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    log.Printf("Probability result: %.4f", prob)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(probResponse{WinProbability: prob})
}
