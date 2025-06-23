import 'dart:math';

extension ListExtensions on List<double> {
  void setMin(List<double> otherList) {
    var minLenght = min(length, otherList.length);

    for (var i = 0; i < minLenght; i++) {
      this[i] = min(this[i], otherList[i]);
    }
  }

  void setAverage(List<double> otherList) {
    var minLenght = min(length, otherList.length);

    for (var i = 0; i < minLenght; i++) {
      this[i] = (this[i] + otherList[i]) / 2;
    }
  }

  List<double> divide(List<double> otherList) {
    var minLenght = min(length, otherList.length);

    var res = List.generate(minLenght, (i) => this[i] / otherList[i]);

    var restList = length > otherList.length ? this : otherList;

    res.addAll(restList.skip(minLenght));

    return res;
  }

  double average() {
    return reduce((a, b) => (a + b) / 2);
  }

  double sum() {
    return reduce((a, b) => a + b);
  }

  double percentile(double percentile) {
    if (isEmpty) {
      throw ArgumentError("Data list cannot be empty");
    }

    // Sort the data
    final sorted = List<double>.from(this)..sort();

    // Compute the rank (percentile should be between 0 and 100)
    final rank = (percentile / 100) * (sorted.length - 1);
    final lowerIndex = rank.floor();
    final upperIndex = rank.ceil();

    if (lowerIndex == upperIndex) {
      return sorted[lowerIndex];
    }

    // Interpolate
    final lowerValue = sorted[lowerIndex];
    final upperValue = sorted[upperIndex];
    return lowerValue + (upperValue - lowerValue) * (rank - lowerIndex);
  }
}
