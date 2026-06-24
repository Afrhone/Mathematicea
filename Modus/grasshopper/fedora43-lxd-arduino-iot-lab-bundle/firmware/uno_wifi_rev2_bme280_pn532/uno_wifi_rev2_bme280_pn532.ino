#include <Wire.h>
#include <Adafruit_BME280.h>

// PN532 support is optional: install Adafruit PN532 library if using the shield.
// #include <Adafruit_PN532.h>
// #define PN532_IRQ   2
// #define PN532_RESET 3
// Adafruit_PN532 nfc(PN532_IRQ, PN532_RESET);

Adafruit_BME280 bme;
bool bmeOK=false;

void setup() {
  Serial.begin(115200);
  while(!Serial && millis() < 5000) {}
  Wire.begin();
  bmeOK = bme.begin(0x76);
  if(!bmeOK) bmeOK = bme.begin(0x77);
  Serial.println("{\"boot\":\"uno-wifi-rev2-bme280-pn532\",\"status\":\"ready\"}");
}

void loop() {
  Serial.print("{\"device\":\"uno_wifi_rev2\",\"ms\":");
  Serial.print(millis());
  Serial.print(",\"bme280\":");
  if(bmeOK){
    Serial.print("{\"temperature_c\":"); Serial.print(bme.readTemperature(),2);
    Serial.print(",\"pressure_hpa\":"); Serial.print(bme.readPressure()/100.0F,2);
    Serial.print(",\"humidity_pct\":"); Serial.print(bme.readHumidity(),2);
    Serial.print("}");
  } else {
    Serial.print("null");
  }
  Serial.print(",\"pins\":{");
  for(int p=2;p<=13;p++){
    Serial.print("\""); Serial.print(p); Serial.print("\":"); Serial.print(digitalRead(p));
    if(p<13) Serial.print(",");
  }
  Serial.println("}}");
  delay(1000);
}
