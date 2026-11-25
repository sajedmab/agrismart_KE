import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class HarvestTask {
  final String title;
  final String badgeText;
  final IconData icon;
  final DateTime date;
  final bool isBadge;

  HarvestTask({
    required this.title,
    required this.badgeText,
    required this.icon,
    required this.date,
    required this.isBadge,
  });
}

class TachesAVenirPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const TachesAVenirPage({super.key, this.onNavigate});

  @override
  State<TachesAVenirPage> createState() => _TachesAVenirPageState();
}

class _TachesAVenirPageState extends State<TachesAVenirPage> {
  DateTime _focusedDay = DateTime(2026, 12, 2);
  DateTime? _selectedDay = DateTime(2026, 12, 2);
  int _selectedIndex = 0;

  final List<HarvestTask> _upcomingTasks = [
    HarvestTask(
      title: 'Récolte Tomates - Parcelle Nord',
      badgeText: 'Dans 5 jours',
      icon: Icons.shopping_basket_outlined,
      date: DateTime(2026, 12, 2),
      isBadge: true,
    ),
    HarvestTask(
      title: 'Taille Oliviers - Parcelle Sud',
      badgeText: '(12 Déc)',
      icon: Icons.park_outlined,
      date: DateTime(2026, 12, 12),
      isBadge: false,
    ),
  ];

  final List<DateTime> _markedDays = [
    DateTime(2026, 12, 2),
    DateTime(2026, 12, 12),
    DateTime(2026, 12, 26),
    DateTime(2026, 12, 27),
  ];

  bool _isHighlightedDay(DateTime day) {
    return _markedDays.any((d) => isSameDay(d, day));
  }

  void _showAddTaskDialog() {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final delayController = TextEditingController(text: 'Dans 3 jours');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // ✅ Fond de l'alerte dynamique
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nouvelle tâche à venir',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Titre (ex: Arrosage)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: delayController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Échéance (ex: Dans 3 jours)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF93E28C),
              foregroundColor: const Color(0xFF283D27),
            ),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _upcomingTasks.add(
                    HarvestTask(
                      title: titleController.text.trim(),
                      badgeText: delayController.text.trim(),
                      icon: Icons.eco_outlined,
                      date: _selectedDay ?? _focusedDay,
                      isBadge: true,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Récupération du thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // ✅ Fond dynamique
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: theme.colorScheme.onSurface, size: 28),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.logout, color: theme.colorScheme.onSurface, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Tâches à venir',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  // ✅ Fond de la carte calendrier
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F7F2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _capitalize(DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay)),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TableCalendar(
                      locale: 'fr_FR',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerVisible: false,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        weekendStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, theme),
                        selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, theme),
                        todayBuilder: (context, day, focusedDay) => _buildDayCell(day, theme),
                        outsideBuilder: (context, day, focusedDay) => Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tâches à venir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
                    itemCount: _upcomingTasks.length,
                    itemBuilder: (context, index) {
                      final task = _upcomingTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // ✅ Fond de la carte de tâche
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F7F2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(task.icon, size: 36, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  task.isBadge
                                      ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      // ✅ Couleur du badge dynamique
                                      color: isDark ? const Color(0xFF3A5A3A) : const Color(0xFFD6E6D2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task.badgeText,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : const Color(0xFF4C8046),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                      : Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      task.badgeText,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : const Color(0xFF4C8046),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 24,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: FloatingActionButton(
                        onPressed: _showAddTaskDialog,
                        backgroundColor: const Color(0xFF93E28C),
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add, color: Color(0xFF283D27), size: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // ✅ Fond de la navbar
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F7F2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: isDark ? const Color(0xFF3A5A3A) : const Color(0xFFD6E6D2),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (widget.onNavigate != null) {
              widget.onNavigate!(index);
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurfaceVariant),
              selectedIcon: Icon(Icons.home, color: theme.colorScheme.onSurface),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('${_upcomingTasks.length}'),
                backgroundColor: const Color(0xFF962D2D),
                child: Icon(Icons.grass_outlined, color: theme.colorScheme.onSurface),
              ),
              selectedIcon: Badge(
                label: Text('${_upcomingTasks.length}'),
                backgroundColor: const Color(0xFF962D2D),
                child: Icon(Icons.grass, color: theme.colorScheme.onSurface),
              ),
              label: 'Zones',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.onSurfaceVariant),
              selectedIcon: Icon(Icons.bar_chart, color: theme.colorScheme.onSurface),
              label: 'Statistiques',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: theme.colorScheme.onSurfaceVariant),
              selectedIcon: Icon(Icons.person, color: theme.colorScheme.onSurface),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, ThemeData theme) {
    final isMarked = _isHighlightedDay(day);
    final isSelected = isSameDay(day, _selectedDay);
    final hasCircle = isMarked && day.day != 26;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // ✅ Couleur de sélection dynamique
              color: (hasCircle || isSelected)
                  ? (isDark ? const Color(0xFF3A5A3A) : const Color(0xFFBDD8B8))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isMarked)
            Positioned(
              bottom: -2,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white54 : const Color(0xFF568B50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}