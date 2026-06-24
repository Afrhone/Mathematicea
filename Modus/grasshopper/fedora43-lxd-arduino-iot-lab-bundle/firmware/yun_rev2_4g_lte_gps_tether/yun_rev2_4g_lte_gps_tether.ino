/*
  Arduino Yun Rev2 + Cooking Hacks / Libelium 4G LTE GPS shield scaffold.

  Vendor APIs differ by shield revision. Copy the arduino4G library into Arduino/libraries
  or use the vendor library included under vendor/arduino4G if present.

  This sketch emits JSON health frames and leaves AT/4G commands explicit.
*/
#include <Bridge.h>

void setup() {
  Serial.begin(115200);
  Bridge.begin();
  Serial.println("{\"boot\":\"yun-rev2-4g-lte-gps\",\"status\":\"ready\"}");
}

void loop() {
  Serial.print("{\"device\":\"yun_rev2_4g\",\"ms\":");
  Serial.print(millis());
  Serial.print(",\"gps\":{\"lat\":null,\"lon\":null,\"fix\":false}");
  Serial.print(",\"lte\":{\"rssi\":null,\"attached\":null}");
  Serial.println("}");
  delay(2000);
}
