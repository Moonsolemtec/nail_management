import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nail_management/theme/app_theme.dart';

class EventPage extends StatelessWidget {
  final DateTime selectedDate;

  const EventPage({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("dd 'de' MMMM", "pt_BR").format(selectedDate);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.deselected,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                formattedDate,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    ListTile(
                      title: Text("Vanessa C"),
                      trailing: Text("09:30"),
                    ),
                    ListTile(
                      title: Text("Andreia F"),
                      trailing: Text("13:30"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                  },
                  child: const Icon(Icons.add),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
