import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.light.index;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Average Price Calculator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.teal.shade600,
          onPrimary: Colors.white,
          secondary: Colors.green.shade600,
          onSecondary: Colors.white,
          background: Colors.white,
          onBackground: Colors.black87,
          surface: Colors.teal.shade50,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade600,
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          onPrimary: Colors.white,
          secondary: Colors.blue,
          onSecondary: Colors.white,
          background: const Color(0xFF121212),
          onBackground: Colors.white,
          surface: const Color(0xFF2D2D2D),
          onSurface: Colors.white,
          error: Colors.red.shade400,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.teal,
          selectionColor: Colors.teal.withOpacity(0.3),
          selectionHandleColor: Colors.teal,
        ),
        scaffoldBackgroundColor: const Color(0xFF2D2D2D),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2D2D2D),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.teal),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          labelStyle: TextStyle(color: Colors.teal),
          hintStyle: TextStyle(color: Colors.teal.withOpacity(0.7)),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF363636),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF00C853),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF404040),
        ),
      ),
      themeMode: _themeMode,
      home: StockQuantityCalculator(
        title: 'Stock Average Price Calculator',
        onThemeChange: _saveThemePreference,
      ),
    );
  }
}

class CalculationEntry {
  final int quantity;
  final double price;
  final double total;
  final DateTime timestamp;

