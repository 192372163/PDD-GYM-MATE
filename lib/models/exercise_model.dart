class ExerciseModel {
  final String id;
  final String name;
  final String description;
  final String targetMuscle;
  final int sets;
  final int reps;
  final int restTimeSec;
  final int caloriesBurned;
  final String difficulty;
  final String equipmentNeeded;
  final String? imageUrl;
  final String? videoUrl;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    this.restTimeSec = 60,
    this.caloriesBurned = 0,
    this.difficulty = 'Beginner',
    this.equipmentNeeded = 'None',
    this.imageUrl,
    this.videoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetMuscle': targetMuscle,
      'sets': sets,
      'reps': reps,
      'restTimeSec': restTimeSec,
      'caloriesBurned': caloriesBurned,
      'difficulty': difficulty,
      'equipmentNeeded': equipmentNeeded,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      targetMuscle: map['targetMuscle'] ?? '',
      sets: map['sets']?.toInt() ?? 0,
      reps: map['reps']?.toInt() ?? 0,
      restTimeSec: map['restTimeSec']?.toInt() ?? 60,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      difficulty: map['difficulty'] ?? 'Beginner',
      equipmentNeeded: map['equipmentNeeded'] ?? 'None',
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
    );
  }
}

class WorkoutPlanModel {
  final String id;
  final String title;
  final DateTime date;
  final List<ExerciseModel> exercises;

  WorkoutPlanModel({
    required this.id,
    required this.title,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'exercises': exercises.map((x) => x.toMap()).toList(),
    };
  }

  factory WorkoutPlanModel.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      exercises: List<ExerciseModel>.from(
        (map['exercises'] ?? []).map((x) => ExerciseModel.fromMap(x)),
      ),
    );
  }
}
