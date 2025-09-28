import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nail_management/theme/app_theme.dart';

class EventPage extends StatelessWidget {
  final DateTime selectedDate;
  final String agentId;

  const EventPage({
    super.key,
    required this.selectedDate,
    required this.agentId,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("dd 'de' MMMM", "pt_BR").format(selectedDate);

    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("events")
                      .where("agentId", isEqualTo: agentId)
                      .where("date", isGreaterThanOrEqualTo: startOfDay)
                      .where("date", isLessThan: endOfDay)
                      .orderBy("date")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Nenhum evento para este dia."));
                    }

                    final events = snapshot.data!.docs;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index].data() as Map<String, dynamic>;
                        final eventTime = (event["date"] as Timestamp).toDate();
                        final eventTitle = event["title"] ?? "Sem título";

                        return ListTile(
                          title: Text(eventTitle),
                          trailing: Text("${eventTime.hour.toString().padLeft(2,'0')}:${eventTime.minute.toString().padLeft(2,'0')}"),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    // Aqui você pode abrir um modal para adicionar evento
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
