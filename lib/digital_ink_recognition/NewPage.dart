import 'package:examinator/digital_ink_recognition/canvasInstructions.dart';
import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class Signature extends CustomPainter {
  final Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background lines
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 0.5;

    final double lineHeight =
        35; // Adjust this value to change the spacing between lines

    for (double i = lineHeight; i < size.height; i += lineHeight) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // Draw ink strokes
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final start = stroke.points[i];
        final end = stroke.points[i + 1];
        canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DigitalInkView extends StatefulWidget {
  final int questionNumber;
  final List<Ink>? initialPages;
  final List<List<StrokePoint>>? initialPointsLists;

  DigitalInkView({
    required this.questionNumber,
    this.initialPages,
    this.initialPointsLists,
  });

  @override
  State<DigitalInkView> createState() => _DigitalInkViewState();
}

class _DigitalInkViewState extends State<DigitalInkView> {
  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  var _language = 'en';
  var _digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'en');
  List<Ink> _pages = [];
  List<List<StrokePoint>> _pointsList = [];
  int _currentPageIndex = 0;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _downloadModel();
    _pages = widget.initialPages ?? [Ink()];
    _pointsList = widget.initialPointsLists ?? [[]];
  }

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _updatePagesInNavigator();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Answer ${widget.questionNumber}'),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(
                        color: Colors.black), // Adjust style as needed
                  ),
                  // SizedBox(width: 2), // Add some space between the text and the icon
                  IconButton(
                      icon: Icon(Icons.help_outline),
                      onPressed: () {
                        instruction().showInstructions(context);
                      }),
                ],
              ),
            ),
            IconButton(
              icon: Tooltip(
                message: 'Recognize Text',
                child: Icon(Icons.center_focus_strong),
              ),
              onPressed: _recogniseTextManually,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Page ${_currentPageIndex + 1}/${_pages.length}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onPanStart: (DragStartDetails details) {
                    _pages[_currentPageIndex].strokes.add(Stroke());
                    _pointsList[_currentPageIndex] = [];
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    setState(() {
                      final RenderObject? object = context.findRenderObject();
                      final localPosition = (object as RenderBox?)
                          ?.globalToLocal(details.localPosition);
                      if (localPosition != null) {
                        _pointsList[_currentPageIndex].add(StrokePoint(
                          x: localPosition.dx,
                          y: localPosition.dy,
                          t: DateTime.now().millisecondsSinceEpoch,
                        ));
                      }
                      if (_pages[_currentPageIndex].strokes.isNotEmpty) {
                        _pages[_currentPageIndex].strokes.last.points =
                            _pointsList[_currentPageIndex];
                      }
                    });
                  },
                  onPanEnd: (DragEndDetails details) {
                    _recognizeTextOnEnd();
                  },
                  child: CustomPaint(
                    painter: Signature(ink: _pages[_currentPageIndex]),
                    size: Size.infinite,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(
                    message: 'Clear',
                    child: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: _clearPad,
                    ),
                  ),
                  Tooltip(
                    message: 'Add Page',
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addPage,
                    ),
                  ),
                  Tooltip(
                    message: 'Previous Page',
                    child: IconButton(
                      icon: Icon(Icons.navigate_before),
                      onPressed: () {
                        if (_currentPageIndex > 0) {
                          setState(() {
                            _currentPageIndex--;
                          });
                        }
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Next Page',
                    child: IconButton(
                      icon: Icon(Icons.navigate_next),
                      onPressed: () {
                        if (_currentPageIndex < _pages.length - 1) {
                          setState(() {
                            _currentPageIndex++;
                          });
                        }
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Delete Page',
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deletePage,
                    ),
                  ),
                  Tooltip(
                    message: 'Undo Stroke',
                    child: IconButton(
                      icon: Icon(Icons.undo),
                      onPressed: _undoStroke,
                    ),
                  ),
                ],
              ),
              if (_recognizedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Digital Text: $_recognizedText',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _undoStroke() {
    setState(() {
      if (_pages[_currentPageIndex].strokes.isNotEmpty) {
        _pages[_currentPageIndex].strokes.removeLast();
        // Optionally, update recognized text or any other state affected by stroke removal.
      }
    });
  }

  void _recogniseTextManually() async {
    if (_pages[_currentPageIndex].strokes.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Recognizing'),
        ),
        barrierDismissible: true,
      );
      try {
        final candidates =
            await _digitalInkRecognizer.recognize(_pages[_currentPageIndex]);
        setState(() {
          _recognizedText = candidates[0].text;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
      Navigator.pop(context);
    }
  }

  void _recognizeTextOnEnd() async {
    if (_pointsList[_currentPageIndex].isNotEmpty) {
      // showDialog(
      //   context: context,
      //   builder: (context) => const AlertDialog(
      //     title: Text('Recognizing'),
      //   ),
      //   barrierDismissible: true,
      // );
      try {
        final candidates =
            await _digitalInkRecognizer.recognize(_pages[_currentPageIndex]);
        setState(() {
          _recognizedText = candidates[0].text;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
      // Navigator.pop(context);
    }
  }

  Future<void> _downloadModel() async {
    await _modelManager.downloadModel(_language);
  }

  void _clearPad() {
    setState(() {
      _pages[_currentPageIndex].strokes.clear();
      _pointsList[_currentPageIndex].clear();
      _recognizedText = '';
    });
  }

  void _addPage() {
    setState(() {
      _pages.add(Ink());
      _pointsList.add([]);
      _currentPageIndex = _pages.length - 1;
    });
  }

  void _deletePage() {
    setState(() {
      if (_pages.length > 1) {
        _pages.removeAt(_currentPageIndex);
        _pointsList.removeAt(_currentPageIndex);
        if (_currentPageIndex >= _pages.length) {
          _currentPageIndex = _pages.length - 1;
        }
      }
    });
  }

  void _updatePagesInNavigator() {
    Navigator.pop(context, [_pages, _pointsList]);
  }
}
