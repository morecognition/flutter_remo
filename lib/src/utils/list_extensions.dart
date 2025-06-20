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
}
