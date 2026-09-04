import 'package:flutter/material.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/features/qa/domain/models/question.dart';

/// Las preguntas publicas de una publicacion (requisito 5).
///
/// Quien mira puede preguntar; solo el dueno ve el campo de respuesta, y solo
/// en las preguntas que aun no ha respondido.
class QuestionList extends StatefulWidget {
  const QuestionList({
    super.key,
    required this.questions,
    required this.isOwner,
    required this.onAsk,
    required this.onAnswer,
  });

  final List<Question> questions;
  final bool isOwner;
  final Future<void> Function(String text) onAsk;
  final Future<void> Function(Question question, String text) onAnswer;

  @override
  State<QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends State<QuestionList> {
  final _ask = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ask.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    await widget.onAsk(text);
    if (!mounted) return;
    _ask.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preguntas publicas (${widget.questions.length})',
            style: text.titleMedium),
        const SizedBox(height: 12),
        if (!widget.isOwner) ...[
          TextField(
            controller: _ask,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escribe una pregunta publica',
              suffixIcon: IconButton(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.questions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Todavia nadie ha preguntado.',
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final question in widget.questions)
          _QuestionTile(
            question: question,
            isOwner: widget.isOwner,
            onAnswer: (value) => widget.onAnswer(question, value),
          ),
      ],
    );
  }
}

class _QuestionTile extends StatefulWidget {
  const _QuestionTile({
    required this.question,
    required this.isOwner,
    required this.onAnswer,
  });

  final Question question;
  final bool isOwner;
  final Future<void> Function(String text) onAnswer;

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  final _answer = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final question = widget.question;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(question.askerName, style: text.labelLarge),
              ),
              Text(
                Formatters.relative(question.createdAt),
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(question.text, style: text.bodyMedium),
          if (question.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${question.answer!.responderName} respondio',
                    style: text.labelMedium?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(question.answer!.text, style: text.bodyMedium),
                ],
              ),
            ),
          ] else if (widget.isOwner) ...[
            const SizedBox(height: 8),
            if (!_open)
              TextButton.icon(
                onPressed: () => setState(() => _open = true),
                icon: const Icon(Icons.reply),
                label: const Text('Responder en publico'),
              )
            else
              TextField(
                controller: _answer,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tu respuesta publica',
                  suffixIcon: IconButton(
                    onPressed: () async {
                      await widget.onAnswer(_answer.text);
                      if (mounted) setState(() => _open = false);
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
