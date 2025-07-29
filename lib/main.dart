import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(SudokuApp());
}

class SudokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Résolveur de Sudoku',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: SudokuSolver(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SudokuSolver extends StatefulWidget {
  @override
  _SudokuSolverState createState() => _SudokuSolverState();
}

class _SudokuSolverState extends State<SudokuSolver> {
  // Grille vide par défaut
  List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>>? solution;
  bool isLoading = false;
  List<List<TextEditingController>> controllers = [];

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs pour chaque cellule
    controllers = List.generate(
      9,
      (i) => List.generate(9, (j) => TextEditingController()),
    );
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Fonction pour vérifier si un nombre peut être placé à une position donnée
  bool isValid(List<List<int>> grid, int row, int col, int num) {
    // Vérifier la ligne
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == num) return false;
    }

    // Vérifier la colonne
    for (int x = 0; x < 9; x++) {
      if (grid[x][col] == num) return false;
    }

    // Vérifier le carré 3x3
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  // Algorithme de backtracking pour résoudre le Sudoku
  bool solveSudoku(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isValid(grid, i, j, num)) {
              grid[i][j] = num;
              if (solveSudoku(grid)) {
                return true;
              }
              grid[i][j] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  // Gérer les changements dans les cellules
  void handleCellChange(int row, int col, String value) {
    setState(() {
      if (value.isEmpty) {
        grid[row][col] = 0;
      } else {
        int? num = int.tryParse(value);
        if (num != null && num >= 1 && num <= 9) {
          grid[row][col] = num;
        }
      }
      solution = null; // Reset solution when grid changes
    });
  }

  // Résoudre le Sudoku
  Future<void> handleSolve() async {
    setState(() {
      isLoading = true;
    });

    // Ajouter un délai pour l'animation de chargement
    await Future.delayed(Duration(milliseconds: 100));

    List<List<int>> gridCopy = grid.map((row) => List<int>.from(row)).toList();

    if (solveSudoku(gridCopy)) {
      setState(() {
        solution = gridCopy;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Aucune solution trouvée pour cette grille !'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Réinitialiser la grille
  void handleReset() {
    setState(() {
      grid = List.generate(9, (_) => List.filled(9, 0));
      solution = null;
      // Vider tous les contrôleurs
      for (var row in controllers) {
        for (var controller in row) {
          controller.clear();
        }
      }
    });
  }

  // Appliquer la solution à la grille
  void applySolution() {
    if (solution != null) {
      setState(() {
        grid = solution!.map((row) => List<int>.from(row)).toList();
        solution = null;
        // Mettre à jour les contrôleurs
        for (int i = 0; i < 9; i++) {
          for (int j = 0; j < 9; j++) {
            controllers[i][j].text = grid[i][j] == 0
                ? ''
                : grid[i][j].toString();
          }
        }
      });
    }
  }

  // Charger un exemple de grille
  void loadExample() {
    List<List<int>> exampleGrid = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ];

    setState(() {
      grid = exampleGrid;
      solution = null;
      // Mettre à jour les contrôleurs
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          controllers[i][j].text = grid[i][j] == 0 ? '' : grid[i][j].toString();
        }
      }
    });
  }

  // Widget pour une cellule individuelle
  Widget buildSudokuCell(int row, int col) {
    bool isThickBottomBorder = (row + 1) % 3 == 0 && row < 8;
    bool isThickRightBorder = (col + 1) % 3 == 0 && col < 8;
    bool isSolution = solution != null && solution![row][col] != grid[row][col];

    return Container(
      width: 35,
      height: 35,
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSolution ? Colors.green.shade100 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade600,
            width: isThickBottomBorder ? 3 : 1,
          ),
          right: BorderSide(
            color: Colors.grey.shade600,
            width: isThickRightBorder ? 3 : 1,
          ),
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          left: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TextField(
        controller: controllers[row][col],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isSolution ? Colors.green.shade700 : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => handleCellChange(row, col, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Résolveur de Sudoku',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Grille de Sudoku
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(
                  9,
                  (row) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      9,
                      (col) => buildSudokuCell(row, col),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Boutons d'action
            Column(
              children: [
                // Bouton Résoudre
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : handleSolve,
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.play_arrow, size: 24),
                    label: Text(
                      isLoading ? 'Résolution...' : 'Résoudre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Autres boutons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: handleReset,
                        icon: Icon(Icons.refresh, size: 20),
                        label: Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loadExample,
                        icon: Icon(Icons.description, size: 20),
                        label: Text('Exemple'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (solution != null) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: applySolution,
                      icon: Icon(Icons.check, size: 24),
                      label: Text(
                        'Appliquer la solution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 30),

            // Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Saisissez les chiffres connus (1-9)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    '• Utilisez "Exemple" pour une grille de test',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    '• Les cases vertes montrent la solution trouvée',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
