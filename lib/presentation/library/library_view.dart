import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/models/book.dart';
import '../library/library_provider.dart';
import 'widgets/book_detail_sheet.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const List<String> _categories = [
    'All',
    'Available Now',
    'Software Engineering',
    'AI & ML',
    'Cloud & Security',
    'Systems & Architecture',
    'Reserved',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, LibraryProvider provider) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      provider.setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<LibraryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: colors.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_library_reserve',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
            label: Text(
              'Active Loans (${provider.borrowedCount})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              _tabController.animateTo(1);
            },
          ),
          body: Column(
            children: [
              _buildTopTabBar(colors),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    isLandscape
                        ? _buildCatalogLandscape(context, provider, colors)
                        : _buildCatalogPortrait(context, provider, colors),
                    _buildActiveLoansView(context, provider, colors),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabBar(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: colors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Catalog & Research Repository'),
          Tab(text: 'Active Borrowed Records'),
        ],
      ),
    );
  }

  Widget _buildCatalogPortrait(
    BuildContext context,
    LibraryProvider provider,
    ColorScheme colors,
  ) {
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => provider.loadLibraryData(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSearchBar(provider, colors),
          const SizedBox(height: 10),
          _buildCategoryChips(provider, colors),
          const SizedBox(height: 12),
          Text(
            'MATCHING CATALOG TITLES (${provider.books.length})',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...provider.books.map((book) => _buildBookCard(context, book, provider, colors)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCatalogLandscape(
    BuildContext context,
    LibraryProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Search, categories, summary
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(provider, colors),
                const SizedBox(height: 8),
                _buildCategoryChips(provider, colors),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Catalog Stats',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Seeded Titles: 42 peer-reviewed reference works.',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active Loans: ${provider.borrowedCount} volumes currently borrowed.',
                        style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: Grid of books with safe mainAxisExtent
        Expanded(
          flex: 5,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 145, // Crucial rule: Explicit mainAxisExtent so cards never collapse
              mainAxisSpacing: 8,
            ),
            itemCount: provider.books.length,
            itemBuilder: (context, index) {
              return _buildBookCard(context, provider.books[index], provider, colors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(LibraryProvider provider, ColorScheme colors) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => _onSearchChanged(val, provider),
      decoration: InputDecoration(
        hintText: 'Search by title, author, or ISBN-13...',
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: colors.onSurfaceVariant, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: colors.onSurfaceVariant, size: 18),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(LibraryProvider provider, ColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = provider.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(cat),
              labelStyle: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) => provider.setCategory(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    BookModel book,
    LibraryProvider provider,
    ColorScheme colors,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openBookDetailSheet(context, book, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                book.coverAsset,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.category,
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          book.isReserved ? Icons.bookmark_added : Icons.bookmark_border_rounded,
                          color: book.isReserved ? colors.primary : colors.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () async {
                          await provider.toggleReserve(book.id);
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              book.isReserved ? 'Reservation removed for "${book.title}".' : 'Reserved "${book.title}".',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        book.shelfLocation,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        book.isAvailable
                            ? '${book.availableCopies} Available'
                            : 'Waitlist',
                        style: TextStyle(
                          color: book.isAvailable ? colors.secondary : colors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLoansView(
    BuildContext context,
    LibraryProvider provider,
    ColorScheme colors,
  ) {
    if (provider.activeLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No Active Borrowed Records',
              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Explore the catalog to borrow or reserve computer science volumes.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final totalFine = provider.totalOverdueFines;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (totalFine > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Outstanding Overdue Fine: \$${totalFine.toStringAsFixed(2)} (\$0.50/day policy). Renew now to waive further penalties.',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'CURRENTLY BORROWED TITLES (${provider.activeLoans.length})',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...provider.activeLoans.map((item) {
          final days = item.loan.daysRemaining;
          final isOver = item.loan.isOverdue;
          final fine = item.loan.calculatedFine;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOver ? colors.error : colors.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        item.book.coverAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'By ${item.book.author}',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOver
                                      ? colors.error.withValues(alpha: 0.15)
                                      : colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOver
                                      ? 'OVERDUE by ${days.abs()} Day${days.abs() > 1 ? "s" : ""}'
                                      : 'Due in $days Days',
                                  style: TextStyle(
                                    color: isOver ? colors.error : colors.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isOver && fine > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Fine: \$${fine.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: colors.error,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.update_rounded, size: 16),
                        label: Text(
                          'Renew (+14 Days)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: () async {
                          final success = await provider.renewLoan(item.loan.id);
                          if (success && context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Loan extended by 14 days for "${item.book.title}".',
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        icon: Icon(Icons.assignment_return_outlined, size: 16, color: colors.onSurface),
                        label: Text(
                          'Return Book',
                          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        onPressed: () async {
                          final success = await provider.returnBook(item.loan.id, item.book.id);
                          if (success && context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Returned "${item.book.title}". Library catalog updated.',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  void _openBookDetailSheet(
    BuildContext context,
    BookModel book,
    LibraryProvider provider,
  ) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BookDetailSheet(book: book, provider: provider);
      },
    );
  }
}
