import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

class AddItemInput extends StatefulWidget {
  const AddItemInput({
    super.key,
    required this.lists,
    required this.onSubmit,
    this.initialList,
    this.embedded = false,
  });

  final List<String> lists;
  final String? initialList;
  final void Function(String item, String list) onSubmit;
  final bool embedded;

  @override
  State<AddItemInput> createState() => AddItemInputState();
}

class AddItemInputState extends State<AddItemInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late String _selectedList;

  @override
  void initState() {
    super.initState();
    _selectedList = _resolveSelectedList(widget.initialList);
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(AddItemInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lists != widget.lists ||
        oldWidget.initialList != widget.initialList) {
      _selectedList = _resolveSelectedList(widget.initialList ?? _selectedList);
    }
  }

  String _resolveSelectedList(String? preferred) {
    if (widget.lists.isEmpty) return 'My List';
    if (preferred != null && widget.lists.contains(preferred)) {
      return preferred;
    }
    return widget.lists.first;
  }

  void focusWithList(String? listTitle) {
    if (listTitle != null && widget.lists.contains(listTitle)) {
      setState(() => _selectedList = listTitle);
    }
    _focusNode.requestFocus();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    widget.onSubmit(value, _selectedList);
    _controller.clear();

    if (widget.embedded) {
      _focusNode.requestFocus();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final lists = widget.lists.isEmpty ? const ['My List'] : widget.lists;

    return Material(
      color: theme.cardSurface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: widget.embedded ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: widget.embedded ? 8 : 10,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                (widget.embedded ? 4 : 8),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.brandBlue, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Add Item',
                      hintStyle: TextStyle(color: context.brandBlue),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: theme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lists.contains(_selectedList)
                        ? _selectedList
                        : lists.first,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.subtitle,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    items: lists
                        .map(
                          (l) => DropdownMenuItem(value: l, child: Text(l)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedList = v);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.add_circle,
                    color: context.brandBlue,
                    size: 32,
                  ),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAddItemInput(
  BuildContext context, {
  required List<String> lists,
  String? initialList,
  required void Function(String item, String list) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddItemInput(
      lists: lists,
      initialList: initialList,
      onSubmit: onSubmit,
    ),
  );
}
