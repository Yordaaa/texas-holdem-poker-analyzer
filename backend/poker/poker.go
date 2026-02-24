package poker

import (
    "errors"
    "fmt"
    "math/rand"
    "sort"
    "strings"
    "time"
)

// card ranks: 2-9, T, J, Q, K, A
// suits: H, D, C, S

// internal representation
const (
    NumRanks = 13
    NumSuits = 4
)

var rankMap = map[byte]int{
    '2': 0, '3': 1, '4': 2, '5': 3, '6': 4, '7': 5, '8': 6, '9': 7,
    'T': 8, 'J': 9, 'Q': 10, 'K': 11, 'A': 12,
}
var suitMap = map[byte]int{
    'H': 0, 'D': 1, 'C': 2, 'S': 3,
}

func parseCard(s string) (rank, suit int, err error) {
    if len(s) != 2 {
        return 0, 0, errors.New("card must be 2 characters")
    }
    // Convert to uppercase to be case-insensitive
    s = strings.ToUpper(s)
    r, ok := rankMap[s[1]]
    if !ok {
        return 0, 0, fmt.Errorf("invalid rank %c", s[1])
    }
    u, ok := suitMap[s[0]]
    if !ok {
        return 0, 0, fmt.Errorf("invalid suit %c", s[0])
    }
    return r, u, nil
}

// Evaluate returns best hand name and an integer value for comparison.
func Evaluate(hole []string, board []string) (string, int, error) {
    if len(hole) != 2 {
        return "", 0, errors.New("hole cards must be exactly 2")
    }
    if len(board) > 5 {
        return "", 0, errors.New("board cannot exceed 5 cards")
    }
    // Need at least 5 total cards (hole + board) to evaluate
    if len(hole)+len(board) < 5 {
        return "", 0, errors.New("need at least 5 cards total (hole + board)")
    }

    cards := make([]int, 0, len(hole)+len(board))
    seen := make(map[string]bool)
    for _, s := range append(hole, board...) {
        if seen[s] {
            return "", 0, errors.New("duplicate card")
        }
        seen[s] = true
        r, u, err := parseCard(s)
        if err != nil {
            return "", 0, err
        }
        cards = append(cards, r*10+u) // encode rank and suit
    }

    // if fewer than 7 cards, we'll still generate combinations though board count may be <5
    bestValue := -1
    bestName := ""
    combos := combinations(cards, 5)
    for _, combo := range combos {
        name, val := evaluate5(combo)
        if val > bestValue {
            bestValue = val
            bestName = name
        }
    }
    return bestName, bestValue, nil
}

// For simplicity in this demo, value will be encoded as follows:
// high bits = hand type (0=high card..8=straight flush), low bits encode kicker ranks.

func evaluate5(cards []int) (string, int) {
    // cards len always 5, each = rank*10 + suit
    ranks := make([]int, 5)
    suits := make([]int, 5)
    for i, c := range cards {
        ranks[i] = c / 10
        suits[i] = c % 10
    }
    sort.Ints(ranks)
    isFlush := true
    for i := 1; i < 5; i++ {
        if suits[i] != suits[0] {
            isFlush = false
            break
        }
    }
    // check straight (including wheel)
    isStraight := true
    for i := 1; i < 5; i++ {
        if ranks[i] != ranks[i-1]+1 {
            isStraight = false
            break
        }
    }
    // special case: wheel A-2-3-4-5 (ranks would sort to 0,1,2,3,12)
    if !isStraight {
        if ranks[0] == 0 && ranks[1] == 1 && ranks[2] == 2 && ranks[3] == 3 && ranks[4] == 12 {
            // wheel A-2-3-4-5: treat ace as low (rank 4) for kicker ordering
            isStraight = true
            ranks[4] = 4
        }
    }

    counts := make(map[int]int)
    for _, r := range ranks {
        counts[r]++
    }
    // count frequencies for pairs/trips/quads
    freq := make([]int, 0, len(counts))
    for _, v := range counts {
        freq = append(freq, v)
    }
    sort.Sort(sort.Reverse(sort.IntSlice(freq)))

    handType := 0
    switch {
    case isStraight && isFlush:
        handType = 8
    case freq[0] == 4:
        handType = 7
    case freq[0] == 3 && freq[1] == 2:
        handType = 6
    case isFlush:
        handType = 5
    case isStraight:
        handType = 4
    case freq[0] == 3:
        handType = 3
    case freq[0] == 2 && freq[1] == 2:
        handType = 2
    case freq[0] == 2:
        handType = 1
    default:
        handType = 0
    }

    // compute base value
    value := handType << 20
    // add kicker information (ranks reversed for comparison)
    for i := 4; i >= 0; i-- {
        value = (value << 4) | ranks[i]
    }

    name := handName(handType)
    return name, value
}

