import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryPicker extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selected;

  const CategoryPicker({
    super.key,
    required this.allCategories,
    required this.selected,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  late List<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.allCategories;
    final String lower = _query.toLowerCase();
    return widget.allCategories
        .where((String c) => c.toLowerCase().contains(lower))
        .toList();
  }

  void _toggle(String category) {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  void _selectAll() {
    setState(() => _selected = List<String>.from(widget.allCategories));
  }

  void _clearAll() {
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withAlpha(80),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (String value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_selected.length} of ${widget.allCategories.length} selected',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: _selectAll, child: const Text('All')),
                const SizedBox(width: 4),
                TextButton(onPressed: _clearAll, child: const Text('None')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (BuildContext context, int index) {
                final String category = _filtered[index];
                final bool isSelected = _selected.contains(category);
                return ListTile(
                  title: Text(_formatLabel(category)),
                  dense: true,
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggle(category),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _toggle(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String category) {
    return category
        .split(' ')
        .map(
          (String w) =>
              w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
        )
        .join(' ');
  }
}
