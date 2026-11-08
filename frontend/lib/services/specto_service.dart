import '../core/api/api_client.dart';

/// Единый сервис для всех API-вызовов Specto (предметы, оценки, статистика,
/// профиль, наблюдатели).
class SpectoService {
  SpectoService._();
  static final SpectoService instance = SpectoService._();

  // ── Helpers ──────────────────────────────────

  Map<String, dynamic> _sq({int? studentId}) {
    if (studentId != null) return {'student_id': studentId.toString()};
    return {};
  }

  // ── Subjects ─────────────────────────────────

  Future<List<dynamic>> getSubjects({int? studentId}) async {
    final r = await dio.get('/subjects/', queryParameters: _sq(studentId: studentId));
    return r.data as List;
  }

  Future<List<dynamic>> createSubjects(List<String> names) async {
    final r = await dio.post('/subjects/create/', data: {'names': names});
    return r.data as List;
  }

  Future<void> deleteSubject(int id) async {
    await dio.delete('/subjects/$id/');
  }

  // ── Grades ───────────────────────────────────

  Future<Map<String, dynamic>> addGrade(int subjectId, int score) async {
    final r = await dio.post('/grades/create/', data: {
      'subject_id': subjectId,
      'score': score,
    });
    return r.data as Map<String, dynamic>;
  }

  // ── Stats ────────────────────────────────────

  /// Статистика за сегодня (включает week_bank из бэкенда).
  Future<Map<String, dynamic>> getTodayStats({int? studentId}) async {
    final r = await dio.get('/stats/today/', queryParameters: _sq(studentId: studentId));
    return r.data as Map<String, dynamic>;
  }

  /// Статистика за неделю. offset=0 текущая, -1 прошлая и т.д.
  Future<Map<String, dynamic>> getWeekStats({int offset = 0, int? studentId}) async {
    final q = _sq(studentId: studentId);
    q['offset'] = offset.toString();
    final r = await dio.get('/stats/week/', queryParameters: q);
    return r.data as Map<String, dynamic>;
  }

  /// Общая статистика за всё время.
  Future<Map<String, dynamic>> getHistoryOverview({int? studentId}) async {
    final r = await dio.get('/stats/history/', queryParameters: _sq(studentId: studentId));
    return r.data as Map<String, dynamic>;
  }

  /// Статистика за конкретный день.
  Future<Map<String, dynamic>> getDayStats(String isoDate, {int? studentId}) async {
    final q = _sq(studentId: studentId);
    q['date'] = isoDate;
    final r = await dio.get('/stats/day/', queryParameters: q);
    return r.data as Map<String, dynamic>;
  }

  /// Статистика по конкретному предмету.
  Future<Map<String, dynamic>> getSubjectStats(int subjectId, {int? studentId}) async {
    final r = await dio.get(
      '/stats/subject/$subjectId/',
      queryParameters: _sq(studentId: studentId),
    );
    return r.data as Map<String, dynamic>;
  }

  // ── Profile ──────────────────────────────────

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? schoolGrade,
    String? username,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (schoolGrade != null) data['school_grade'] = schoolGrade;
    if (username != null) data['username'] = username;
    final r = await dio.patch('/profile/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    String newPasswordConfirm,
  ) async {
    await dio.post('/profile/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    });
  }

  // ── Student → Observers ──────────────────────

  Future<Map<String, dynamic>> getStudentObservers() async {
    final r = await dio.get('/student/observers/');
    return r.data as Map<String, dynamic>;
  }

  Future<void> respondObserverRequest(int linkId, String action) async {
    await dio.post('/student/observers/$linkId/respond/', data: {'action': action});
  }

  Future<void> removeObserver(int linkId) async {
    await dio.delete('/student/observers/$linkId/');
  }

  // ── Observer → Students ──────────────────────

  Future<Map<String, dynamic>> getObserverStudents() async {
    final r = await dio.get('/observer/students/');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> searchStudents(String query) async {
    final r = await dio.get('/observer/students/search/', queryParameters: {'q': query});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendObserverRequest(int studentId) async {
    final r = await dio.post('/observer/request/$studentId/');
    return r.data as Map<String, dynamic>;
  }
}

