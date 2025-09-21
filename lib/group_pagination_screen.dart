import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class GroupPaginationScreen extends StatefulWidget {
  const GroupPaginationScreen({super.key});

  @override
  State<GroupPaginationScreen> createState() => _GroupPaginationScreenState();
}

class _GroupPaginationScreenState extends State<GroupPaginationScreen> {
  static const _pageSize = 50;

  // Each group will have its own paging controller
  final Map<int, PagingController<int, String>> _controllers = {};

  // List of group IDs
  final List<int> _groups = List.generate(25, (i) => i + 1);

  int _nextGroupId = 26;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PagingController<int, String> _getControllerForGroup(int groupId) {
    if (!_controllers.containsKey(groupId)) {
      final controller = PagingController<int, String>(firstPageKey: 1);
      controller.addPageRequestListener(
            (pageKey) => _fetchPage(groupId, pageKey, controller),
      );
      _controllers[groupId] = controller;
    }
    return _controllers[groupId]!;
  }

  Future<void> _fetchPage(int groupId, int pageKey, PagingController<int, String> controller) async
  {
    try {
      await Future.delayed(const Duration(seconds: 1)); // simulate delay

      final newItems = List.generate(
        _pageSize,
            (index) => "Group $groupId → Item ${(pageKey - 1) * _pageSize + index + 1}",
      );

      final isLastPage = pageKey >= 3; // simulate 3 pages
      if (isLastPage) {
        controller.appendLastPage(newItems);
      } else {
        controller.appendPage(newItems, pageKey + 1);
      }
    } catch (error) {
      controller.error = error;
    }
  }

  void _addNewItem(int groupId) {
    final controller = _getControllerForGroup(groupId);
    final newItem = "Group $groupId → NEW ITEM ${DateTime.now().millisecondsSinceEpoch}";

    final updatedList = [newItem, ...?controller.itemList]; // prepend
    controller.value = PagingState(
      itemList: updatedList,
      nextPageKey: controller.nextPageKey,
      error: controller.error,
    );
  }

  // Function to add a new group dynamically
  void _addNewGroup() {
    setState(() {
      _groups.add(_nextGroupId);
      _nextGroupId++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(_groups.length),
      appBar: AppBar(
        title: const Text("Group + Pagination Example"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add,color: Colors.amberAccent,),
            tooltip: "Add New Group",
            onPressed: _addNewGroup,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final groupId = _groups[index];
          return ExpansionTile(
            title: Text("Group $groupId"),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () => _addNewItem(groupId),
                  child: const Text("Add New Item"),
                ),
              ),
              SizedBox(
                height: 250,
                child: PagedListView<int, String>(
                  pagingController: _getControllerForGroup(groupId),
                  builderDelegate: PagedChildBuilderDelegate<String>(
                    itemBuilder: (context, item, index) => ListTile(
                      title: Text(item),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
