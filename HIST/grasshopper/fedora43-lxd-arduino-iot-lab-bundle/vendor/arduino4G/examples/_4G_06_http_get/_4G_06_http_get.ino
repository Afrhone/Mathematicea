/*  
    -------------------------- 4G_06 - HTTP GET  ------------------------- 
    
    Explanation: This example shows how to send HTTP GET requests

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

// APN settings
///////////////////////////////////////
char apn[] = "";
char login[] = "";
char password[] = "";
///////////////////////////////////////

// SERVER settings
///////////////////////////////////////
char host[] = "";
uint16_t port = 80;
char resource[] = "";
///////////////////////////////////////

// variables
uint8_t error;


void setup()
{
  error = _4G.ON();
  Serial.println(F("Start program"));
  
  //********************************************************************
  // GET method to the Libelium's test url                              
  // You can use this php to test the HTTP connection of the module.    
  // The php returns the parameters the user sends with the URL.        
  //********************************************************************

  //////////////////////////////////////////////////
  // 1. sets operator parameters
  //////////////////////////////////////////////////
  _4G.set_APN(apn, login, password);

  //////////////////////////////////////////////////
  // 2. Show APN settings via USB port
  //////////////////////////////////////////////////
  _4G.show_APN();
}


void loop()
{
  //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////  
  error = _4G.ON();

  if (error == 0)
  {
    Serial.println(F("1. 4G module ready..."));

    ////////////////////////////////////////////////
    // 2. HTTP GET
    ////////////////////////////////////////////////
    Serial.println(F("2. Getting URL with GET method..."));

    // send the request
    error = _4G.http( GET_METHOD, host, port, resource);

    // Check the answer
    if (error == 0)
    {
      Serial.print(F("Done. HTTP code: "));
      Serial.println(_4G._httpCode);
      Serial.print("Server response: ");
      Serial.println((char *)_4G._buffer);
    }
    else
    {
      Serial.print(F("Failed. Error code: "));
      Serial.println(error, DEC);
    }    
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("1. 4G module not started"));
    Serial.print(F("Error code: "));
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
  delay(10000);
}
