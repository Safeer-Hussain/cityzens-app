import 'package:flutter/material.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/models/book.dart';
import '../library_provider.dart';

class BookDetailSheet extends StatelessWidget {
  final BookModel book;
  final LibraryProvider provider;

  const BookDetailSheet({
    super.key,
    required this.book,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      book.coverAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.category,
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${book.author}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ISBN: ${book.isbn}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaColumn(
                      label: 'Shelf Location',
                      value: book.shelfLocation,
                      icon: Icons.shelves,
                      colors: colors,
                    ),
                    Container(height: 28, width: 1, color: colors.outlineVariant),
                    _buildMetaColumn(
                      label: 'Availability',
                      value: '${book.availableCopies} / ${book.totalCopies} Copies',
                      icon: Icons.inventory_2_outlined,
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Digital Abstract',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.abstractText,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Table of Contents (${book.tableOfContents.length} Sections)',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: book.tableOfContents.length,
                  separatorBuilder: (_, _) => Divider(color: colors.outlineVariant, height: 1),
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 14, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              book.tableOfContents[idx],
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: colors.primary),
                      ),
                      icon: Icon(
                        book.isReserved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                        color: colors.primary,
                        size: 18,
                      ),
                      label: Text(
                        book.isReserved ? 'Reserved' : 'Reserve Copy',
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        await provider.toggleReserve(book.id);
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            book.isReserved ? 'Reservation removed for "${book.title}".' : 'Reserved copy of "${book.title}".',
                          );
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: book.isAvailable ? colors.primary : colors.surfaceContainerHighest,
                        foregroundColor: book.isAvailable ? colors.onPrimary : colors.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(
                        book.isAvailable ? 'Check Out Book' : 'Waitlist Only',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: book.isAvailable
                          ? () async {
                              await provider.checkoutBook(book.id, 'CTZ-2026-8842');
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Checked out "${book.title}". 14-day loan recorded.',
                                );
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaColumn({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colors,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            ),
            Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
