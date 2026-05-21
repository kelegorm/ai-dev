/// Tuning-константы жестовой логики примера.
///
/// Это **не** визуальная тема (см. `canvas/canvas_theme.dart`), а внутренние
/// пороги и длительности gesture-механики: классификатор намерения, snap,
/// fling, pinch. Все «магические числа» жестов собраны здесь как единственный
/// источник правды.
library;

// --- Intent classifier --------------------------------------------------

/// Минимальное горизонтальное смещение (px), чтобы намерение жеста
/// определилось как горизонтальное.
const double kIntentMinDx = 4.0;

/// Минимальное вертикальное смещение (px), чтобы намерение жеста
/// определилось как вертикальное.
const double kIntentMinDy = 12.0;

/// Доля, которую `dx` должен превосходить относительно `dy`, чтобы жест
/// считался горизонтальным (`dx > dy * kIntentDxDyRatio`).
const double kIntentDxDyRatio = 0.6;

// --- Horizontal navigation ----------------------------------------------

/// Доля ширины экрана, которую палец должен пройти горизонтально, чтобы
/// release засчитался как навигация на соседний экран.
const double kNavDistanceFraction = 0.25;

/// Порог скорости (px/sec), после которого горизонтальный release уводит
/// навигацию на соседний экран независимо от пройденной дистанции.
const double kNavVelocityThreshold = 500.0;

/// Длительность анимации snap'а bounded-пейджера (left ↔ canvas ↔ right).
const Duration kPagerSnapDuration = Duration(milliseconds: 250);

/// Количество страниц bounded-пейджера: [Left, Canvas, Right].
const int pagerPageCount = 3;

/// Индекс последней страницы пейджера — верхняя граница clamp'а.
const int kLastPagerPage = pagerPageCount - 1;

/// Индекс центральной (канвас) страницы пейджера.
const int kCanvasPagerPage = 1;

// --- Vertical fling ------------------------------------------------------

/// Коэффициент трения для `FrictionSimulation` вертикального fling'а.
const double kFlingFriction = 0.135;

/// Минимальная скорость (px/sec), ниже которой fling не запускается.
const double kMinFlingVelocity = 80.0;

// --- Pinch ---------------------------------------------------------------

/// Нижняя граница расстояния между пальцами (px) при pinch'е — защищает
/// от деления на около-ноль при сведённых пальцах.
const double kPinchMinSpan = 20.0;
