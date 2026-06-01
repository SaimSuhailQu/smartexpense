import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ExpenseCardPlaceholder extends StatelessWidget {
  const ExpenseCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const ListTile(
          title: SizedBox(height: 14, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
          subtitle: SizedBox(height: 10, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
          trailing: CircleAvatar(backgroundColor: Colors.white, radius: 14),
        ),
      ),
    );
  }
}
