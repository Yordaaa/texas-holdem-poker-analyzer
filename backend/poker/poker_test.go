package poker

import "testing"

func TestEvaluate(t *testing.T) {
    tests := []struct {
        hole  []string
        board []string
        want  string
    }{
        {[]string{"HA", "HK"}, []string{"HQ", "HJ", "HT", "H9", "H8"}, "Straight Flush"},
        {[]string{"HA", "DA"}, []string{"CA", "SA", "H2", "D3"}, "Four of a Kind"},
        {[]string{"HA", "DA"}, []string{"CA", "SK", "HK", "DK"}, "Full House"},
        {[]string{"HA", "H3"}, []string{"H2", "H5", "H7", "C9", "DK"}, "Flush"},
        {[]string{"HA", "D2"}, []string{"C3", "S4", "H5", "D9", "DK"}, "Straight"},
        {[]string{"HA", "DA"}, []string{"CA", "S2", "H3", "D9", "DK"}, "Three of a Kind"},
        {[]string{"HA", "DA"}, []string{"HK", "DK", "S3", "C4", "D9"}, "Two Pair"},
        {[]string{"HA", "C2"}, []string{"H2", "D3", "S5", "C7", "D9"}, "One Pair"},
        {[]string{"HA", "DK"}, []string{"H2", "D3", "S5", "C7", "D9"}, "High Card"},
    }
    for _, tc := range tests {
        got, _, err := Evaluate(tc.hole, tc.board)
        if err != nil {
            t.Fatalf("unexpected error: %v", err)
        }
        if got != tc.want {
            t.Errorf("Evaluate(%v,%v) = %s; want %s", tc.hole, tc.board, got, tc.want)
        }
    }
}

func TestCompare(t *testing.T) {
    a := []string{"HA", "HK"}
    b := []string{"HA", "HK"}
    board := []string{"HQ", "HJ", "HT", "H9", "H8"}
    _, va, _ := Evaluate(a, board)
    _, vb, _ := Evaluate(b, board)
    if CompareValues(va, vb) != 0 {
        t.Error("identical hands should tie")
    }
    // high card vs pair
    board2 := []string{"H2", "D3", "S5", "C7", "D9"}
    _, va2, _ := Evaluate(a, board2)
    _, vb2, _ := Evaluate(b, board2)
    if CompareValues(va2, vb2) != 0 {
        t.Error("still tie with same hole")
    }
}

func TestProbability(t *testing.T) {
    prob, err := Probability([]string{"HA", "HK"}, []string{"HQ", "HJ", "HT", "H9", "H8"}, 2, 1000)
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if prob < 0 || prob > 1 {
        t.Errorf("probability out of range: %f", prob)
    }
}

// additional comparison cases derived from provided test spreadsheet/image
func TestCompareCases(t *testing.T) {
    cases := []struct{
        board []string
        h1    []string
        h2    []string
        want  int // 0 means first wins, 1 means second wins, -1 tie
    }{
        // high card: SK over SQ
        {[]string{"D6","S9","H4","S3","C2"}, []string{"SK","CA"}, []string{"HA","SQ"}, 0},
        // another high-card permutation, second has CK instead of SQ
        {[]string{"D6","S9","H4","S3","C2"}, []string{"SK","CA"}, []string{"HA","CK"}, -1},
        // high card with different board ordering
        {[]string{"D6","S9","H4","H3","H2"}, []string{"SK","CA"}, []string{"HA","SQ"}, 0},
        // high card comparing DQ vs DJ
        {[]string{"D6","S9","H4","H3","H2"}, []string{"C7","DQ"}, []string{"C8","DJ"}, 0},
        // one pair: K kicker beats 8 kicker
        {[]string{"SK","HT","C8","C7","D2"}, []string{"DK","C5"}, []string{"H8","D5"}, 0},
        // two pair: A-Q > Q-? (simple example)
        {[]string{"SA","DQ","CK","D6","H6"}, []string{"HA","C3"}, []string{"CQ","H4"}, 0},
        // three of a kind: J3 scenario
        {[]string{"SA","D3","H3","C8","SJ"}, []string{"S3","HK"}, []string{"HJ","H2"}, 0},
        // straight: 7-high straight beats 6-high
        {[]string{"H3","S4","C5","S6","HT"}, []string{"D7","HA"}, []string{"H2","SA"}, 0},
        // flush: A-high diamond flush beats Q-high
        {[]string{"D3","D6","DT","C5","HQ"}, []string{"DK","DA"}, []string{"D2","DQ"}, 0},
        // four of a kind: A>K
        {[]string{"HT","ST","CT","DT","HK"}, []string{"HA","S7"}, []string{"DJ","C5"}, 0},
        // royal flush on board results in tie regardless of holes
        {[]string{"DT","DJ","DQ","DK","DA"}, []string{"HA","HK"}, []string{"CA","CK"}, -1},
    }
    for i, tc := range cases {
        _, v1, err1 := Evaluate(tc.h1, tc.board)
        if err1 != nil {
            t.Fatalf("case %d: unexpected error evaluating hand1: %v", i, err1)
        }
        _, v2, err2 := Evaluate(tc.h2, tc.board)
        if err2 != nil {
            t.Fatalf("case %d: unexpected error evaluating hand2: %v", i, err2)
        }
        cmp := CompareValues(v1, v2)
        var got int
        if cmp > 0 {
            got = 0
        } else if cmp < 0 {
            got = 1
        } else {
            got = -1
        }
        if got != tc.want {
            t.Errorf("case %d: board=%v h1=%v h2=%v want %d got %d", i, tc.board, tc.h1, tc.h2, tc.want, got)
        }
    }
}
