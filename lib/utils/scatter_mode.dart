enum ScatterMode {
  last10,
  window30Cap,
  adaptive,
}

class ScatterConfig {
  // Default cap for window30Cap mode
  static const int capN = 40;
  // Default target for adaptive downsampling
  static const int downsampleTarget = 60;
  // Default window in days for windowed modes
  static const int windowDays = 30;
}
