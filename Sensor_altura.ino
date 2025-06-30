const int trigPin = 8;
const int echoPin = 9;
long duration;
float distance_cm;

void setup() {
  Serial.begin(9600);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
}

float medirDistancia() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  return (duration * 0.0343) / 2.0;
}

void loop() {
  float mediciones[5];
  float suma = 0;

  for (int i = 0; i < 5; i++) {
    mediciones[i] = medirDistancia();
    suma += mediciones[i];
    delay(50);
  }

  for (int i = 0; i < 5; i++) {
    Serial.print(mediciones[i], 2);
    if (i < 4)
      Serial.print(",");
    else
      Serial.println();
  }

  float promedio = suma / 5.0;

  if (promedio <= 3.0) {
    while (true);
  }

  delay(1000);
}
