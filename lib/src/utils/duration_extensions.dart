extension DurationExtensions on Duration {
  double inDecimalSeconds() {
    return inMilliseconds / 1000.0;
  }
}
