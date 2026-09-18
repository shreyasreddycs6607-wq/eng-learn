// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LessonProgressEntriesTable extends LessonProgressEntries
    with TableInfo<$LessonProgressEntriesTable, LessonProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctAnswersMeta =
      const VerificationMeta('correctAnswers');
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
      'correct_answers', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _incorrectAnswersMeta =
      const VerificationMeta('incorrectAnswers');
  @override
  late final GeneratedColumn<int> incorrectAnswers = GeneratedColumn<int>(
      'incorrect_answers', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPracticedMeta =
      const VerificationMeta('lastPracticed');
  @override
  late final GeneratedColumn<DateTime> lastPracticed =
      GeneratedColumn<DateTime>('last_practiced', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        lessonId,
        completed,
        attempts,
        correctAnswers,
        incorrectAnswers,
        lastPracticed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<LessonProgressEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
          _correctAnswersMeta,
          correctAnswers.isAcceptableOrUnknown(
              data['correct_answers']!, _correctAnswersMeta));
    }
    if (data.containsKey('incorrect_answers')) {
      context.handle(
          _incorrectAnswersMeta,
          incorrectAnswers.isAcceptableOrUnknown(
              data['incorrect_answers']!, _incorrectAnswersMeta));
    }
    if (data.containsKey('last_practiced')) {
      context.handle(
          _lastPracticedMeta,
          lastPracticed.isAcceptableOrUnknown(
              data['last_practiced']!, _lastPracticedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressEntry(
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      correctAnswers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_answers'])!,
      incorrectAnswers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}incorrect_answers'])!,
      lastPracticed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_practiced']),
    );
  }

  @override
  $LessonProgressEntriesTable createAlias(String alias) {
    return $LessonProgressEntriesTable(attachedDatabase, alias);
  }
}

