/*
    ------------------------ 4G_12 - TCP server ------------------------

    Explanation: This example shows how to open a TCP listening socket
    and waits for incoming connections. After correctly connecting to a
    TCP client, sending/receiving functions are shown

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
uint16_t local_port = 5000;
uint8_t keep_alive  = 240; // From 0 (disabled) to 240 minutes
///////////////////////////////////////

// define Socket ID (from 'SOCKET_1' to 'SOCKET_2')
///////////////////////////////////////
uint8_t socketId = arduino4G::SOCKET_1;
///////////////////////////////////////

// define variables
uint8_t  error;
uint32_t previous;
uint8_t  socketIndex;
boolean  tcp_server_status = false;
uint8_t  socket_state;


void setup()
{
  //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////
  error = _4G.ON();

  if (error == 0)
  {
    Serial.println(F("4G module ready"));

    ////////////////////////////////////////////////
    // Enter PIN code
    ////////////////////////////////////////////////

    /*
      Serial.println(F("Setting PIN code..."));
      if (_4G.enterPIN("****") == 1)
      {
      Serial.println(F("PIN code accepted"));
      }
      else
      {
      Serial.println(F("PIN code incorrect"));
      }
    */

  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("4G module not started"));
  }

  //////////////////////////////////////////////////
  // 2. sets operator parameters
  //////////////////////////////////////////////////
  _4G.set_APN(apn, login, password);

  //////////////////////////////////////////////////
  // 3. Show APN settings via Serial port
  //////////////////////////////////////////////////
  _4G.show_APN();
}


