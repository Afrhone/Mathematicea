/*  
    ---------------------- 4G_04 - Sending SMS ---------------------- 
   
    Explanation: This example shows how to set up the module to use
    SMS and send text messages

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

//////////////////////////////////////////////////
char phone_number[] = "";
char sms_body[] = "";
//////////////////////////////////////////////////

// variables
uint8_t error;


void setup()
{
}


void loop()
{
  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();

  if (error == 0)
  {
    Serial.println(F("1. 4G module ready..."));

    ////////////////////////////////////////////////
    // 2. Configure SMS options
    ////////////////////////////////////////////////
    error = _4G.configureSMS();

    if (error == 0)
    {
      Serial.println(F("2.1. 4G module configured to use SMS"));		
    }
    else
    {
      Serial.print(F("2.1. Error calling 'configureSMS' function. Code: "));
      Serial.println(error, DEC);
    } 

    ////////////////////////////////////////////////
    // 3. Send SMS
    ////////////////////////////////////////////////
    Serial.println(F("4.2. Sending SMS..."));
    error = _4G.sendSMS( phone_number, sms_body);

    if (error == 0)
    {
      Serial.println(F(" done"));	
    }
    else
    {
      Serial.print(F("error. Code: "));
      Serial.println(error, DEC);
    }    
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.print(F("1. 4G module not started. Error code: "));
    Serial.println(error, DEC);
  }

  ////////////////////////////////////////////////
  // 3. Powers off the 4G module
  ////////////////////////////////////////////////
  Serial.println(F("3. Switch OFF 4G module"));
  _4G.OFF();

  ////////////////////////////////////////////////
  // 4. Sleep
  ////////////////////////////////////////////////
  delay(60000);
}
