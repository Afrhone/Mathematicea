/*
    ------------------------ 4G_11 - TCP client  --------------------------

    Explanation: This example shows how to open a TCP client socket
    to the specified server address and port. Besides, the functions
    for sending/receiving data are used.

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
uint16_t remote_port = 1010;
uint16_t local_port  = 4000;
///////////////////////////////////////

// FRAME
///////////////////////////////////////
char frame[] = "Node01-2016/10/6-Value_1\n";
///////////////////////////////////////

// define Socket ID (from 'SOCKET_1' to 'SOCKET_2')
///////////////////////////////////////
uint8_t socketId = arduino4G::SOCKET_1;
///////////////////////////////////////

// define variables
uint8_t  error;
uint32_t previous;
uint8_t  socketIndex;


void setup()
{
  error = _4G.ON();
  if (error == 0)
    Serial.println(F("module ON..."));
  else
    Serial.println(F("module OFF"));

  Serial.println(F("Start program"));

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
    // 2. TCP socket
    ////////////////////////////////////////////////

    error = _4G.openSocket(socketId, TCP_CLIENT, host, remote_port, local_port);

    if (error == 0)
    {
      Serial.println(F("2.1. Opening a socket... done!"));

      Serial.print(F("IP address:"));
      Serial.println(_4G._ip);

      //////////////////////////////////////////////
      // 2.2. Send data
      //////////////////////////////////////////////

      error = _4G.send(socketId, "This is a test frame from Cooking Hacks!\n");

      if (error == 0)
      {
        Serial.println(F("2.2. Sending a string... done!"));
      }
      else
      {
        Serial.print(F("2.2. Error sending. Code: "));
        Serial.println(error, DEC);
      }

      //////////////////////////////////////////////
      // 2.3. Send a frame and send it through the connection
      //////////////////////////////////////////////

      error = _4G.send(socketId, (uint8_t *)frame, sizeof(frame));
      if (error == 0)
      {
        Serial.println(F("2.3. Sending a frame... done!"));
      }
      else
      {
        Serial.print(F("2.3. Error sending a frame. Code: "));
        Serial.println(error, DEC);
      }

      //////////////////////////////////////////////
      // 2.4. Receive data
      //////////////////////////////////////////////

      // Wait for incoming data from the socket (if the other side responds)
      Serial.print(F("2.4. Waiting to receive..."));

      error = _4G.receive(socketId, 60000);

      if (error == 0)
      {
        if (_4G.socketInfo[socketId].size > 0)
        {
          Serial.println(F("\n-----------------------------------"));
          Serial.print(F("Received:"));
          Serial.println((const char *)_4G._buffer);
          Serial.println(F("-----------------------------------"));
        }
        else
        {
          Serial.println(F("Nothing received"));
        }
      }
      else
      {
        Serial.println(F("Nothing received."));
        Serial.println(error, DEC);
      }
    }
    else
    {
      Serial.print(F("2.1. Error opening socket. Error code: "));
      Serial.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 2.5. Close socket
    //////////////////////////////////////////////
    error = _4G.closeSocket(socketId);

    if (error == 0)
    {
      Serial.println(F("2.5. Socket closed OK"));
    }
    else
    {
      Serial.print(F("2.5. Error closing socket. Error code: "));
      Serial.println(error, DEC);
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("1. 4G module not started"));
  }

  ////////////////////////////////////////////////
  // 3. Powers off the 4G module
  ////////////////////////////////////////////////
  Serial.println(F("3. Switch OFF 4G module"));
  _4G.OFF();

  ////////////////////////////////////////////////
  // 4. Sleep
  ////////////////////////////////////////////////

  delay(5000);
}
