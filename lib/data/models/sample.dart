/// One raw accelerometer reading (m/s², device axes, gravity included).
class Sample {
  const Sample(this.tMs, this.x, this.y, this.z);

  final int tMs;
  final double x;
  final double y;
  final double z;
}
