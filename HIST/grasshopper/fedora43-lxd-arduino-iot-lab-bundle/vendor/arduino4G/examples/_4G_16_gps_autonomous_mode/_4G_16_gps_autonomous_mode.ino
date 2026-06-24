/*
    --------------- 4G_16 - GPS Autonomous mode  ---------------

    Explanation: This example shows how to use de GPS in autonomous mode.
     - To work poperly, GPS module needs a 2A(at least) power supply.
     - GPS antennae needs direct skyview to fix satellites; work outdoor.

    Note 1: in Arduino UNO the same UART is used for user debug interface 
    and LE910 AT commands. Handle with care, user interface messages could 
    interfere with AT commands.

    Example: 
          Serial.print("operATo"); 
    It is seen as wrong AT command by the LE910 module.

    Note 2: to run this example properly you must increase the reception 
    serial buffer to 128 bytes. 
    -> go to: <arduino_dir>/hardware/arduino/avr/cores/arduino
    -> edit:  HardwareSerial.h 

     If you are using Arduino Uno:
    -> merge: #define SERIAL_RX_BUFFER_SIZE 128

     If you are using Arduino Mega:
    -> merge: #define SERIAL_TX_BUFFER_SIZE 128
    -> merge: #define SERIAL_RX_BUFFER_SIZE 128

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Version:           1.3
    Design:            David Gascon
    Implementation:    Alejandro Gallego, Yuri Carmona, Luis Miguel Marti
    Port to Arduino:   Ruben Martin
*/

#include "arduino4G.h"

// define variables
uint8_t error;
uint8_t gps_status;
bool gps_fix;

float latitude;
float longitude;

void setup()
{
  Serial.println("Start program");

  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();

  // check answer
  if (error == 0)
  {
    Serial.println(F("1. 4G module ready..."));

    ////////////////////////////////////////////////
    // 2. Start GPS feature
    ////////////////////////////////////////////////

    gps_status = _4G.gpsStart();

    // check answer
    if (gps_status == 0)
    {
      Serial.println(F("2. Starting GPS in autonomous mode... done!"));
    }
    else
    {
      Serial.print(F("2. Error calling the 'startGPS' function. Code: "));
      Serial.println(gps_status, DEC);
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("1. 4G module not started"));
    Serial.print(F("Error code: "));
    Serial.println(error, DEC);
    Serial.println(F("The code stops here."));
    while (1);
  }
}


void loop()
{
  ////////////////////////////////////////////////
  // 3. Wait for satellite signals and get values
  ////////////////////////////////////////////////
  if (gps_status == 0)
  {
    error = _4G.waitForSignal(20000);
    if (error == 0)
    {
      Serial.println(F("----------------------------"));
      Serial.print(F("Ltitude: "));
      Serial.print(_4G._latitude);
      Serial.print(F(","));
      Serial.println(_4G._latitudeNS);
      Serial.print(F("Longitude: "));
      Serial.print(_4G._longitude);
      Serial.print(F(","));
      Serial.println(_4G._longitudeEW);
      Serial.print(F("UTC_time: "));
      Serial.println(_4G._time);
      Serial.print(F("UTC_dte: "));
      Serial.println(_4G._date);
      Serial.print(F("Number of stellites: "));
      Serial.println(_4G._numSatellites, DEC);
      Serial.print(F("HDOP: "));
      Serial.println(_4G._hdop);
      Serial.println(F("----------------------------"));

      // get degrees
      latitude  = _4G.convert2Degrees(_4G._latitude, _4G._latitudeNS);
      longitude = _4G.convert2Degrees(_4G._longitude, _4G._longitudeEW);
      
      Serial.println("Conversion to degrees:");
      Serial.print(F("Ltitude: "));
      Serial.println(latitude, 6);
      Serial.print(F("Longitude: "));
      Serial.println(longitude, 6);  
      Serial.println();
      delay(10000);
    }
    else
    {
      Serial.println("no stellites fixed");
    }
  }
  else
  {
    Serial.println(F("Restarting the GPS engine"));
    _4G.gpsStop();
    delay(1000);

    gps_status = _4G.gpsStart();
  }
}
