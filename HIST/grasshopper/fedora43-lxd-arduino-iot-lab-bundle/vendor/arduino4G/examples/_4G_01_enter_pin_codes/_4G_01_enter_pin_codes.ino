/*  
    ----------------------- 4G_01 - Setting PIN codes --------------------- 
   
    Explanation: This example shows how to check for the PIN code of
    the SIM card. In the case it is enabled, the program asks for the 
    PIN code in order to enter it and access.

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

// define variables
uint8_t PIN_status;
char PIN_code[30];
uint8_t error;
int counter;
int temp;
uint32_t previous;


void setup()
{    
  Serial.println(F("******************************************************************************"));
  Serial.println(F("This example inits the 4G module and request the unlock codes if necessary"));
  Serial.println(F("******************************************************************************"));

  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  previous = millis();
  error = _4G.ON();
  if (error == 0)  
  {
    Serial.print(F("1. 4G module ready in "));	
    Serial.print(millis()-previous);
    Serial.println(F(" ms"));
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("1. 4G module not started"));
    Serial.print(F("Error code: "));
    Serial.println(error, DEC);
  }
}


void loop()
{
  
  //////////////////////////////////////////////////
  // 2. Check PIN code
  //////////////////////////////////////////////////
  Serial.println(F("2. Reading code..."));
  PIN_status = _4G.checkPIN();
  
  switch (PIN_status)
  {
  case 0:
    Serial.println(F("SIM and module unlocked. Ready to use"));
    Serial.println(F("The sketch will stop here"));
    while(1);
    break;

  case 1:
    Serial.println(F("LE910 is awaiting SIM PIN."));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 2:
    Serial.println(F("LE910 is awaiting SIM PUK"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 3:
    Serial.println(F("LE910 is awaiting phone-to-SIM card password."));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 4:
    Serial.println(F("LE910 is awaiting phone-to-very-first-SIM card password."));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 5:
    Serial.println(F("LE910 is awaiting phone-to-very-first-SIM card unblocking password."));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 6:
    Serial.println(F("LE910 is awaiting SIM PIN2"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 7:
    Serial.println(F("LE910 is awaiting SIM PUK2"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 8:
    Serial.println(F("LE910 is awaiting network personalization password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 9:
    Serial.println(F("LE910 is awaiting network personalization unblocking password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 10:
    Serial.println(F("LE910 is awaiting network subset personalization password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 11:
    Serial.println(F("LE910 is awaiting network subset personalization unblocking password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 12:
    Serial.println(F("LE910 is awaiting service provider personalization password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 13:
    Serial.println(F("LE910 is awaiting service provider personalization unblocking password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 14:
    Serial.println(F("LE910 is awaiting corporate personalization password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  case 15:
    Serial.println(F("LE910 is awaiting corporate personalization unblocking password"));
    Serial.println(F("Please, enter the code: "));
    readString(PIN_code);
    break;

  default: 
    Serial.print(F("Error code: "));
    Serial.println(PIN_status, DEC);
    break;
  }

  //////////////////////////////////////////////////
  // 3. Set PIN code
  //////////////////////////////////////////////////
  if ((PIN_status != 0) && (PIN_status < 16))
  {
    Serial.print(F("3. Entering PIN code..."));
    if (_4G.enterPIN(PIN_code) == 0) 
    {
      Serial.println(F("3. done"));
    }
    else
    {
      Serial.println(F("3. error"));
    }
  }
}


/******************************************************************
*
* readString 
*
*
*
*******************************************************************/
void readString(char* message)
{
  int x = 0;	

  // clean input buffer
  Serial.flush();
  
  // wait for incoming data from keyboard
  while(Serial.available() == 0);

  // Treat all incoming bytes
  while (Serial.available() > 0)
  {
    message[x] = Serial.read();

    if( (message[x] == '\r') || (message[x] == '\n') )
    {
      message[x]='\0';
    }
    else
    {
      x++;
    }
  }
}

