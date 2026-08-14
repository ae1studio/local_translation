import 'package:flutter/material.dart';
import 'package:local_translation/local_translation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = LocalTranslation();
  final _input = TextEditingController(
    text: 'Hello world\nBonjour le monde\nHola mundo',
  );
  final _target = TextEditingController(text: 'en');
  final _source = TextEditingController();

  bool _supported = false;
  String _status = 'Checking support...';
  String _output = '';

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  @override
  void dispose() {
    _input.dispose();
    _target.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _checkSupport() async {
    var supported = false;
    try {
      supported = await _plugin.isSupported();
    } catch (_) {
      supported = false;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _supported = supported;
      _status = supported
          ? 'Translation is available'
          : 'Translation is not available on this device';
    });
  }

  List<String> get _lines {
    return _input.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String? get _sourceLanguage {
    final value = _source.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _detectOne() async {
    final lines = _lines;
    if (lines.isEmpty) {
      return;
    }
    try {
      final detection = await _plugin.detectLanguage(lines.first);
      setState(() {
        _output =
            '${lines.first} → ${detection.languageCode ?? 'unknown'} '
            '(${detection.confidence.toStringAsFixed(2)})';
      });
    } on LocalTranslationException catch (error) {
      setState(() => _output = error.toString());
    }
  }

  Future<void> _detect() async {
    try {
      final results = await _plugin.detectLanguages(_lines);
      setState(() {
        _output = results
            .asMap()
            .entries
            .map((entry) {
              final detection = entry.value;
              final text = _lines[entry.key];
              return '$text → ${detection.languageCode ?? 'unknown'} '
                  '(${detection.confidence.toStringAsFixed(2)})';
            })
            .join('\n');
      });
    } on LocalTranslationException catch (error) {
      setState(() => _output = error.toString());
    }
  }

  Future<void> _translateOne() async {
    final lines = _lines;
    if (lines.isEmpty) {
      return;
    }
    try {
      final result = await _plugin.translate(
        lines.first,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _target.text.trim(),
      );
      setState(() {
        _output = '${result.sourceText} → ${result.translatedText}';
      });
    } on LocalTranslationException catch (error) {
      setState(() => _output = error.toString());
    }
  }

  Future<void> _translateMany() async {
    try {
      final results = await _plugin.translateBatch(
        _lines,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _target.text.trim(),
      );
      setState(() {
        _output = results
            .map((result) => '${result.sourceText} → ${result.translatedText}')
            .join('\n');
      });
    } on LocalTranslationException catch (error) {
      setState(() => _output = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Local translation')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_status),
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Text (one string per line)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _source,
              decoration: const InputDecoration(
                labelText: 'Source language (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              decoration: const InputDecoration(
                labelText: 'Target language',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _detectOne,
                  child: const Text('Detect first'),
                ),
                ElevatedButton(
                  onPressed: _detect,
                  child: const Text('Detect all'),
                ),
                ElevatedButton(
                  onPressed: _supported ? _translateOne : null,
                  child: const Text('Translate first'),
                ),
                ElevatedButton(
                  onPressed: _supported ? _translateMany : null,
                  child: const Text('Translate all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_output),
          ],
        ),
      ),
    );
  }
}
