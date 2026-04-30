// AI生成 - OCR 拍照导入页：拍照/选图 → 文字识别 → 转为闪卡或笔记
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/note_provider.dart';

class OcrImportPage extends ConsumerStatefulWidget {
  const OcrImportPage({super.key});
  @override
  ConsumerState<OcrImportPage> createState() => _OcrImportPageState();
}

class _OcrImportPageState extends ConsumerState<OcrImportPage> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  String _recognizedText = '';
  bool _isProcessing = false;
  File? _imageFile;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _pickAndRecognize(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1920);
      if (picked == null) return;

      setState(() {
        _isProcessing = true;
        _imageFile = File(picked.path);
      });

      final inputImage = InputImage.fromFilePath(picked.path);
      final result = await _recognizer.processImage(inputImage);

      setState(() {
        _recognizedText = result.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    }
  }

  void _importAsFlashcards() {
    if (_recognizedText.isEmpty) return;
    // 按行拆分，每两行一组（问题+答案）
    final lines = _recognizedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FlashcardImportSheet(
          lines: lines, deckProvider: ref.read(flashcardProvider.notifier)),
    );
  }

  void _importAsNote() {
    if (_recognizedText.isEmpty) return;
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存为笔记'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: '笔记标题'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final title =
                  titleCtrl.text.trim().isEmpty ? 'OCR 导入' : titleCtrl.text.trim();
              ref.read(noteProvider.notifier).addNote(
                    title: title,
                    content: _recognizedText,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已保存为笔记')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('OCR 拍照导入')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 拍照/选图区 ───
            Row(children: [
              Expanded(
                child: _actionCard(
                  theme,
                  '拍照识别',
                  Icons.camera_alt_rounded,
                  Colors.blue,
                  () => _pickAndRecognize(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  theme,
                  '从相册选择',
                  Icons.photo_library_rounded,
                  Colors.purple,
                  () => _pickAndRecognize(ImageSource.gallery),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ─── 图片预览 ───
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!,
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            // ─── 识别状态 ───
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在识别文字...'),
                    ],
                  ),
                ),
              ),

            // ─── 识别结果 ───
            if (_recognizedText.isNotEmpty && !_isProcessing) ...[
              Row(children: [
                Text('识别结果',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_recognizedText.split('\n').length} 行',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _recognizedText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 导入操作 ───
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _importAsFlashcards,
                    icon: const Icon(Icons.style_rounded, size: 18),
                    label: const Text('导入为闪卡'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importAsNote,
                    icon: const Icon(Icons.note_add_rounded, size: 18),
                    label: const Text('导入为笔记'),
                  ),
                ),
              ]),
            ],

            // ─── 空状态 ───
            if (_recognizedText.isEmpty && !_isProcessing && _imageFile == null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.document_scanner_rounded,
                        size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('拍照或选择图片以识别文字',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('支持中英文混合识别',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
      ThemeData theme, String label, IconData icon, Color c, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: c, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── 闪卡导入底部弹出 ───
class _FlashcardImportSheet extends StatefulWidget {
  final List<String> lines;
  final FlashcardNotifier deckProvider;
  const _FlashcardImportSheet(
      {required this.lines, required this.deckProvider});
  @override
  State<_FlashcardImportSheet> createState() => _FlashcardImportSheetState();
}

class _FlashcardImportSheetState extends State<_FlashcardImportSheet> {
  String _separator = 'everyTwo'; // everyTwo | tab | dash
  String? _selectedDeckId;
  final _newDeckCtrl = TextEditingController(text: 'OCR 导入');

  List<(String, String)> get _pairs {
    final lines = widget.lines;
    final pairs = <(String, String)>[];
    if (_separator == 'everyTwo') {
      for (int i = 0; i < lines.length - 1; i += 2) {
        pairs.add((lines[i], lines[i + 1]));
      }
    } else if (_separator == 'tab') {
      for (final line in lines) {
        final parts = line.split('\t');
        if (parts.length >= 2) {
          pairs.add((parts[0].trim(), parts.sublist(1).join(' ').trim()));
        }
      }
    } else {
      for (final line in lines) {
        final idx = line.indexOf(' - ');
        if (idx > 0) {
          pairs.add((line.substring(0, idx).trim(), line.substring(idx + 3).trim()));
        }
      }
    }
    return pairs;
  }

  void _doImport() {
    final pairs = _pairs;
    if (pairs.isEmpty) return;

    if (_selectedDeckId != null) {
      for (final (front, back) in pairs) {
        widget.deckProvider.addCard(_selectedDeckId!, front: front, back: back);
      }
    } else {
      widget.deckProvider.addDeck(name: _newDeckCtrl.text.trim().isEmpty
          ? 'OCR 导入'
          : _newDeckCtrl.text.trim());
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${pairs.length} 张闪卡')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = _pairs;

    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('导入为闪卡', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),

          // ─── 分隔方式选择 ───
          Text('分隔方式', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'everyTwo', label: Text('每两行')),
              ButtonSegment(value: 'tab', label: Text('Tab分隔')),
              ButtonSegment(value: 'dash', label: Text('短横线')),
            ],
            selected: {_separator},
            onSelectionChanged: (v) =>
                setState(() => _separator = v.first),
          ),
          const SizedBox(height: 12),

          // ─── 预览 ───
          Text('预览 (${pairs.length} 张)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: pairs.isEmpty
                ? const Center(child: Text('无法按此方式分组', style: TextStyle(fontSize: 12)))
                : ListView(
                    children: pairs.take(5).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Expanded(
                            child: Text(p.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        const Text(' → ', style: TextStyle(fontSize: 12)),
                        Expanded(
                            child: Text(p.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))),
                      ]),
                    )).toList(),
                  ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _newDeckCtrl,
            decoration: const InputDecoration(labelText: '新建卡组名称'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: pairs.isEmpty ? null : _doImport,
              child: Text('导入 ${pairs.length} 张闪卡'),
            ),
          ),
        ],
      ),
    );
  }
}
