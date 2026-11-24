import 'package:flutter/material.dart';

class HarvestTask {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  bool completed;

  HarvestTask({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.completed = false,
  });
}

class HarvestCalendarPage extends StatefulWidget {
  const HarvestCalendarPage({super.key});

  @override
  State<HarvestCalendarPage> createState() => _HarvestCalendarPageState();
}

class _HarvestCalendarPageState extends State<HarvestCalendarPage> {
  static const Color green = Color(0xFF56A832);
  static const Color darkGreen = Color(0xFF2F6B35);
  static const Color background = Color(0xFFF1F5F0);

  late DateTime _month;
  late DateTime _selectedDay;
  final List<HarvestTask> _tasks = [];

  static const List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const List<String> _weekdays = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  List<HarvestTask> get _selectedTasks =>
      _tasks.where((task) => _sameDay(task.date, _selectedDay)).toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  int get _completedCount => _tasks.where((task) => task.completed).length;

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String type = 'Récolte';
    DateTime date = _selectedDay;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter une tâche'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la tâche',
                    hintText: 'Ex. Récolte des tomates',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Récolte', child: Text('Récolte')),
                    DropdownMenuItem(value: 'Plantation', child: Text('Plantation')),
                    DropdownMenuItem(value: 'Irrigation', child: Text('Irrigation')),
                    DropdownMenuItem(value: 'Entretien', child: Text('Entretien')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dateLabel(date))),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => date = picked);
                        }
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: green),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                setState(() {
                  _tasks.add(HarvestTask(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title,
                    type: type,
                    date: DateTime(date.year, date.month, date.day),
                  ));
                  _selectedDay = DateTime(date.year, date.month, date.day);
                  _month = DateTime(date.year, date.month);
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(HarvestTask task) {
    setState(() => _tasks.removeWhere((item) => item.id == task.id));
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Récolte':
        return const Color(0xFFE88D2A);
      case 'Plantation':
        return const Color(0xFF4C9A50);
      case 'Irrigation':
        return const Color(0xFF3296C8);
      default:
        return const Color(0xFF8B75B7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmptyDays = firstWeekday - 1;
    final cellCount = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Calendrier agricole'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_months[_month.month - 1]} ${_month.year}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mois précédent',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Mois suivant',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: _weekdays
                            .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cellCount,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemBuilder: (context, index) {
                          final dayNumber = index - leadingEmptyDays + 1;

                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox.shrink();
                          }

                          final date = DateTime(
                            _month.year,
                            _month.month,
                            dayNumber,
                          );

                          final selected = _sameDay(date, _selectedDay);
                          final isToday = _sameDay(date, today);
                          final hasTasks =
                          _tasks.any((task) => _sameDay(task.date, date));

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() => _selectedDay = date);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected ? green : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isToday && !selected
                                    ? Border.all(color: green, width: 1.5)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontWeight: selected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (hasTasks)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                            : green,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel(_selectedDay),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddTaskDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_available,
                          size: 38, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucune tâche pour cette journée',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              else
                ..._selectedTasks.map((task) {
                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Checkbox(
                        activeColor: green,
                        value: task.completed,
                        onChanged: (value) {
                          setState(() => task.completed = value ?? false);
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.completed
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        task.type,
                        style: TextStyle(color: _typeColor(task.type)),
                      ),
                      trailing: IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _deleteTask(task),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              const Text(
                'Résumé des tâches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatCard(
                    title: 'Total',
                    value: '${_tasks.length}',
                    icon: Icons.list_alt,
                    color: green,
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    title: 'Terminées',
                    value: '$_completedCount',
                    icon: Icons.check_circle_outline,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    title: 'En attente',
                    value: '${_tasks.length - _completedCount}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        foregroundColor: Colors.white,
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}