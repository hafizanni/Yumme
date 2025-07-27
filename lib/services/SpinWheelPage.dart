import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class SpinWheelPage extends StatefulWidget {
  const SpinWheelPage({Key? key}) : super(key: key);

  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage> {
  final StreamController<int> _selected = StreamController<int>();
  int? _lastSelected;
  int? _pendingSelected;

  List<String> names = [
    '???',
    '???',
    '???',
    '???',
    '???',
    '???',
    '???',
    '???',
  ];

  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.green,
  ];

  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _selected.close();
    _nameController.dispose();
    super.dispose();
  }

  void _spin() {
    if (names.isEmpty) return;
    final random = (DateTime.now().millisecondsSinceEpoch) % names.length;
    _pendingSelected = random;
    _selected.add(random);
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Names'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < names.length; i++)
                      ListTile(
                        title: Text(names[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setStateDialog(() {
                              names.removeAt(i);
                              if (_lastSelected != null && _lastSelected! >= names.length) {
                                _lastSelected = null;
                              }
                            });
                            setState(() {});
                          },
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Add new name',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            final newName = _nameController.text.trim();
                            if (newName.isNotEmpty && !names.contains(newName)) {
                              setStateDialog(() {
                                names.add(newName);
                                _nameController.clear();
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFf7971e),
              Color(0xFFffd200),
              Color(0xFF21d4fd),
              Color(0xFFb721ff),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child: Text(
                      'Lets Decide Your Restaurant🥳!',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 18,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: const BorderSide(color: Colors.white70, width: 2),
                    ),
                    color: Colors.white.withOpacity(0.85),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: SizedBox(
                        height: 320,
                        width: 320,
                        child: names.isEmpty
                            ? const Center(
                                child: Text(
                                  'No names.\nPlease add some!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 20,
                                  ),
                                ),
                              )
                            : FortuneWheel(
                                selected: _selected.stream,
                                animateFirst: false,
                                onAnimationEnd: () {
                                  setState(() {
                                    _lastSelected = _pendingSelected;
                                  });
                                },
                                items: [
                                  for (int i = 0; i < names.length; i++)
                                    FortuneItem(
                                      style: FortuneItemStyle(
                                        color: colors[i % colors.length].withOpacity(0.85),
                                        borderColor: Colors.white,
                                        borderWidth: 3,
                                      ),
                                      child: RotatedBox(
                                        quarterTurns: 1,
                                        child: Text(
                                          names[i],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: (i % 4 == 0 || i % 4 == 3)
                                                ? Colors.white
                                                : Colors.black,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2,
                                                color: Colors.black.withOpacity(0.3),
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                indicators: const [
                                  FortuneIndicator(
                                    alignment: Alignment.topCenter,
                                    child: TriangleIndicator(
                                      color: Colors.amber,
                                      width: 32,
                                      height: 32,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          boxShadow: names.isEmpty
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.6),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: names.isEmpty ? null : _spin,
                          icon: const Icon(Icons.casino, size: 28),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 32.0),
                            child: Text(
                              'SPIN',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, color: Colors.amber),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          backgroundColor: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: (_lastSelected != null && names.isNotEmpty && _lastSelected! < names.length)
                        ? Column(
                            key: ValueKey(_lastSelected),
                            children: [
                              const Text(
                                'Selected:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 32),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  names[_lastSelected!],
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
