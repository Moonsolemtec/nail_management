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

  final List<Map<String, String>> _professionals = const [
    {"name": "Paola", "image": "./images/sem_imagem.jpg"},
    {"name": "Heloísa", "image": "./images/sem_imagem.jpg"},
  ];

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
        professionals: _professionals,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return EventPage(selectedDate: selected);
          },
        );
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

class CalendarPage extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Map<String, String>> professionals;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  const CalendarPage({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.professionals,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: ProfessionalsList(professionals: professionals),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,
              calendarStyle: _calendarStyle(context),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  CalendarStyle _calendarStyle(BuildContext context) => CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primary,
            width: 2,
          ),
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontWeight: FontWeight.bold,
        ),
      );
}

class ProfessionalsList extends StatelessWidget {
  final List<Map<String, String>> professionals;

  const ProfessionalsList({super.key, required this.professionals});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: professionals
              .map((professional) => ProfessionalCard(
                    name: professional["name"]!,
                    imagePath: professional["image"]!,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class ProfessionalCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const ProfessionalCard({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundImage: NetworkImage(imagePath), radius: 25),
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