  CalculationEntry({
    required this.quantity,
    required this.price,
    required this.total,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'price': price,
      'total': total,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static CalculationEntry fromMap(Map<String, dynamic> map) {
    return CalculationEntry(
      quantity: map['quantity'],
      price: map['price'],
      total: map['total'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  static CalculationEntry fromJson(String jsonString) {
    return fromMap(json.decode(jsonString));
  }
}

class StockQuantityCalculator extends StatefulWidget {
  final Function(ThemeMode) onThemeChange;
  final String title;

  const StockQuantityCalculator({
    Key? key,
    required this.onThemeChange,
    this.title = 'Stock Average Price Calculator',
  }) : super(key: key);

  @override
  _StockQuantityCalculatorState createState() => _StockQuantityCalculatorState();
}

class _StockQuantityCalculatorState extends State<StockQuantityCalculator> {
  final List<CalculationEntry> _stockEntries = [];
  final List<CalculationEntry> _calculationHistory = [];
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  double _totalValue = 0.0;
  int _totalQuantity = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
   _loadCurrentEntries();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('permanent_history');
    
    if (historyJson != null) {
      setState(() {
        _calculationHistory.clear();
        _calculationHistory.addAll(
          historyJson.map((entry) => CalculationEntry.fromJson(entry)).toList()
        );
      });
    }
  }

  Future<void> _loadCurrentEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getStringList('current_entries');
    
    if (currentJson != null) {
      setState(() {
        _stockEntries.clear();
        _stockEntries.addAll(
          currentJson.map((entry) => CalculationEntry.fromJson(entry)).toList()
        );
        
        _totalValue = 0.0;
        _totalQuantity = 0;
        for (var entry in _stockEntries) {
          _totalValue += entry.total;
          _totalQuantity += entry.quantity;
        }
      });
    }
  }

  Future<void> _saveCurrentEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = _stockEntries
        .map((entry) => entry.toJson())
        .toList();
    await prefs.setStringList('current_entries', currentJson);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _calculationHistory
        .map((entry) => entry.toJson())
        .toList();
    await prefs.setStringList('permanent_history', historyJson);
  }

  void _addEntry() {
    if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text);
      final price = double.tryParse(_priceController.text);

      if (quantity != null && price != null) {
        final total = quantity * price;
        final entry = CalculationEntry(
          quantity: quantity,
          price: price,
          total: total,
          timestamp: DateTime.now(),
        );

        setState(() {
          _stockEntries.add(entry);
          _calculationHistory.add(entry);
          _totalValue += total;
          _totalQuantity += quantity;
          _quantityController.clear();
          _priceController.clear();
        });
        _saveCurrentEntries();
        _saveHistory();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Confirmation'),
          content: const Text('Are you sure you want to reset current calculations? History will be preserved.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                setState(() {
                  _stockEntries.clear();
                  _totalValue = 0.0;
                  _totalQuantity = 0;
                  _quantityController.clear();
                  _priceController.clear();
                });
                _saveCurrentEntries();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteEntry(int index) {
    if(index < 0 || index >= _stockEntries.length) return;
    
    setState(() {
      var entry = _stockEntries[index];
      _totalValue -= entry.total;
      _totalQuantity -= entry.quantity;
      _stockEntries.removeAt(index);
    });
    _saveCurrentEntries();
  }

  double get overallAverageValue {
    return _totalQuantity > 0 ? _totalValue / _totalQuantity : 0.0;
  }

  Widget _buildHistoryEntry(CalculationEntry entry, int index) {
    // Format timestamp to dd-mm-yyyy hh:mm:ss
    String formattedDate = "${entry.timestamp.day.toString().padLeft(2, '0')}-"
        "${entry.timestamp.month.toString().padLeft(2, '0')}-"
        "${entry.timestamp.year} "
        "${entry.timestamp.hour.toString().padLeft(2, '0')}:"
        "${entry.timestamp.minute.toString().padLeft(2, '0')}:"
        "${entry.timestamp.second.toString().padLeft(2, '0')}";

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 15,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity: ${entry.quantity}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                'Price: ₹${entry.price.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                'Total: ₹${entry.total.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade400,  // Brighter green for dark theme
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, 
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.red.shade400
                : Colors.red,
          ),
          onPressed: () => _deleteEntry(index),
        ),
      ],
    );
  }

 String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}-'
         '${dateTime.month.toString().padLeft(2, '0')}-'
         '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
         '${dateTime.minute.toString().padLeft(2, '0')}:'
         '${dateTime.second.toString().padLeft(2, '0')}';
}

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Scaffold(
              appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  title: const Text('Calculation History'),
                  backgroundColor: Colors.transparent, // Make background transparent
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete All History'),
                            content: const Text('Do you want to delete all history entries?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  setDialogState(() {
                                    _calculationHistory.clear();
                                  });
                                  _saveHistory();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.teal.shade50,
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.blue.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListView.builder(
                  itemCount: _calculationHistory.length,
                  itemBuilder: (context, index) {
                    final entry = _calculationHistory[_calculationHistory.length - 1 - index];
                    final serialNo = _calculationHistory.length - index; // Calculate serial number
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: /*Theme.of(context).brightness == Brightness.dark
                              ? Colors.black*/                              //For dark theme
                              Colors.white,
                          child: Text(
                            '$serialNo',
                            style: TextStyle(
                              color: /*Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white*/                              //For dark theme
                                   Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: ${entry.quantity}'),
                            Text('Price: ₹${entry.price}'),
                            Text(
                              'Total: ₹${entry.total}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(_formatDateTime(entry.timestamp),
                        style: const TextStyle(
                          fontStyle: FontStyle.italic, // Set font style to italic
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _calculationHistory.removeAt(_calculationHistory.length - 1 - index);
                              _saveHistory();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 400 ? 20 : 24;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Builder(
            builder: (BuildContext context) {
              return AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                title: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              );
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Stock Calculator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Theme section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light Theme'),
              onTap: () {
                widget.onThemeChange(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Theme'),
              onTap: () {
                widget.onThemeChange(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: const Text('System Default'),
              onTap: () {
                widget.onThemeChange(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            // History section
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                _showHistoryDialog(context);
              },
            ),
            const Divider(),
            // Links section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Links',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.support),
              title: const Text('Support'),
              onTap: () {
                launchUrl(Uri.parse('https://github.com/chinmaynkr'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('LinkedIn'),
              onTap: () {
                launchUrl(Uri.parse('https://www.linkedin.com/in/chinmay-nerkar'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              onTap: () {
                launchUrl(Uri.parse('https://github.com/chinmaynkr'));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Stock Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Enter Quantity',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Enter Price Per Unit',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _addEntry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade700.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add Entry',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade700.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Total Invested Value section
              Card(
                elevation: 6,
                shadowColor: Colors.teal.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.teal.shade50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.teal,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Invested Value',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          Text(
                            '₹${_totalValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Overall Average Value section
              Card(
                elevation: 6,
                shadowColor: Colors.blue.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Average Value',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            '₹${overallAverageValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // List of Entries
              _stockEntries.isEmpty
                  ? const Center(child: Text("No entries added"))
                  : Column(
                      children: _stockEntries.asMap().entries.map((entry) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF363636)  // Dark theme color
                                : Colors.teal.shade50,     // Light theme color
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.teal.shade300.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          child: _buildHistoryEntry(entry.value, entry.key),
                        );
                      }).toList(),
                    ),
            ],
          ),
          
        ),
      ),
    );
  }
}