import 'package:flutter/material.dart';

import '../../../theme.dart';

class CategoryPickerSheet extends StatefulWidget {
  final List<String> allCategories;
  final String? currentCategory;

  const CategoryPickerSheet({
    super.key,
    required this.allCategories,
    this.currentCategory,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String _query = '';
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.allCategories;
  }

  void _onSearch(String value) {
    setState(() {
      _query = value.toLowerCase();
      _filtered = widget.allCategories
          .where((String c) => c.toLowerCase().contains(_query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pick a Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      'Free Draw',
                      style: TextStyle(color: AppTheme.brandOrange),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filtered.length,
                itemBuilder: (BuildContext context, int index) {
                  final String category = _filtered[index];
                  final bool isSelected =
                      widget.currentCategory?.toLowerCase() ==
                      category.toLowerCase();

                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.brandOrange.withAlpha(30)
                            : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.brush,
                        size: 18,
                        color: isSelected
                            ? AppTheme.brandOrange
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      category,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.brandOrange
                            : colors.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppTheme.brandOrange,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, category),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
