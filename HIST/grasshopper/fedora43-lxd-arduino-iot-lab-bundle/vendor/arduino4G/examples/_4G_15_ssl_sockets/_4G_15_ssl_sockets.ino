/*
    --------------- 4G_15 - SSL functions for TCP sockets  ---------------

    Explanation: This example shows how to use the SSL commands so as
    to open a TCP client socket to the specified server address and port.

    Note 1: in Arduino UNO the same UART is used for user debug interface 
    and LE910 AT commands. Handle with care, user interface messages could 
    interfere with AT commands.

    Example: 
          Serial.print("operATo"); 
    It is seen as wrong AT command by the LE910 module.

    Note 2: due to Arduino UNO memory limitations, this example only can 
    work in Arduino MEGA boards.

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
uint16_t remote_port = 443;
///////////////////////////////////////

// define data to send through TCP socket
///////////////////////////////////////
char data[] =
  "GET /getpost_frame_parser.php?counter=1&varA=1&varB=2&varC=3&varE=4&varE=5 HTTP/1.1\r\n"\
  "Host: www.yourhost.com\r\n"\
  "Content-Length: 0\r\n\r\n"; // data as example
///////////////////////////////////////

// define Socket ID (mandatory SOCKET_1)
///////////////////////////////////////
uint8_t socketId = arduino4G::SOCKET_1;
///////////////////////////////////////

// define certificate for SSL
////////////////////////////////////////////////////////////////////////
char certificate[] =
  "-----BEGIN CERTIFICATE-----\r"\
  "MIICGzCCAYQCCQCWP2pnP2wL+TANBgkqhkiG9w0BAQQFADBSMSwwKgYDVQQKDCNM\r"\
  "aWJlbGl1bSBDb211bmlhY2lvbmVzIERpc3RyaWJ1aWRhczELMAkGA1UEBhMCRVMx\r"\
  "FTATBgNVBAMMDGxpYmVsaXVtLmNvbTAeFw0xNTA3MDYxMTAyNDJaFw0yNTA3MDMx\r"\
  "MTAyNDJaMFIxLDAqBgNVBAoMI0xpYmVsaXVtIENvbXVuaWFjaW9uZXMgRGlzdHJp\r"\
  "YnVpZGFzMQswCQYDVQQGEwJFUzEVMBMGA1UEAwwMbGliZWxpdW0uY29tMIGfMA0G\r"\
  "CSqGSIb3DQEBAQUAA4GNADCBiQKBgQCznwc4Rt6HF4CumZqDkMPL9Wn73kyoVDiT\r"\
  "kTST6Gj8IUsqnwftnu959Oqlow5X80foNu/o88zj8bbrSpXsaqaD9Wjt2zDJkdSL\r"\
  "42uElTDY+BuyUEY84L3JJ7InDPSyduayhXlKquNlhjP1SGX/q8WNVPzL05Sw1pPR\r"\
  "QPSt0ow82wIDAQABMA0GCSqGSIb3DQEBBAUAA4GBALEtLedkIjtsCHXxEZeuUA2t\r"\
  "DhIPBt2rIUUKOjcdOtC0AeQzalX1ln279KOoD86NShCRMkKl24SCFgXwQ0e8TcQ3\r"\
  "9Le1A24vGmZtJvc+MFh1bS/b2KmHYOj0ie8QmHBSMVxMIc/opFy3BAmLC9V/90hj\r"\
  "BziFIf5Ff7pZvzBoimQi\r"\
  "-----END CERTIFICATE-----"; // certificate as example
////////////////////////////////////////////////////////////////////////

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
    // 2. Set CA certificate
    ////////////////////////////////////////////////

    error = _4G.manageSSL(socketId, SSL_ACTION_STORE, SSL_TYPE_CA_CERT, certificate);

    if (error == 0)
    {
      Serial.println(F("\n2. Set CA certific OK"));
    }
    else
    {
      Serial.println(F("\n2. Error setting CA certific"));
    }

    ////////////////////////////////////////////////
    // 2. SSL socket
    ////////////////////////////////////////////////

    error = _4G.openSocketSSL(socketId, host, remote_port);

    if (error == 0)
    {
      Serial.println(F("2.1. Opening a socket... done!"));

      //////////////////////////////////////////////
      // 2.2. Send data through socket
      //////////////////////////////////////////////
      
      error = _4G.sendSSL(socketId, data);
      if (error == 0)
      {
        Serial.println(F("2.2. Sending... done!"));
      }
      else
      {
        Serial.print(F("2.2. Error sending. Code: "));
        Serial.println(error, DEC);
      }

      //////////////////////////////////////////////
      // 2.3. Receive data
      //////////////////////////////////////////////

      // Wait for incoming data from the socket (if the other side responds)
      Serial.print(F("2.3. Waiting to receive...\n"));

      error = _4G.receiveSSL(socketId, 60000);
      delay (10000);

      if (error == 0)
      {
        if (_4G._length > 0)
        {
          Serial.println(F("\n-----------------------------------"));
          Serial.print(F("Received:"));
          Serial.println((const char *)_4G._buffer);
          Serial.println(F("-----------------------------------"));
        }
        else
        {
          Serial.println(F("2.3. Nothing received"));
        }
      }
      else
      {
        Serial.print(F("2.3. Nothing received. Error code: "));
        Serial.println(error, DEC);
      }

      //////////////////////////////////////////////
      // 2.4. Close socket
      //////////////////////////////////////////////
      error = _4G.closeSocketSSL(socketId);

      if (error == 0)
      {
        Serial.println(F("2.4. Socket closed OK"));
      }
      else
      {
        Serial.print(F("2.4. Error closing socket. Error code: "));
        Serial.println(error, DEC);
      }
      
    }
    else
    {
      Serial.print(F("2.1. Error opening socket. Error code: "));
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
