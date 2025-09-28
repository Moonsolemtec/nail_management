import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nail_management/pages/event_page.dart';
import 'package:nail_management/pages/service_page.dart';
import 'package:nail_management/pages/settings_page.dart';
import 'package:nail_management/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LandingPage({super.key, required this.onToggleTheme});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _selectedIndex = 1;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ServicePage(),
      CalendarPage(
        focusedDay: _focusedDay,
        selectedDay: _selectedDay,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nail Management"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.deselected,
        iconSize: 30,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: ""),
        ],
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  const CalendarPage({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String? selectedAgentId;
  List<Map<String, dynamic>> agents = [];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    final snapshot = await FirebaseFirestore.instance.collection("agents").get();
    setState(() {
      agents = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "name": data["name"] ?? "",
          "imagePath": data["imagePath"] ?? "",
        };
      }).toList();
    });
  }

  void _selectAgent(String id) {
    setState(() {
      selectedAgentId = selectedAgentId == id ? null : id;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedAgentId == null) return; // não permite seleção se nenhum agente
    widget.onDaySelected(selectedDay, focusedDay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return EventPage(
          selectedDate: selectedDay,
          agentId: selectedAgentId!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista horizontal de agentes
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              final isSelected = agent["id"] == selectedAgentId;

              ImageProvider? avatarImage;
              if (agent["imagePath"].isNotEmpty) {
                final file = File(agent["imagePath"]);
                if (file.existsSync()) {
                  avatarImage = FileImage(file);
                }
              }

              return GestureDetector(
                onTap: () => _selectAgent(agent["id"]),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                          : BorderSide.none,
                    ),
                    elevation: isSelected ? 4 : 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: avatarImage,
                          child: avatarImage == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          agent["name"],
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Calendário
        Padding(
          padding: const EdgeInsets.all(8),
          child: AbsorbPointer(
            absorbing: selectedAgentId == null, // desabilita o calendário se nenhum agente
            child: Opacity(
              opacity: selectedAgentId == null ? 0.5 : 1.0, // efeito visual de desabilitado
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  focusedDay: widget.focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
                  onDaySelected: _onDaySelected,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class ProfessionalsList extends StatelessWidget {
  final List<Map<String, String>> agents;

  const ProfessionalsList({super.key, required this.agents});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: agents.map((agent) {
            return ProfessionalCard(
              name: agent["name"]!,
              imagePath: agent["imagePath"],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProfessionalCard extends StatelessWidget {
  final String name;
  final String? imagePath;

  const ProfessionalCard({
    super.key,
    required this.name,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;

    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        avatarImage = FileImage(file);
      }
    }

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: avatarImage,
              child: avatarImage == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

