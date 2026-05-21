/// Tuning-константы навигационной механики примера shared-scaffold.
///
/// Внутренние пороги и длительности: классификатор намерения, snap subState
/// и outer PageView. Pinch/zoom в этом примере нет — соответствующих
/// констант тоже.
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

// --- Snap ----------------------------------------------------------------

/// Доля пройденного пути, после которой snap subState (tab1 ↔ tab2) уезжает
/// к следующей позиции.
const double kSnapDistanceFraction = 0.18;

/// Порог скорости (px/sec), после которого snap уезжает к следующей
/// позиции независимо от пройденной дистанции.
const double kSnapVelocityThreshold = 500.0;

/// Длительность анимации snap'а subState (tab1 ↔ tab2).
const Duration kSubStateSnapDuration = Duration(milliseconds: 250);

/// Длительность анимации snap'а outer PageView (tab3/4).
const Duration kOuterSnapDuration = Duration(milliseconds: 250);

// --- Outer pages ---------------------------------------------------------

/// Количество outer-страниц: [SuperPage, Tab3, Tab4].
const int outerPageCount = 3;

/// Индекс последней outer-страницы — верхняя граница clamp'а.
const int kLastOuterPage = outerPageCount - 1;

/// Порог subState, при достижении которого BottomNav подсвечивает tab2.
const double kSubStateNavThreshold = 0.5;
