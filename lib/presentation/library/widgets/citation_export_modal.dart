import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/citation_generator.dart';
import '../../../data/models/book.dart';
import '../library_provider.dart';

class CitationExportModal extends StatefulWidget {
  final BookModel book;
  final LibraryProvider provider;

  const CitationExportModal({
    super.key,
    required this.book,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context,
    BookModel book,
    LibraryProvider provider,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CitationExportModal(book: book, provider: provider),
    );
  }

  @override
  State<CitationExportModal> createState() => _CitationExportModalState();
}

class _CitationExportModalState extends State<CitationExportModal> {
  late CitationStyle _activeStyle;

  @override
  void initState() {
    super.initState();
    _activeStyle = widget.provider.selectedCitationStyle;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final citation = CitationGenerator.format(widget.book, _activeStyle);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.format_quote_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Citation Exporter',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Style Selector Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CitationStyle.values.map((style) {
                    final isSelected = _activeStyle == style;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          style.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _activeStyle = style);
                            widget.provider.setCitationStyle(style);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Formatted Citation Code Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_activeStyle.displayName.toUpperCase()} REFERENCE',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          tooltip: 'Copy to Clipboard',
                          onPressed: () async {
                            await widget.provider.copyTextToClipboard(citation);
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Copied ${_activeStyle.displayName} reference to clipboard.',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      citation,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 11,
                        fontFamily: _activeStyle == CitationStyle.bibtex
                            ? 'monospace'
                            : null,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Metadata Pill Row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildMetaPill('Publisher', widget.book.publisher, colors),
                  _buildMetaPill(
                    'Year',
                    '${widget.book.publicationYear}',
                    colors,
                  ),
                  _buildMetaPill('Cite Key', widget.book.citationKey, colors),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(
                        'Copy Markdown (.md)',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () async {
                        final md =
                            CitationGenerator.generateMarkdownBibliography(
                              books: [widget.book],
                              style: _activeStyle,
                              title: 'Citation: ${widget.book.title}',
                            );
                        await widget.provider.copyTextToClipboard(md);
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Copied Markdown citation block to clipboard.',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Copy Citation',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () async {
                        await widget.provider.copyTextToClipboard(citation);
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Copied ${_activeStyle.displayName} citation to clipboard.',
                          );
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaPill(String label, String value, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
