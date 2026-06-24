/*  
    --------------------- 4G 02 - Getting module info --------------------
    
    Explanation: This example shows how to get IMSI from SIM card and IMEI 
    from 4G module

    Note 1: in Arduino UNO the same UART is used for user debug interface 
    and LE910 AT commands. Handle with care, user interface messages could 
    interfere with AT commands.

    Example: 
          Serial.print("operATo"); 
    It is seen as wrong AT command by the LE910 module.

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

// variables
int temperature;
uint8_t error;


void setup()
{
  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();

  Serial.println("Start program");

  // check answer
  if (error == 0)
  {    
    Serial.println(F("4G module ready\n"));
    
    ////////////////////////////////////////////////
    // 1.1. Hardware revision 
    ////////////////////////////////////////////////   
    error = _4G.getInfo(arduino4G::INFO_HW);
    if (error == 0)
    {
      Serial.print(F("1.1. Hardware revision: "));
      Serial.println((char *)_4G._buffer);
    }

    ////////////////////////////////////////////////
    // 1.2. Manufacturer identification
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_MANUFACTURER_ID);
    if (error == 0)
    {
      Serial.print(F("1.2. Manufacturer identification: "));
      Serial.println((char *)_4G._buffer);
    }
 
    ////////////////////////////////////////////////
    // 1.3. Model identification
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_MODEL_ID);
    if (error == 0)
    {
      Serial.print(F("1.3. Model identification: "));
      Serial.println((char *)_4G._buffer);
    }

    ////////////////////////////////////////////////
    // 1.4. Revision identification
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_REV_ID);
    if (error == 0)
    {
      Serial.print(F("1.4. Revision identification: "));
      Serial.println((char *)_4G._buffer);
    }

    ////////////////////////////////////////////////
    // 1.5. Revision identification
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_IMEI);
    if (error == 0)
    {
      Serial.print(F("1.5. IMEI: "));
      Serial.println((char *)_4G._buffer);
    }

    ////////////////////////////////////////////////
    // 1.6. IMSI
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_IMSI);
    if (error == 0)
    {
      Serial.print(F("1.6. IMSI: "));
      Serial.println((char *)_4G._buffer);
    }

    ////////////////////////////////////////////////
    // 1.7. ICCID
    ////////////////////////////////////////////////
    error = _4G.getInfo(arduino4G::INFO_ICCID);
    if (error == 0)
    {
      Serial.print(F("1.7. ICCID: "));
      Serial.println((char *)_4G._buffer);
    }
    
    ////////////////////////////////////////////////
    // 1.8. Show APN settings
    ////////////////////////////////////////////////
    Serial.println(F("1.8. Show APN:"));
    _4G.show_APN();
    
    ////////////////////////////////////////////////
    // 1.9. Get temperature
    ////////////////////////////////////////////////
    error = _4G.getTemp();
    if (error == 0)
    {
      Serial.print(F("1.9a. Temp interval: "));
      Serial.println(_4G._tempInterval, DEC);
      Serial.print(F("1.9b. Temp: "));
      Serial.print(_4G._temp, DEC);
      Serial.println(F(" Celsius degrees"));
    }
    else
    {
      
      Serial.println(F("Error calling 'getTemp' function"));
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("4G module not started"));
  }
}


void loop()
{
  // do nothing
}
