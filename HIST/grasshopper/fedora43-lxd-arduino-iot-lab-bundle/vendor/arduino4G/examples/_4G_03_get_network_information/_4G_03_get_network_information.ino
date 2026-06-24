/*  
    -----------------  4G_03 - Getting network information ---------------- 

    Important: in Arduino UNO the same UART is used for Debug User Interface 
    and LE910 AT commands. Handle with care, user interface messages could 
    interfere with AT commands.

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
uint8_t connection_status;
char operator_name[16];
uint8_t error;

void setup()
{    
}

void loop()
{
  //////////////////////////////////////////////////
  // 1. Switch ON the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();
  
  if (error == 0)
  {
    Serial.println(F("1. 4G module ready")); 

    ////////////////////////////////////////////////
    // 1.1. Check connection to network and continue
    ////////////////////////////////////////////////
    connection_status = _4G.checkDataConnection(30);
    if (connection_status == 0)
    {
      Serial.println(F("1.1. Module connected to network"));

      //////////////////////////////////////////////
      // 1.2. Get RSSI
      //////////////////////////////////////////////
      error = _4G.getRSSI();
      if (error == 0)
      {
        Serial.print(F("1.2. RSSI: "));
        Serial.print(_4G._rssi, DEC);
        Serial.println(F(" dBm"));
      }
      else
      {
        Serial.println(F("1.2. Error calling 'getRSSI' function"));
      }

      //////////////////////////////////////////////
      // 1.3. Get Network Type
      //////////////////////////////////////////////
      error = _4G.getNetworkType();

      if (error == 0)
      {
        Serial.print(F("1.3. Network type: "));
        switch (_4G._networkType)
        {
        case 0:
          Serial.println(F("GPRS"));
          break;
        case 1:
          Serial.println(F("EGPRS"));
          break;
        case 2:
          Serial.println(F("WCDMA"));
          break;
        case 3:
          Serial.println(F("HSDPA"));
          break;
        case 4:
          Serial.println(F("LTE"));
          break;
        case 5:
          Serial.println(F("Unknown or not registered"));
          break;				
        }
      }
      else
      {
        Serial.println(F("1.3. Error calling 'getNetworkType' function"));
      }

      //////////////////////////////////////////////
      // 1.4. Get Operator name
      //////////////////////////////////////////////
      memset(operator_name, '\0', sizeof(operator_name));
      error = _4G.getOperator(operator_name);

      if (error == 0)
      {
        Serial.print(F("1.4. Opertor: "));
        Serial.println(operator_name);
      }
      else
      {
        Serial.println(F("1.4. Error calling 'getOpertor' function"));
      }

      //////////////////////////////////////////////
      // 1.5. Show RTC time from Network
      //////////////////////////////////////////////
      Serial.println(F("1.5. RTC Network Time: "));
      
      error = _4G.showTimeFrom4G();

      if (error == 0)
      {
        Serial.println(F("1.5. Time Show OK"));
      }
      else
      {
        Serial.println(F("1.5. Error calling 'showTimeFrom4G' function"));
      }
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("4G module not started"));
    Serial.print(F("Error code: "));
    Serial.println(error, DEC);
  }

  //////////////////////////////////////////////////
  // 2. Switch OFF the 4G module
  //////////////////////////////////////////////////
  Serial.println(F("2. Switch OFF 4G module"));
  _4G.OFF();

  //////////////////////////////////////////////////
  // 3. Sleep
  //////////////////////////////////////////////////
  delay(60000);
}