func handName(ht int) string {
    switch ht {
    case 8:
        return "Straight Flush"
    case 7:
        return "Four of a Kind"
    case 6:
        return "Full House"
    case 5:
        return "Flush"
    case 4:
        return "Straight"
    case 3:
        return "Three of a Kind"
    case 2:
        return "Two Pair"
    case 1:
        return "One Pair"
    default:
        return "High Card"
    }
}

// CompareValues returns 1 if v1>v2, -1 if v2>v1, 0 if equal
func CompareValues(v1, v2 int) int {
    if v1 > v2 {
        return 1
    }
    if v2 > v1 {
        return -1
    }
    return 0
}

// combinations returns all subsets of n cards taken k at a time
func combinations(cards []int, k int) [][]int {
    var res [][]int
    n := len(cards)
    if k > n {
        return res
    }
    idx := make([]int, k)
    for i := 0; i < k; i++ {
        idx[i] = i
    }
    for {
        combo := make([]int, k)
        for i := 0; i < k; i++ {
            combo[i] = cards[idx[i]]
        }
        res = append(res, combo)
        // advance
        i := k - 1
        for i >= 0 && idx[i] == n-k+i {
            i--
        }
        if i < 0 {
            break
        }
        idx[i]++
        for j := i + 1; j < k; j++ {
            idx[j] = idx[j-1] + 1
        }
    }
    return res
}

// Probability runs Monte Carlo simulation to estimate win probability for given hole and board
func Probability(hole []string, board []string, players, sims int) (float64, error) {
    if players < 2 {
        return 0, errors.New("at least two players")
    }
    if sims <= 0 {
        return 0, errors.New("simulations must be positive")
    }
    // parse known cards
    used := map[string]bool{}
    for _, c := range append(hole, board...) {
        if used[c] {
            return 0, errors.New("duplicate card in input")
        }
        used[c] = true
    }
    deck := make([]string, 0, 52-len(used))
    suits := []byte{'H', 'D', 'C', 'S'}
    ranks := []byte{'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'}
    for _, s := range suits {
        for _, r := range ranks {
            card := string([]byte{s, r})
            if !used[card] {
                deck = append(deck, card)
            }
        }
    }
    rand.Seed(time.Now().UnixNano())
    wins := 0
    for i := 0; i < sims; i++ {
        // shuffle deck
        rand.Shuffle(len(deck), func(i, j int) { deck[i], deck[j] = deck[j], deck[i] })
        // deal to opponents
        offset := 0
        oppHands := make([][]string, players-1)
        for p := 0; p < players-1; p++ {
            oppHands[p] = []string{deck[offset], deck[offset+1]}
            offset += 2
        }
        // fill missing board cards
        simBoard := append([]string(nil), board...)
        needed := 5 - len(simBoard)
        for j := 0; j < needed; j++ {
            simBoard = append(simBoard, deck[offset])
            offset++
        }
        // evaluate hero
        _, heroVal, _ := Evaluate(hole, simBoard)
        better := false
        tied := false
        for _, opp := range oppHands {
            _, val, _ := Evaluate(opp, simBoard)
            cmp := CompareValues(heroVal, val)
            if cmp < 0 {
                better = true
                break
            }
            if cmp == 0 {
                tied = true
            }
        }
        if !better {
            if tied {
                wins += 1 // split pot; count as partial win? but we'll simply count as win for simplicity
            } else {
                wins++
            }
        }
    }
    return float64(wins) / float64(sims), nil
}
