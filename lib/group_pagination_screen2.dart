import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class GroupPaginationScreen extends StatefulWidget {
  const GroupPaginationScreen({super.key});

  @override
  State<GroupPaginationScreen> createState() => _GroupPaginationScreenState();
}

class _GroupPaginationScreenState extends State<GroupPaginationScreen> {
  static const _pageSize = 10;

  final Map<int, PagingController<int, String>> _controllers = {};

  // Map to store how many items each group should have
  final Map<int, int> _groupItemCounts = {};

  final List<int> _groups = List.generate(50, (i) => i + 1);

  int _nextGroupId = 51;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Assign random item counts for each group at the start
    for (var groupId in _groups) {
      _groupItemCounts[groupId] = _random.nextInt(1001); // between 0 and 1000
    }
  }

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

  Future<void> _fetchPage(
      int groupId, int pageKey, PagingController<int, String> controller) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // simulate delay

      final totalCount = _groupItemCounts[groupId] ?? 0;

      final startIndex = (pageKey - 1) * _pageSize;
      final endIndex = min(startIndex + _pageSize, totalCount);

      final newItems = List.generate(
        endIndex - startIndex,
            (index) => "Group $groupId → Item ${startIndex + index + 1}",
      );

      final isLastPage = endIndex >= totalCount;
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
    final newItem =
        "Group $groupId → NEW ITEM ${DateTime.now().millisecondsSinceEpoch}";

    final updatedList = [newItem, ...?controller.itemList];
    controller.value = PagingState(
      itemList: updatedList,
      nextPageKey: controller.nextPageKey,
      error: controller.error,
    );

    // Increase group item count since a new item is added
    _groupItemCounts[groupId] = (_groupItemCounts[groupId] ?? 0) + 1;
  }

  void _addNewGroup() {
    setState(() {
      _groups.add(_nextGroupId);
      // Assign a random item count for the new group too
      _groupItemCounts[_nextGroupId] = _random.nextInt(1001);
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
            icon: const Icon(Icons.add, color: Colors.amberAccent),
            tooltip: "Add New Group",
            onPressed: _addNewGroup,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final groupId = _groups[index];
          final totalCount = _groupItemCounts[groupId] ?? 0;
          return ExpansionTile(
            title: Text("Group $groupId  (Items: $totalCount)"),
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: () => _addNewItem(groupId),
                  child: const Text("Add New Item"),
                ),
              ),
              PagedListView<int, String>(
                pagingController: _getControllerForGroup(groupId),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                builderDelegate: PagedChildBuilderDelegate<String>(
                  itemBuilder: (context, item, index) => ListTile(
                    title: Text(item),
                  ),
                  noItemsFoundIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No items found"),
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