void loop()
{
  //////////////////////////////////////////////////
  // 0. Switch ON
  //////////////////////////////////////////////////
  error = _4G.ON();

  ///////////////////////////////////////////////////////
  // 1. Open TCP Listen on defined port
  ///////////////////////////////////////////////////////

  error = _4G.openSocketListen(socketId, TCP_SERVER, local_port, 240);

  if (error == 0)
  {
    Serial.println(F("1. Socket open"));

    Serial.println(F("----------------------------"));
    Serial.print(F("IP address: "));
    Serial.println(_4G._ip);
    Serial.print(F("Local port: "));
    Serial.println(local_port);
    Serial.println(F("----------------------------"));

    // update flag
    tcp_server_status = true;
  }
  else
  {
    Serial.print(F("1. Error opening socket. Error code: "));
    Serial.println(error, DEC);

    // update flag
    tcp_server_status = false;
  }

  ///////////////////////////////////////////////////////
  // 2. Wait for incoming connection from TCP client
  ///////////////////////////////////////////////////////

  Serial.println(F("2. Wait for incoming connection (10 secs): "));

  error = _4G.manageSockets(10000);

  if (error == 0)
  {
    if (_4G.socketStatus[socketId].state == arduino4G::STATUS_SUSPENDED)
    {
      Serial.println(F("Dta connection in socket:"));
      Serial.println(F("-------------------------------------"));
      Serial.print(F("Socket ID: "));
      Serial.println(_4G.socketStatus[socketId].id, DEC);
      Serial.print(F("Socket Stte: "));
      Serial.println(_4G.socketStatus[socketId].state, DEC);
      Serial.print(F("Socket Local IP: "));
      Serial.println(_4G.socketStatus[socketId].localIp);
      Serial.print(F("Socket Local Port: "));
      Serial.println(_4G.socketStatus[socketId].localPort, DEC);
      Serial.print(F("Socket Remote IP: "));
      Serial.println(_4G.socketStatus[socketId].remoteIp);
      Serial.print(F("Socket Remote Port: "));
      Serial.println(_4G.socketStatus[socketId].remotePort, DEC);
      Serial.println(F("-------------------------------------"));

      // update flag
      tcp_server_status = true;
    }
    else
    {
      tcp_server_status = false;
      Serial.print(F("3. Incorrect Socket Stte: "));
      Serial.println(_4G.socketStatus[socketId].state, DEC);      
    }
  }
  else
  {
    Serial.print(F("3. No incoming dta. Code: "));
    Serial.println(error, DEC);

    // update flag
    tcp_server_status = false;
  }

  ///////////////////////////////////////////////////////
  // 3. Loop while connected
  ///////////////////////////////////////////////////////

  while (tcp_server_status == true)
  {
    //////////////////////////////////////////////
    // 3.1. Get socket info
    //////////////////////////////////////////////
    error = _4G.getSocketInfo(socketId);

    if (error == 0)
    {
      Serial.println(F("3.1. Socket Info since it was opened:"));
      Serial.println(F("-------------------------------------"));
      Serial.print(F("Socket ID: "));
      Serial.println(_4G.socketInfo[socketId].id, DEC);
      Serial.print(F("Socket Sent bytes: "));
      Serial.println(_4G.socketInfo[socketId].sent, DEC);
      Serial.print(F("Socket Received bytes: "));
      Serial.println(_4G.socketInfo[socketId].received, DEC);
      Serial.print(F("Socket pending bytes read: "));
      Serial.println(_4G.socketInfo[socketId].size);
      Serial.print(F("Socket bytes sent and not yet acked: "));
      Serial.println(_4G.socketInfo[socketId].ack, DEC);
      Serial.println(F("-------------------------------------"));
    }
    else
    {
      Serial.print(F("3.1. Error getting socket info. Erro code: "));
      Serial.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 3.2. Send data
    //////////////////////////////////////////////
    error = _4G.send(socketId, (char*)"This is a message from Cooking Hacks TCP server\n");

    if (error == 0)
    {
      Serial.println(F("3.2. Dta sent via TCP socket"));
    }
    else
    {
      Serial.println(F("3.2. Error sending dta via TCP socket"));
    }

    //////////////////////////////////////////////
    // 3.3. Receive data
    //////////////////////////////////////////////

    // Wait for incoming data from the socket (if the other side responds)
    Serial.print(F("3.3. Waiting to receive dta (30 secs): "));

    error = _4G.receive(socketId, 30000);

    if (error == 0)
    {
      if (_4G.socketInfo[socketId].size > 0)
      {
        Serial.println(F("\nDta received:"));
        Serial.println(F("====================================="));
        Serial.println((const char *)_4G._buffer);
        Serial.println(F("====================================="));
      }
      else
      {
        Serial.println(F("NO dta received"));
      }
    }
    else
    {
      Serial.println(F("No dta received."));
      Serial.println(error, DEC);
    }

    //////////////////////////////////////////////
    // 3.4. Check Socket Listen status
    /////////////////////////////////////////////
    error = _4G.getSocketStatus(socketId);

    if (error == 0)
    {
      // get state
      socket_state = _4G.socketStatus[socketId].state;
      
      Serial.print(F("3.4. Get socket sttus OK: "));
      Serial.println(socket_state, DEC);


      // check socket status
      if (socket_state == arduino4G::STATUS_CLOSED)
      {
        Serial.println(F("SOCKET CLOSED"));

        // update flag
        tcp_server_status = false;
      }
    }
    else
    {
      Serial.print(F("3.4. Error getting socket sttus. Error code: "));
      Serial.println(error, DEC);

      // update flag
      tcp_server_status = false;
    }

    Serial.println();
  }

  ///////////////////////////////////////////////////////
  // 4. Close socket
  ///////////////////////////////////////////////////////
  error = _4G.closeSocketListen(socketId, TCP_SERVER);

  if (error == 0)
  {
    Serial.println(F("4. Socket closed OK"));
  }
  else
  {
    Serial.print(F("4. Error closing socket. Error code: "));
    Serial.println(error, DEC);
  }

  Serial.println();

  ////////////////////////////////////////////////
  // 5. Powers off the 4G module
  ////////////////////////////////////////////////
  Serial.println(F("3. Switch OFF 4G module"));
  _4G.OFF();

  ////////////////////////////////////////////////
  // 6. Sleep
  ////////////////////////////////////////////////

  delay(5000);
}
