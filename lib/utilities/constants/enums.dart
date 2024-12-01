enum AppRole {
  admin('Admin'),
  user('User');

  const AppRole(this.label);
  final String label;
}

enum BloodType {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  oPositive('O+'),
  oNegative('O-'),
  abPositive('AB+'),
  abNegative('AB-');

  const BloodType(this.label);
  final String label;
}

