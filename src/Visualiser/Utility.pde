int sum(int[] a) {
  int s = 0;
  for (int i = 0; i < a.length; i++) s += a[i];
  return s;
}

float p2d(float p) {
  return 360 * p;
}
  
String toScore(int s) {
  switch (s) {
    case 2: return "++";
    case 1: return "+";
    case 0: return "o";
    case -1: return "-";
    default: return "--";
  }
}