class LessonProgressEntry extends DataClass
    implements Insertable<LessonProgressEntry> {
  final String lessonId;
  final bool completed;
  final int attempts;
  final int correctAnswers;
  final int incorrectAnswers;
  final DateTime? lastPracticed;
  const LessonProgressEntry(
      {required this.lessonId,
      required this.completed,
      required this.attempts,
      required this.correctAnswers,
      required this.incorrectAnswers,
      this.lastPracticed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['completed'] = Variable<bool>(completed);
    map['attempts'] = Variable<int>(attempts);
    map['correct_answers'] = Variable<int>(correctAnswers);
    map['incorrect_answers'] = Variable<int>(incorrectAnswers);
    if (!nullToAbsent || lastPracticed != null) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed);
    }
    return map;
  }

  LessonProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressEntriesCompanion(
      lessonId: Value(lessonId),
      completed: Value(completed),
      attempts: Value(attempts),
      correctAnswers: Value(correctAnswers),
      incorrectAnswers: Value(incorrectAnswers),
      lastPracticed: lastPracticed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticed),
    );
  }

  factory LessonProgressEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressEntry(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      completed: serializer.fromJson<bool>(json['completed']),
      attempts: serializer.fromJson<int>(json['attempts']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
      incorrectAnswers: serializer.fromJson<int>(json['incorrectAnswers']),
      lastPracticed: serializer.fromJson<DateTime?>(json['lastPracticed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'completed': serializer.toJson<bool>(completed),
      'attempts': serializer.toJson<int>(attempts),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
      'incorrectAnswers': serializer.toJson<int>(incorrectAnswers),
      'lastPracticed': serializer.toJson<DateTime?>(lastPracticed),
    };
  }

  LessonProgressEntry copyWith(
          {String? lessonId,
          bool? completed,
          int? attempts,
          int? correctAnswers,
          int? incorrectAnswers,
          Value<DateTime?> lastPracticed = const Value.absent()}) =>
      LessonProgressEntry(
        lessonId: lessonId ?? this.lessonId,
        completed: completed ?? this.completed,
        attempts: attempts ?? this.attempts,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
        lastPracticed:
            lastPracticed.present ? lastPracticed.value : this.lastPracticed,
      );
  LessonProgressEntry copyWithCompanion(LessonProgressEntriesCompanion data) {
    return LessonProgressEntry(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      completed: data.completed.present ? data.completed.value : this.completed,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
      incorrectAnswers: data.incorrectAnswers.present
          ? data.incorrectAnswers.value
          : this.incorrectAnswers,
      lastPracticed: data.lastPracticed.present
          ? data.lastPracticed.value
          : this.lastPracticed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressEntry(')
          ..write('lessonId: $lessonId, ')
          ..write('completed: $completed, ')
          ..write('attempts: $attempts, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('incorrectAnswers: $incorrectAnswers, ')
          ..write('lastPracticed: $lastPracticed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, completed, attempts, correctAnswers,
      incorrectAnswers, lastPracticed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressEntry &&
          other.lessonId == this.lessonId &&
          other.completed == this.completed &&
          other.attempts == this.attempts &&
          other.correctAnswers == this.correctAnswers &&
          other.incorrectAnswers == this.incorrectAnswers &&
          other.lastPracticed == this.lastPracticed);
}

class LessonProgressEntriesCompanion
    extends UpdateCompanion<LessonProgressEntry> {
  final Value<String> lessonId;
  final Value<bool> completed;
  final Value<int> attempts;
  final Value<int> correctAnswers;
  final Value<int> incorrectAnswers;
  final Value<DateTime?> lastPracticed;
  final Value<int> rowid;
  const LessonProgressEntriesCompanion({
    this.lessonId = const Value.absent(),
    this.completed = const Value.absent(),
    this.attempts = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.incorrectAnswers = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressEntriesCompanion.insert({
    required String lessonId,
    this.completed = const Value.absent(),
    this.attempts = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.incorrectAnswers = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId);
  static Insertable<LessonProgressEntry> custom({
    Expression<String>? lessonId,
    Expression<bool>? completed,
    Expression<int>? attempts,
    Expression<int>? correctAnswers,
    Expression<int>? incorrectAnswers,
    Expression<DateTime>? lastPracticed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (completed != null) 'completed': completed,
      if (attempts != null) 'attempts': attempts,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (incorrectAnswers != null) 'incorrect_answers': incorrectAnswers,
      if (lastPracticed != null) 'last_practiced': lastPracticed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressEntriesCompanion copyWith(
      {Value<String>? lessonId,
      Value<bool>? completed,
      Value<int>? attempts,
      Value<int>? correctAnswers,
      Value<int>? incorrectAnswers,
      Value<DateTime?>? lastPracticed,
      Value<int>? rowid}) {
    return LessonProgressEntriesCompanion(
      lessonId: lessonId ?? this.lessonId,
      completed: completed ?? this.completed,
      attempts: attempts ?? this.attempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    if (incorrectAnswers.present) {
      map['incorrect_answers'] = Variable<int>(incorrectAnswers.value);
    }
    if (lastPracticed.present) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressEntriesCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('completed: $completed, ')
          ..write('attempts: $attempts, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('incorrectAnswers: $incorrectAnswers, ')
          ..write('lastPracticed: $lastPracticed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileEntriesTable extends UserProfileEntries
    with TableInfo<$UserProfileEntriesTable, UserProfileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentLessonIdMeta =
      const VerificationMeta('currentLessonId');
  @override
  late final GeneratedColumn<String> currentLessonId = GeneratedColumn<String>(
      'current_lesson_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
      'streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastLearningDateMeta =
      const VerificationMeta('lastLearningDate');
  @override
  late final GeneratedColumn<DateTime> lastLearningDate =
      GeneratedColumn<DateTime>('last_learning_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, currentLessonId, streak, lastLearningDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile_entries';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfileEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_lesson_id')) {
      context.handle(
          _currentLessonIdMeta,
          currentLessonId.isAcceptableOrUnknown(
              data['current_lesson_id']!, _currentLessonIdMeta));
    }
    if (data.containsKey('streak')) {
      context.handle(_streakMeta,
          streak.isAcceptableOrUnknown(data['streak']!, _streakMeta));
    }
    if (data.containsKey('last_learning_date')) {
      context.handle(
          _lastLearningDateMeta,
          lastLearningDate.isAcceptableOrUnknown(
              data['last_learning_date']!, _lastLearningDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currentLessonId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_lesson_id']),
      streak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}streak'])!,
      lastLearningDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_learning_date']),
    );
  }

  @override
  $UserProfileEntriesTable createAlias(String alias) {
    return $UserProfileEntriesTable(attachedDatabase, alias);
  }
}

class UserProfileEntry extends DataClass
    implements Insertable<UserProfileEntry> {
  final int id;
  final String? currentLessonId;
  final int streak;
  final DateTime? lastLearningDate;
  const UserProfileEntry(
      {required this.id,
      this.currentLessonId,
      required this.streak,
      this.lastLearningDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentLessonId != null) {
      map['current_lesson_id'] = Variable<String>(currentLessonId);
    }
    map['streak'] = Variable<int>(streak);
    if (!nullToAbsent || lastLearningDate != null) {
      map['last_learning_date'] = Variable<DateTime>(lastLearningDate);
    }
    return map;
  }

  UserProfileEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserProfileEntriesCompanion(
      id: Value(id),
      currentLessonId: currentLessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentLessonId),
      streak: Value(streak),
      lastLearningDate: lastLearningDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLearningDate),
    );
  }

  factory UserProfileEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileEntry(
      id: serializer.fromJson<int>(json['id']),
      currentLessonId: serializer.fromJson<String?>(json['currentLessonId']),
      streak: serializer.fromJson<int>(json['streak']),
      lastLearningDate:
          serializer.fromJson<DateTime?>(json['lastLearningDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentLessonId': serializer.toJson<String?>(currentLessonId),
      'streak': serializer.toJson<int>(streak),
      'lastLearningDate': serializer.toJson<DateTime?>(lastLearningDate),
    };
  }

  UserProfileEntry copyWith(
          {int? id,
          Value<String?> currentLessonId = const Value.absent(),
          int? streak,
          Value<DateTime?> lastLearningDate = const Value.absent()}) =>
      UserProfileEntry(
        id: id ?? this.id,
        currentLessonId: currentLessonId.present
            ? currentLessonId.value
            : this.currentLessonId,
        streak: streak ?? this.streak,
        lastLearningDate: lastLearningDate.present
            ? lastLearningDate.value
            : this.lastLearningDate,
      );
  UserProfileEntry copyWithCompanion(UserProfileEntriesCompanion data) {
    return UserProfileEntry(
      id: data.id.present ? data.id.value : this.id,
      currentLessonId: data.currentLessonId.present
          ? data.currentLessonId.value
          : this.currentLessonId,
      streak: data.streak.present ? data.streak.value : this.streak,
      lastLearningDate: data.lastLearningDate.present
          ? data.lastLearningDate.value
          : this.lastLearningDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileEntry(')
          ..write('id: $id, ')
          ..write('currentLessonId: $currentLessonId, ')
          ..write('streak: $streak, ')
          ..write('lastLearningDate: $lastLearningDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentLessonId, streak, lastLearningDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileEntry &&
          other.id == this.id &&
          other.currentLessonId == this.currentLessonId &&
          other.streak == this.streak &&
          other.lastLearningDate == this.lastLearningDate);
}

class UserProfileEntriesCompanion extends UpdateCompanion<UserProfileEntry> {
  final Value<int> id;
  final Value<String?> currentLessonId;
  final Value<int> streak;
  final Value<DateTime?> lastLearningDate;
  const UserProfileEntriesCompanion({
    this.id = const Value.absent(),
    this.currentLessonId = const Value.absent(),
    this.streak = const Value.absent(),
    this.lastLearningDate = const Value.absent(),
  });
  UserProfileEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.currentLessonId = const Value.absent(),
    this.streak = const Value.absent(),
    this.lastLearningDate = const Value.absent(),
  });
  static Insertable<UserProfileEntry> custom({
    Expression<int>? id,
    Expression<String>? currentLessonId,
    Expression<int>? streak,
    Expression<DateTime>? lastLearningDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentLessonId != null) 'current_lesson_id': currentLessonId,
      if (streak != null) 'streak': streak,
      if (lastLearningDate != null) 'last_learning_date': lastLearningDate,
    });
  }

  UserProfileEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? currentLessonId,
      Value<int>? streak,
      Value<DateTime?>? lastLearningDate}) {
    return UserProfileEntriesCompanion(
      id: id ?? this.id,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      streak: streak ?? this.streak,
      lastLearningDate: lastLearningDate ?? this.lastLearningDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentLessonId.present) {
      map['current_lesson_id'] = Variable<String>(currentLessonId.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (lastLearningDate.present) {
      map['last_learning_date'] = Variable<DateTime>(lastLearningDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileEntriesCompanion(')
          ..write('id: $id, ')
          ..write('currentLessonId: $currentLessonId, ')
          ..write('streak: $streak, ')
          ..write('lastLearningDate: $lastLearningDate')
          ..write(')'))
        .toString();
  }
}

class $ExerciseProgressEntriesTable extends ExerciseProgressEntries
    with TableInfo<$ExerciseProgressEntriesTable, ExerciseProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _incorrectCountMeta =
      const VerificationMeta('incorrectCount');
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
      'incorrect_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reviewLevelMeta =
      const VerificationMeta('reviewLevel');
  @override
  late final GeneratedColumn<int> reviewLevel = GeneratedColumn<int>(
      'review_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAttemptedAtMeta =
      const VerificationMeta('lastAttemptedAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>('last_attempted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastCorrectAtMeta =
      const VerificationMeta('lastCorrectAt');
  @override
  late final GeneratedColumn<DateTime> lastCorrectAt =
      GeneratedColumn<DateTime>('last_correct_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextReviewAtMeta =
      const VerificationMeta('nextReviewAt');
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
      'next_review_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        exerciseId,
        lessonId,
        attemptCount,
        correctCount,
        incorrectCount,
        reviewLevel,
        lastAttemptedAt,
        lastCorrectAt,
        nextReviewAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_progress_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<ExerciseProgressEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
          _incorrectCountMeta,
          incorrectCount.isAcceptableOrUnknown(
              data['incorrect_count']!, _incorrectCountMeta));
    }
    if (data.containsKey('review_level')) {
      context.handle(
          _reviewLevelMeta,
          reviewLevel.isAcceptableOrUnknown(
              data['review_level']!, _reviewLevelMeta));
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
          _lastAttemptedAtMeta,
          lastAttemptedAt.isAcceptableOrUnknown(
              data['last_attempted_at']!, _lastAttemptedAtMeta));
    }
    if (data.containsKey('last_correct_at')) {
      context.handle(
          _lastCorrectAtMeta,
          lastCorrectAt.isAcceptableOrUnknown(
              data['last_correct_at']!, _lastCorrectAtMeta));
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
          _nextReviewAtMeta,
          nextReviewAt.isAcceptableOrUnknown(
              data['next_review_at']!, _nextReviewAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  ExerciseProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseProgressEntry(
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      incorrectCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}incorrect_count'])!,
      reviewLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_level'])!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempted_at']),
      lastCorrectAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_correct_at']),
      nextReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_review_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExerciseProgressEntriesTable createAlias(String alias) {
    return $ExerciseProgressEntriesTable(attachedDatabase, alias);
  }
}

class ExerciseProgressEntry extends DataClass
    implements Insertable<ExerciseProgressEntry> {
  final String exerciseId;
  final String lessonId;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int reviewLevel;
  final DateTime? lastAttemptedAt;
  final DateTime? lastCorrectAt;
  final DateTime? nextReviewAt;
  final DateTime createdAt;
  const ExerciseProgressEntry(
      {required this.exerciseId,
      required this.lessonId,
      required this.attemptCount,
      required this.correctCount,
      required this.incorrectCount,
      required this.reviewLevel,
      this.lastAttemptedAt,
      this.lastCorrectAt,
      this.nextReviewAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['review_level'] = Variable<int>(reviewLevel);
    if (!nullToAbsent || lastAttemptedAt != null) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    }
    if (!nullToAbsent || lastCorrectAt != null) {
      map['last_correct_at'] = Variable<DateTime>(lastCorrectAt);
    }
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseProgressEntriesCompanion(
      exerciseId: Value(exerciseId),
      lessonId: Value(lessonId),
      attemptCount: Value(attemptCount),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      reviewLevel: Value(reviewLevel),
      lastAttemptedAt: lastAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptedAt),
      lastCorrectAt: lastCorrectAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCorrectAt),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseProgressEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseProgressEntry(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      reviewLevel: serializer.fromJson<int>(json['reviewLevel']),
      lastAttemptedAt: serializer.fromJson<DateTime?>(json['lastAttemptedAt']),
      lastCorrectAt: serializer.fromJson<DateTime?>(json['lastCorrectAt']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'lessonId': serializer.toJson<String>(lessonId),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'reviewLevel': serializer.toJson<int>(reviewLevel),
      'lastAttemptedAt': serializer.toJson<DateTime?>(lastAttemptedAt),
      'lastCorrectAt': serializer.toJson<DateTime?>(lastCorrectAt),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseProgressEntry copyWith(
          {String? exerciseId,
          String? lessonId,
          int? attemptCount,
          int? correctCount,
          int? incorrectCount,
          int? reviewLevel,
          Value<DateTime?> lastAttemptedAt = const Value.absent(),
          Value<DateTime?> lastCorrectAt = const Value.absent(),
          Value<DateTime?> nextReviewAt = const Value.absent(),
          DateTime? createdAt}) =>
      ExerciseProgressEntry(
        exerciseId: exerciseId ?? this.exerciseId,
        lessonId: lessonId ?? this.lessonId,
        attemptCount: attemptCount ?? this.attemptCount,
        correctCount: correctCount ?? this.correctCount,
        incorrectCount: incorrectCount ?? this.incorrectCount,
        reviewLevel: reviewLevel ?? this.reviewLevel,
        lastAttemptedAt: lastAttemptedAt.present
            ? lastAttemptedAt.value
            : this.lastAttemptedAt,
        lastCorrectAt:
            lastCorrectAt.present ? lastCorrectAt.value : this.lastCorrectAt,
        nextReviewAt:
            nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ExerciseProgressEntry copyWithCompanion(
      ExerciseProgressEntriesCompanion data) {
    return ExerciseProgressEntry(
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      reviewLevel:
          data.reviewLevel.present ? data.reviewLevel.value : this.reviewLevel,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
      lastCorrectAt: data.lastCorrectAt.present
          ? data.lastCorrectAt.value
          : this.lastCorrectAt,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseProgressEntry(')
          ..write('exerciseId: $exerciseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('reviewLevel: $reviewLevel, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('lastCorrectAt: $lastCorrectAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      exerciseId,
      lessonId,
      attemptCount,
      correctCount,
      incorrectCount,
      reviewLevel,
      lastAttemptedAt,
      lastCorrectAt,
      nextReviewAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseProgressEntry &&
          other.exerciseId == this.exerciseId &&
          other.lessonId == this.lessonId &&
          other.attemptCount == this.attemptCount &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.reviewLevel == this.reviewLevel &&
          other.lastAttemptedAt == this.lastAttemptedAt &&
          other.lastCorrectAt == this.lastCorrectAt &&
          other.nextReviewAt == this.nextReviewAt &&
          other.createdAt == this.createdAt);
}

class ExerciseProgressEntriesCompanion
    extends UpdateCompanion<ExerciseProgressEntry> {
  final Value<String> exerciseId;
  final Value<String> lessonId;
  final Value<int> attemptCount;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> reviewLevel;
  final Value<DateTime?> lastAttemptedAt;
  final Value<DateTime?> lastCorrectAt;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExerciseProgressEntriesCompanion({
    this.exerciseId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.reviewLevel = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    this.lastCorrectAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseProgressEntriesCompanion.insert({
    required String exerciseId,
    required String lessonId,
    this.attemptCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.reviewLevel = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    this.lastCorrectAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : exerciseId = Value(exerciseId),
        lessonId = Value(lessonId),
        createdAt = Value(createdAt);
  static Insertable<ExerciseProgressEntry> custom({
    Expression<String>? exerciseId,
    Expression<String>? lessonId,
    Expression<int>? attemptCount,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? reviewLevel,
    Expression<DateTime>? lastAttemptedAt,
    Expression<DateTime>? lastCorrectAt,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (reviewLevel != null) 'review_level': reviewLevel,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
      if (lastCorrectAt != null) 'last_correct_at': lastCorrectAt,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseProgressEntriesCompanion copyWith(
      {Value<String>? exerciseId,
      Value<String>? lessonId,
      Value<int>? attemptCount,
      Value<int>? correctCount,
      Value<int>? incorrectCount,
      Value<int>? reviewLevel,
      Value<DateTime?>? lastAttemptedAt,
      Value<DateTime?>? lastCorrectAt,
      Value<DateTime?>? nextReviewAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ExerciseProgressEntriesCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      lessonId: lessonId ?? this.lessonId,
      attemptCount: attemptCount ?? this.attemptCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      reviewLevel: reviewLevel ?? this.reviewLevel,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (reviewLevel.present) {
      map['review_level'] = Variable<int>(reviewLevel.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    if (lastCorrectAt.present) {
      map['last_correct_at'] = Variable<DateTime>(lastCorrectAt.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseProgressEntriesCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('reviewLevel: $reviewLevel, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('lastCorrectAt: $lastCorrectAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LessonProgressEntriesTable lessonProgressEntries =
      $LessonProgressEntriesTable(this);
  late final $UserProfileEntriesTable userProfileEntries =
      $UserProfileEntriesTable(this);
  late final $ExerciseProgressEntriesTable exerciseProgressEntries =
      $ExerciseProgressEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [lessonProgressEntries, userProfileEntries, exerciseProgressEntries];
}

typedef $$LessonProgressEntriesTableCreateCompanionBuilder
    = LessonProgressEntriesCompanion Function({
  required String lessonId,
  Value<bool> completed,
  Value<int> attempts,
  Value<int> correctAnswers,
  Value<int> incorrectAnswers,
  Value<DateTime?> lastPracticed,
  Value<int> rowid,
});
typedef $$LessonProgressEntriesTableUpdateCompanionBuilder
    = LessonProgressEntriesCompanion Function({
  Value<String> lessonId,
  Value<bool> completed,
  Value<int> attempts,
  Value<int> correctAnswers,
  Value<int> incorrectAnswers,
  Value<DateTime?> lastPracticed,
  Value<int> rowid,
});

class $$LessonProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incorrectAnswers => $composableBuilder(
      column: $table.incorrectAnswers,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed, builder: (column) => ColumnFilters(column));
}

class $$LessonProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incorrectAnswers => $composableBuilder(
      column: $table.incorrectAnswers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed,
      builder: (column) => ColumnOrderings(column));
}

class $$LessonProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers, builder: (column) => column);

  GeneratedColumn<int> get incorrectAnswers => $composableBuilder(
      column: $table.incorrectAnswers, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed, builder: (column) => column);
}

class $$LessonProgressEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonProgressEntriesTable,
    LessonProgressEntry,
    $$LessonProgressEntriesTableFilterComposer,
    $$LessonProgressEntriesTableOrderingComposer,
    $$LessonProgressEntriesTableAnnotationComposer,
    $$LessonProgressEntriesTableCreateCompanionBuilder,
    $$LessonProgressEntriesTableUpdateCompanionBuilder,
    (
      LessonProgressEntry,
      BaseReferences<_$AppDatabase, $LessonProgressEntriesTable,
          LessonProgressEntry>
    ),
    LessonProgressEntry,
    PrefetchHooks Function()> {
  $$LessonProgressEntriesTableTableManager(
      _$AppDatabase db, $LessonProgressEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> lessonId = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int> correctAnswers = const Value.absent(),
            Value<int> incorrectAnswers = const Value.absent(),
            Value<DateTime?> lastPracticed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonProgressEntriesCompanion(
            lessonId: lessonId,
            completed: completed,
            attempts: attempts,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            lastPracticed: lastPracticed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String lessonId,
            Value<bool> completed = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int> correctAnswers = const Value.absent(),
            Value<int> incorrectAnswers = const Value.absent(),
            Value<DateTime?> lastPracticed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonProgressEntriesCompanion.insert(
            lessonId: lessonId,
            completed: completed,
            attempts: attempts,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            lastPracticed: lastPracticed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LessonProgressEntriesTable,
                        LessonProgressEntry>(table),
                    BaseReferences<_$AppDatabase, $LessonProgressEntriesTable,
                        LessonProgressEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonProgressEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LessonProgressEntriesTable,
        LessonProgressEntry,
        $$LessonProgressEntriesTableFilterComposer,
        $$LessonProgressEntriesTableOrderingComposer,
        $$LessonProgressEntriesTableAnnotationComposer,
        $$LessonProgressEntriesTableCreateCompanionBuilder,
        $$LessonProgressEntriesTableUpdateCompanionBuilder,
        (
          LessonProgressEntry,
          BaseReferences<_$AppDatabase, $LessonProgressEntriesTable,
              LessonProgressEntry>
        ),
        LessonProgressEntry,
        PrefetchHooks Function()>;
typedef $$UserProfileEntriesTableCreateCompanionBuilder
    = UserProfileEntriesCompanion Function({
  Value<int> id,
  Value<String?> currentLessonId,
  Value<int> streak,
  Value<DateTime?> lastLearningDate,
});
typedef $$UserProfileEntriesTableUpdateCompanionBuilder
    = UserProfileEntriesCompanion Function({
  Value<int> id,
  Value<String?> currentLessonId,
  Value<int> streak,
  Value<DateTime?> lastLearningDate,
});

class $$UserProfileEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentLessonId => $composableBuilder(
      column: $table.currentLessonId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streak => $composableBuilder(
      column: $table.streak, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLearningDate => $composableBuilder(
      column: $table.lastLearningDate,
      builder: (column) => ColumnFilters(column));
}

class $$UserProfileEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentLessonId => $composableBuilder(
      column: $table.currentLessonId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streak => $composableBuilder(
      column: $table.streak, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLearningDate => $composableBuilder(
      column: $table.lastLearningDate,
      builder: (column) => ColumnOrderings(column));
}

class $$UserProfileEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileEntriesTable> {
  $$UserProfileEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentLessonId => $composableBuilder(
      column: $table.currentLessonId, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLearningDate => $composableBuilder(
      column: $table.lastLearningDate, builder: (column) => column);
}

class $$UserProfileEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfileEntriesTable,
    UserProfileEntry,
    $$UserProfileEntriesTableFilterComposer,
    $$UserProfileEntriesTableOrderingComposer,
    $$UserProfileEntriesTableAnnotationComposer,
    $$UserProfileEntriesTableCreateCompanionBuilder,
    $$UserProfileEntriesTableUpdateCompanionBuilder,
    (
      UserProfileEntry,
      BaseReferences<_$AppDatabase, $UserProfileEntriesTable, UserProfileEntry>
    ),
    UserProfileEntry,
    PrefetchHooks Function()> {
  $$UserProfileEntriesTableTableManager(
      _$AppDatabase db, $UserProfileEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> currentLessonId = const Value.absent(),
            Value<int> streak = const Value.absent(),
            Value<DateTime?> lastLearningDate = const Value.absent(),
          }) =>
              UserProfileEntriesCompanion(
            id: id,
            currentLessonId: currentLessonId,
            streak: streak,
            lastLearningDate: lastLearningDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> currentLessonId = const Value.absent(),
            Value<int> streak = const Value.absent(),
            Value<DateTime?> lastLearningDate = const Value.absent(),
          }) =>
              UserProfileEntriesCompanion.insert(
            id: id,
            currentLessonId: currentLessonId,
            streak: streak,
            lastLearningDate: lastLearningDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$UserProfileEntriesTable, UserProfileEntry>(
                        table),
                    BaseReferences<_$AppDatabase, $UserProfileEntriesTable,
                        UserProfileEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfileEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfileEntriesTable,
    UserProfileEntry,
    $$UserProfileEntriesTableFilterComposer,
    $$UserProfileEntriesTableOrderingComposer,
    $$UserProfileEntriesTableAnnotationComposer,
    $$UserProfileEntriesTableCreateCompanionBuilder,
    $$UserProfileEntriesTableUpdateCompanionBuilder,
    (
      UserProfileEntry,
      BaseReferences<_$AppDatabase, $UserProfileEntriesTable, UserProfileEntry>
    ),
    UserProfileEntry,
    PrefetchHooks Function()>;
typedef $$ExerciseProgressEntriesTableCreateCompanionBuilder
    = ExerciseProgressEntriesCompanion Function({
  required String exerciseId,
  required String lessonId,
  Value<int> attemptCount,
  Value<int> correctCount,
  Value<int> incorrectCount,
  Value<int> reviewLevel,
  Value<DateTime?> lastAttemptedAt,
  Value<DateTime?> lastCorrectAt,
  Value<DateTime?> nextReviewAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ExerciseProgressEntriesTableUpdateCompanionBuilder
    = ExerciseProgressEntriesCompanion Function({
  Value<String> exerciseId,
  Value<String> lessonId,
  Value<int> attemptCount,
  Value<int> correctCount,
  Value<int> incorrectCount,
  Value<int> reviewLevel,
  Value<DateTime?> lastAttemptedAt,
  Value<DateTime?> lastCorrectAt,
  Value<DateTime?> nextReviewAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ExerciseProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseProgressEntriesTable> {
  $$ExerciseProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewLevel => $composableBuilder(
      column: $table.reviewLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCorrectAt => $composableBuilder(
      column: $table.lastCorrectAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExerciseProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseProgressEntriesTable> {
  $$ExerciseProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewLevel => $composableBuilder(
      column: $table.reviewLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCorrectAt => $composableBuilder(
      column: $table.lastCorrectAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExerciseProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseProgressEntriesTable> {
  $$ExerciseProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount, builder: (column) => column);

  GeneratedColumn<int> get reviewLevel => $composableBuilder(
      column: $table.reviewLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCorrectAt => $composableBuilder(
      column: $table.lastCorrectAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExerciseProgressEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseProgressEntriesTable,
    ExerciseProgressEntry,
    $$ExerciseProgressEntriesTableFilterComposer,
    $$ExerciseProgressEntriesTableOrderingComposer,
    $$ExerciseProgressEntriesTableAnnotationComposer,
    $$ExerciseProgressEntriesTableCreateCompanionBuilder,
    $$ExerciseProgressEntriesTableUpdateCompanionBuilder,
    (
      ExerciseProgressEntry,
      BaseReferences<_$AppDatabase, $ExerciseProgressEntriesTable,
          ExerciseProgressEntry>
    ),
    ExerciseProgressEntry,
    PrefetchHooks Function()> {
  $$ExerciseProgressEntriesTableTableManager(
      _$AppDatabase db, $ExerciseProgressEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseProgressEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseProgressEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseProgressEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> exerciseId = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> incorrectCount = const Value.absent(),
            Value<int> reviewLevel = const Value.absent(),
            Value<DateTime?> lastAttemptedAt = const Value.absent(),
            Value<DateTime?> lastCorrectAt = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseProgressEntriesCompanion(
            exerciseId: exerciseId,
            lessonId: lessonId,
            attemptCount: attemptCount,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            reviewLevel: reviewLevel,
            lastAttemptedAt: lastAttemptedAt,
            lastCorrectAt: lastCorrectAt,
            nextReviewAt: nextReviewAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String exerciseId,
            required String lessonId,
            Value<int> attemptCount = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> incorrectCount = const Value.absent(),
            Value<int> reviewLevel = const Value.absent(),
            Value<DateTime?> lastAttemptedAt = const Value.absent(),
            Value<DateTime?> lastCorrectAt = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseProgressEntriesCompanion.insert(
            exerciseId: exerciseId,
            lessonId: lessonId,
            attemptCount: attemptCount,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            reviewLevel: reviewLevel,
            lastAttemptedAt: lastAttemptedAt,
            lastCorrectAt: lastCorrectAt,
            nextReviewAt: nextReviewAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ExerciseProgressEntriesTable,
                        ExerciseProgressEntry>(table),
                    BaseReferences<_$AppDatabase, $ExerciseProgressEntriesTable,
                        ExerciseProgressEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExerciseProgressEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ExerciseProgressEntriesTable,
        ExerciseProgressEntry,
        $$ExerciseProgressEntriesTableFilterComposer,
        $$ExerciseProgressEntriesTableOrderingComposer,
        $$ExerciseProgressEntriesTableAnnotationComposer,
        $$ExerciseProgressEntriesTableCreateCompanionBuilder,
        $$ExerciseProgressEntriesTableUpdateCompanionBuilder,
        (
          ExerciseProgressEntry,
          BaseReferences<_$AppDatabase, $ExerciseProgressEntriesTable,
              ExerciseProgressEntry>
        ),
        ExerciseProgressEntry,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LessonProgressEntriesTableTableManager get lessonProgressEntries =>
      $$LessonProgressEntriesTableTableManager(_db, _db.lessonProgressEntries);
  $$UserProfileEntriesTableTableManager get userProfileEntries =>
      $$UserProfileEntriesTableTableManager(_db, _db.userProfileEntries);
  $$ExerciseProgressEntriesTableTableManager get exerciseProgressEntries =>
      $$ExerciseProgressEntriesTableTableManager(
          _db, _db.exerciseProgressEntries);
}
