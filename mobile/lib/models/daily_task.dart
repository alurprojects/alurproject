// Model minimal untuk tampilan Daily To-do (sesuai gambar).
// Dipisah dari [Task] global agar Daily View tetap ringan & modular.

enum DailyTaskKind { event, scheduled, todo, subTodo, ritual }

enum DailyTaskIcon { star, clock, grid, people, moon }

class DailyTask {
  final String id;
  final String title;
  final DailyTaskKind kind;
  final DailyTaskIcon? icon;
  final String? time; // e.g. "09:00"
  final bool completed;

  const DailyTask({
    required this.id,
    required this.title,
    required this.kind,
    this.icon,
    this.time,
    this.completed = false,
  });

  DailyTask copyWith({bool? completed}) => DailyTask(
        id: id,
        title: title,
        kind: kind,
        icon: icon,
        time: time,
        completed: completed ?? this.completed,
      );
}

class DailyDay {
  final int date;
  final String label; // MON, TUE...
  final bool isActive;

  const DailyDay({required this.date, required this.label, this.isActive = false});

  DailyDay copyWith({bool? isActive}) =>
      DailyDay(date: date, label: label, isActive: isActive ?? this.isActive);
}
