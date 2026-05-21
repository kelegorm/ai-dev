/// Одномерный трекер скорости по последовательности move-событий.
///
/// Инкапсулирует timeStamp-bookkeeping: caller на каждом move-событии
/// передаёт его [Duration]-метку и осевую дельту, а трекер хранит
/// мгновенную скорость (px/sec) на основе двух последних событий.
///
/// Используется отдельно для горизонтальной и вертикальной осей.
class VelocityTracker1D {
  Duration? _lastStamp;
  double _velocity = 0.0;

  /// Текущая мгновенная скорость в px/sec. До первого валидного интервала
  /// (или сразу после [reset]) — `0.0`.
  double get velocity => _velocity;

  /// Регистрирует move-событие: [stamp] — его временная метка, [delta] —
  /// смещение вдоль отслеживаемой оси с предыдущего события.
  ///
  /// Скорость пересчитывается только при положительном `dt` — это защищает
  /// от dt=0 (несколько событий с одинаковым timeStamp).
  void record(Duration stamp, double delta) {
    final last = _lastStamp;
    if (last != null) {
      final dt = (stamp - last).inMicroseconds / 1e6;
      if (dt > 0) {
        _velocity = delta / dt;
      }
    }
    _lastStamp = stamp;
  }

  /// Сбрасывает накопленное состояние — вызывать на старте нового жеста.
  void reset() {
    _lastStamp = null;
    _velocity = 0.0;
  }
}
