#include <Wire.h>

/*
  Scaffold for BMM150 magnetometer + AMG8833 IR camera over I2C.
  Install matching sensor libraries for production reads:
  - DFRobot_BMM150 / Bosch BMM150 compatible library
  - Adafruit_AMG88xx
*/

#define BMM150_ADDR 0x10
#define AMG8833_ADDR 0x69

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Serial.println("{\"boot\":\"arduino-q-bmm150-amg8833\",\"status\":\"ready\"}");
}

uint8_t probe(uint8_t addr){
  Wire.beginTransmission(addr);
  return Wire.endTransmission()==0;
}

void loop() {
  Serial.print("{\"device\":\"arduino_q\",\"ms\":");
  Serial.print(millis());
  Serial.print(",\"i2c\":{\"bmm150\":");
  Serial.print(probe(BMM150_ADDR) ? "true" : "false");
  Serial.print(",\"amg8833\":");
  Serial.print(probe(AMG8833_ADDR) ? "true" : "false");
  Serial.print("},\"bmm150\":{\"x_uT\":null,\"y_uT\":null,\"z_uT\":null},\"amg8833\":{\"pixels\":[]}");
  Serial.println("}");
  delay(1000);
}
