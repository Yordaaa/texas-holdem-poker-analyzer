import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Hold\'em Poker Helper',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// Card display widget
class CardDisplay extends StatelessWidget {
  final String cardText;
  final Color borderColor;
  final Color backgroundColor;

  const CardDisplay({
    required this.cardText,
    this.borderColor = Colors.grey,
    this.backgroundColor = Colors.white,
  });

  Color getSuitColor(String suit) {
    switch (suit.toUpperCase()) {
      case 'H':
      case 'D':
        return Colors.red;
      case 'C':
      case 'S':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String getSuitSymbol(String suit) {
    switch (suit.toUpperCase()) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'C':
        return '♣';
      case 'S':
        return '♠';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cardText.isEmpty) {
      return Container(
        width: 70,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Center(
          child: Icon(Icons.add, color: Colors.grey[400]),
        ),
      );
    }

    String suit = cardText.isNotEmpty ? cardText[0] : '';
    String rank = cardText.length > 1 ? cardText[1] : '';
    // treat '1' as Ace for convenience
    if (rank == '1') rank = 'A';
    Color suitColor = getSuitColor(suit);
    String suitSymbol = getSuitSymbol(suit);

    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: suitColor, width: 2.5),
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: suitColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: suitColor,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: 14,
                    color: suitColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              suitSymbol,
              style: TextStyle(
                fontSize: 20,
                color: suitColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Evaluate tab
  final hole1Controller = TextEditingController();
  final hole2Controller = TextEditingController();
  final board1Controller = TextEditingController();
  final board2Controller = TextEditingController();
  final board3Controller = TextEditingController();
  final board4Controller = TextEditingController();
  final board5Controller = TextEditingController();

  // Probability tab
  final probHole1Controller = TextEditingController();
  final probHole2Controller = TextEditingController();
  final probBoard1Controller = TextEditingController();
  final probBoard2Controller = TextEditingController();
  final probBoard3Controller = TextEditingController();
  final probBoard4Controller = TextEditingController();
  final probBoard5Controller = TextEditingController();
  final playersController = TextEditingController(text: '2');
  final simController = TextEditingController(text: '10000');

  // Compare tab
  final p1Card1Controller = TextEditingController();
  final p1Card2Controller = TextEditingController();
  final p2Card1Controller = TextEditingController();
  final p2Card2Controller = TextEditingController();
  final boardC1Controller = TextEditingController();
  final boardC2Controller = TextEditingController();
  final boardC3Controller = TextEditingController();
  final boardC4Controller = TextEditingController();
  final boardC5Controller = TextEditingController();

  String result = '';
  String resultType = ''; // 'hand', 'probability', 'error', 'winner'
  bool isLoading = false;
  String backendUrl = '/api';
  int activeTab = 0;

  Future<void> evaluate() async {
    final hole = [hole1Controller.text, hole2Controller.text]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();
    final board = [
      board1Controller.text,
      board2Controller.text,
      board3Controller.text,
      board4Controller.text,
      board5Controller.text,
    ]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();

    if (hole.length != 2) {
      showError('Please enter exactly 2 hole cards');
      return;
    }
    if (board.isEmpty || board.length > 5) {
      showError('Please enter 1-5 community cards');
      return;
    }

    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      final resp = await http.post(
        Uri.parse('$backendUrl/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hole': hole, 'board': board}),
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          result = data['hand'];
          resultType = 'hand';
          isLoading = false;
        });
      } else {
        showError('Server error: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  Future<void> calculateProbability() async {
    final hole = [probHole1Controller.text, probHole2Controller.text]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();
    final board = [
      probBoard1Controller.text,
      probBoard2Controller.text,
      probBoard3Controller.text,
      probBoard4Controller.text,
      probBoard5Controller.text,
    ]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();

    if (hole.length != 2) {
      showError('Please enter exactly 2 hole cards');
      return;
    }
    if (board.isEmpty || board.length > 5) {
      showError('Please enter 1-5 community cards');
      return;
    }

    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      final players = int.tryParse(playersController.text) ?? 2;
      final sims = int.tryParse(simController.text) ?? 10000;

      final resp = await http.post(
        Uri.parse('$backendUrl/probability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hole': hole,
          'board': board,
          'players': players,
          'simulations': sims,
        }),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final prob = (data['winProbability'] * 100).toStringAsFixed(2);
        setState(() {
          result = '$prob%';
          resultType = 'probability';
          isLoading = false;
        });
      } else {
        showError('Server error: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  Future<void> compareHands() async {
    final hand1 = [p1Card1Controller.text, p1Card2Controller.text]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();
    final hand2 = [p2Card1Controller.text, p2Card2Controller.text]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();
    final board = [
      boardC1Controller.text,
      boardC2Controller.text,
      boardC3Controller.text,
      boardC4Controller.text,
      boardC5Controller.text,
    ]
        .where((e) => e.isNotEmpty)
        .map((e) => e.toUpperCase())
        .toList();

    if (hand1.length != 2) {
      showError('Player 1: Enter exactly 2 cards');
      return;
    }
    if (hand2.length != 2) {
      showError('Player 2: Enter exactly 2 cards');
      return;
    }
    if (board.isEmpty || board.length > 5) {
      showError('Community: Enter 1-5 cards');
      return;
    }

    setState(() {
      isLoading = true;
      result = '';
    });

    try {
      final resp = await http.post(
        Uri.parse('$backendUrl/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hands': [
            {'hole': hand1, 'board': board},
            {'hole': hand2, 'board': board},
          ]
        }),
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final winner = data['winner'];
        setState(() {
          if (winner == 0) {
            result = 'Player 1 Wins!';
          } else if (winner == 1) {
            result = 'Player 2 Wins!';
          } else {
            result = 'Tie!';
          }
          resultType = 'winner';
          isLoading = false;
        });
      } else {
        showError('Server error: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  void showError(String message) {
    setState(() {
      result = message;
      resultType = 'error';
      isLoading = false;
    });
  }

  @override
  void dispose() {
    hole1Controller.dispose();
    hole2Controller.dispose();
    board1Controller.dispose();
    board2Controller.dispose();
    board3Controller.dispose();
    board4Controller.dispose();
    board5Controller.dispose();
    probHole1Controller.dispose();
    probHole2Controller.dispose();
    probBoard1Controller.dispose();
    probBoard2Controller.dispose();
    probBoard3Controller.dispose();
    probBoard4Controller.dispose();
    probBoard5Controller.dispose();
    playersController.dispose();
    simController.dispose();
    p1Card1Controller.dispose();
    p1Card2Controller.dispose();
    p2Card1Controller.dispose();
    p2Card2Controller.dispose();
    boardC1Controller.dispose();
    boardC2Controller.dispose();
    boardC3Controller.dispose();
    boardC4Controller.dispose();
    boardC5Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('🃏 Poker Hand Analyzer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.indigo.withOpacity(0.05),
            child: Row(
              children: [
                _buildTabButton('Evaluate', 0),
                _buildTabButton('Probability', 1),
                _buildTabButton('Compare', 2),
              ],
            ),
          ),
          Expanded(
            child: activeTab == 0
                ? _buildEvaluateTab()
                : activeTab == 1
                    ? _buildProbabilityTab()
                    : _buildCompareTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    bool isActive = activeTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.indigo : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.indigo : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardInput(TextEditingController controller, String label) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            maxLength: 2,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400]),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.indigo, width: 2.5),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            onChanged: (value) {
              // treat '1' as Ace and force uppercase
              var cleaned = value.toUpperCase();
              // if only '1', convert to 'A'
              if (cleaned == '1') {
                cleaned = 'A';
              }
              // if H1, D1, C1, S1 convert rank to A
              else if (cleaned.length == 2 && cleaned[1] == '1') {
                cleaned = cleaned[0] + 'A';
              }
              if (cleaned != value) {
                controller.text = cleaned;
                controller.selection = TextSelection.collapsed(offset: cleaned.length);
              }
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
        CardDisplay(cardText: controller.text),
      ],
    );
  }

  Widget _buildEvaluateTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Your hole cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🃏 Your Hole Cards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardInput(hole1Controller, 'H1'),
                      _buildCardInput(hole2Controller, 'H2'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Community cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[50]!, Colors.teal[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '🏛️ Community Cards (Enter 1-5)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildCardInput(board1Controller, 'C1'),
                        _buildCardInput(board2Controller, 'C2'),
                        _buildCardInput(board3Controller, 'C3'),
                        _buildCardInput(board4Controller, 'C4'),
                        _buildCardInput(board5Controller, 'C5'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : evaluate,
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search, color: Colors.white),
                label: const Text('Evaluate Hand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                disabledBackgroundColor: Colors.grey[400],
              ),
            ),
            if (result.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: resultType == 'error' ? Colors.red[50] : Colors.green[50],
                  border: Border.all(
                    color: resultType == 'error' ? Colors.red[400]! : Colors.green[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (resultType == 'error' ? Colors.red : Colors.green).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      resultType == 'error' ? '❌ Error' : '✅ Best Hand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: resultType == 'error' ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[50]!, Colors.purple[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🃏 Your Hole Cards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardInput(probHole1Controller, 'H1'),
                      _buildCardInput(probHole2Controller, 'H2'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '🏛️ Community Cards (1-5)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildCardInput(probBoard1Controller, 'C1'),
                        _buildCardInput(probBoard2Controller, 'C2'),
                        _buildCardInput(probBoard3Controller, 'C3'),
                        _buildCardInput(probBoard4Controller, 'C4'),
                        _buildCardInput(probBoard5Controller, 'C5'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Players', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: playersController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Simulations', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: simController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : calculateProbability,
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.calculate, color: Colors.white),
                label: const Text('Calculate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple,
                disabledBackgroundColor: Colors.grey[400],
              ),
            ),
            if (result.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: resultType == 'error' ? Colors.red[50] : Colors.purple[50],
                  border: Border.all(
                    color: resultType == 'error' ? Colors.red[400]! : Colors.purple[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (resultType == 'error' ? Colors.red : Colors.purple).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      resultType == 'error' ? '❌ Error' : '📊 Win Probability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: resultType == 'error' ? Colors.red : Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompareTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Community cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyan[50]!, Colors.cyan[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan[400]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '🏛️ Community Cards (1-5)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildCardInput(boardC1Controller, 'C1'),
                        _buildCardInput(boardC2Controller, 'C2'),
                        _buildCardInput(boardC3Controller, 'C3'),
                        _buildCardInput(boardC4Controller, 'C4'),
                        _buildCardInput(boardC5Controller, 'C5'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Players side by side
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[400]!, width: 2.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '♠️ Player 1',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCardInput(p1Card1Controller, 'P1'),
                            _buildCardInput(p1Card2Controller, 'P2'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[50]!, Colors.orange[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[400]!, width: 2.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '♥️ Player 2',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCardInput(p2Card1Controller, 'P1'),
                            _buildCardInput(p2Card2Controller, 'P2'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: isLoading ? null : compareHands,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.compare, size: 24, color: Colors.white),
              label: const Text('COMPARE HANDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.indigo,
                disabledBackgroundColor: Colors.grey[400],
                elevation: 4,
              ),
            ),
            // Result
            if (result.isNotEmpty) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: resultType == 'error'
                        ? [Colors.red[50]!, Colors.red[100]!]
                        : resultType == 'winner'
                            ? [Colors.amber[50]!, Colors.amber[100]!]
                            : [Colors.purple[50]!, Colors.purple[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: resultType == 'error'
                        ? Colors.red[400]!
                        : resultType == 'winner'
                            ? Colors.amber[400]!
                            : Colors.purple[400]!,
                    width: 2.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (resultType == 'error'
                              ? Colors.red
                              : resultType == 'winner'
                                  ? Colors.amber
                                  : Colors.purple)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      resultType == 'error'
                          ? '❌ Error'
                          : resultType == 'winner'
                              ? '🎉 Result'
                              : '🤝 Tie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: resultType == 'error'
                            ? Colors.red
                            : resultType == 'winner'
                                ? Colors.amber[800]
                                : Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: resultType == 'error'
                            ? Colors.red[900]
                            : resultType == 'winner'
                                ? Colors.amber[900]
                                : Colors.purple[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
