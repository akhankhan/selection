import 'package:flutter/material.dart';

class AddItemInput extends StatefulWidget {
  const AddItemInput({
    super.key,
    required this.lists,
    required this.onSubmit,
  });

  final List<String> lists;
  final void Function(String item, String list) onSubmit;

  @override
  State<AddItemInput> createState() => _AddItemInputState();
}

class _AddItemInputState extends State<AddItemInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late String _selectedList = widget.lists.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0071CE), width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    widget.onSubmit(value.trim(), _selectedList);
                    Navigator.of(context).pop();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Add Item',
                    hintStyle: TextStyle(color: Color(0xFF0071CE)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedList,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  items: widget.lists
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedList = v);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddItemInput(
  BuildContext context, {
  required List<String> lists,
  required void Function(String item, String list) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddItemInput(lists: lists, onSubmit: onSubmit),
  );
}
