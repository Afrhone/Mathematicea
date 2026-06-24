/*
  Wi-Fi sensor probe scaffold for a configurable Arduino Run Rev2/Wi-Fi board.
  Replace WiFi include/credentials according to actual board package.
*/
void setup() {
  Serial.begin(115200);
  Serial.println("{\"boot\":\"run-rev2-wifi-probe\",\"status\":\"ready\"}");
}
void loop() {
  Serial.print("{\"device\":\"run_rev2\",\"ms\":");
  Serial.print(millis());
  Serial.println(",\"wifi\":{\"ip\":null,\"rssi\":null}}");
  delay(1000);
}
