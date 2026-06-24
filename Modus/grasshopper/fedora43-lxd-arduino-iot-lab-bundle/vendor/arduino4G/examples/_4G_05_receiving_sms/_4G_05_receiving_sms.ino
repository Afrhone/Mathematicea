/*  
    ----------------------- 4G_05 - Receiving SMS  -------------------- 
    
    Explanation: This example shows how to set up the module to use
    SMS and receive text messages

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
uint8_t error, status, index;
char sms_received[50];


void setup()
{    
  
  Serial.println(F("Start program"));
  
  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();

  if (error == 0)
  {
    Serial.println(F("1. 4G module ready..."));

    ////////////////////////////////////////////////
    // 2. Set PIN code
    ////////////////////////////////////////////////  
    error = _4G.enterPIN((char*)"");

    if (error == 1) 
    {
      Serial.println(F("2. PIN code accepted"));
    }
    else
    {
      Serial.println(F("2. PIN code incorrect"));
    }

    ////////////////////////////////////////////////
    // 2.2. Configure SMS options
    ////////////////////////////////////////////////
    error = _4G.configureSMS();

    if (error == 0)
    {
      Serial.println(F("3. 4G module configured to use SMS"));
    }
    else
    {
      Serial.print(F("3. Error calling 'configureSMS' function. Code: "));
      Serial.println(error, DEC);
    } 
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("4G module not started"));
    Serial.print(F("Error code: "));
    Serial.println(error, DEC);
  }
}


void loop()
{

  //////////////////////////////////////////////
  // 1. Wait for new incoming SMS
  //////////////////////////////////////////////
  error = _4G.readNewSMS(30000);

  if (error == 0)
  {
    Serial.println(F("-----------------------------------"));
    Serial.print(F("SMS index: "));
    Serial.println(_4G._smsIndex, DEC);

    Serial.print(F("SMS Stte: "));
    Serial.println(_4G._smsStatus);

    Serial.print(F("Phone number: "));
    Serial.println(_4G._smsNumber);

    Serial.print(F("SMS day: "));
    Serial.println(_4G._smsDate);

    Serial.print(F("SMS time: "));
    Serial.println(_4G._smsTime);

    Serial.print(F("SMS body: "));
    Serial.println((char *)_4G._buffer);
    Serial.println(F("-----------------------------------"));
  }
  else
  {
    Serial.print(F("No incoming SMS. Code: "));
    Serial.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 2. Read all existing SMS
  //////////////////////////////////////////////

  // init variables
  status = 0;
  index = 1;

  while (status == 0)
  {
    // Read incoming SMS
    status = _4G.readSMS(index);

    if (status == 0)
    {
      Serial.println(F("--- READ SMS ---"));

      Serial.print(F("SMS index: "));
      Serial.println(_4G._smsIndex, DEC);

      Serial.print(F("SMS body: "));
      Serial.println((char *)_4G._buffer);

      Serial.print(F("SMS Sttus: "));
      Serial.println(_4G._smsStatus);

      Serial.print(F("Phone number: "));
      Serial.println(_4G._smsNumber);

      Serial.print(F("SMS day: "));
      Serial.println(_4G._smsDate);

      Serial.print(F("SMS time: "));
      Serial.println(_4G._smsTime);
      Serial.println(F("-------------------------------"));

    }
    else
    {
      Serial.print(F("No more SMS. Code: "));
      Serial.println(error, DEC);
    }

    // increase index to access the next SMS
    index++;
  }

  //////////////////////////////////////////////
  // 3. Delete all existing SMS
  //////////////////////////////////////////////

  // set index to delete to first possible message
  index = 1;
  
  error = _4G.deleteSMS(index, arduino4G::SMS_DELETE_ALL_1);

  if (error == 0)
  {
    Serial.println(F("Delete SMSs done"));
  }
  else
  {
    Serial.print(F("Error calling 'deleteSMS' function. Code:"));
    Serial.println(error, DEC);
  }

  Serial.println(F("************************************************************"));

  delay(5000);
}
