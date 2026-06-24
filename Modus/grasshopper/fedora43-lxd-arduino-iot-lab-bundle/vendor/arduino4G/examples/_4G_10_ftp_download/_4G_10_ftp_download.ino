/*
    ----------- 4G_10 - Downloading files to a FTP server  -----------

    Explanation: This example shows how to download a file from a FTP
    server to Arduino SD card

    Note 1: in Arduino UNO the same UART is used for user debug interface 
    and LE910 AT commands. Handle with care, user interface messages could 
    interfere with AT commands.

    Example: 
          Serial.print("operATo"); 
    It is seen as wrong AT command by the LE910 module.

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    Note 2: due to Arduino UNO memory limitations, this example only can 
    work in Arduino MEGA boards.

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

#include <arduino4G.h>
#include <SPI.h>
#include <SD.h>

// APN settings
///////////////////////////////////////
char apn[] = "";
char login[] = "";
char password[] = "";
///////////////////////////////////////

// SERVER settings
///////////////////////////////////////
char ftp_server[] = "";
uint16_t ftp_port = 21;
char ftp_user[] = "";
char ftp_pass[] = "";
///////////////////////////////////////

///////////////////////////////////////////////////////////////////////
// Define filenames for SD card and FTP server: (FAT16 NAMES:"AAAAAAAA.EEE")
///////////////////////////////////////////////////////////////////////
char SD_FILE[] = "RECEIVED.TXT";
char SERVER_FILE[] = "COOKING.TXT";
///////////////////////////////////////////////////////////////////////

// SD settings
///////////////////////////////////////
# define SD_CS (4)
///////////////////////////////////////

// define variables
int error;
uint32_t previous;


void setup()
{
  error = _4G.ON();

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
    // 2.1. FTP open session
    ////////////////////////////////////////////////

    error = _4G.ftpOpenSession(ftp_server, ftp_port, ftp_user, ftp_pass);

    if (error == 0)
    {
      Serial.println(F("2.1. FTP open session OK"));

      previous = millis();

      //////////////////////////////////////////////
      // 2.2. FTP download
      //////////////////////////////////////////////
      error = _4G.ftpDownload(SD_FILE, SERVER_FILE);

      if (error == 0)
      {

        Serial.print(F("2.2. Download SD file from FTP server done! "));
        Serial.print(F("Download time: "));
        Serial.print((millis() - previous) / 1000, DEC);
        Serial.println(F(" s"));
      }
      else
      {
        Serial.print(F("2.2. Error calling 'ftpDownload' function. Error: "));
        Serial.println(error, DEC);
      }

      //////////////////////////////////////////////
      // 2.3. FTP close session
      //////////////////////////////////////////////

      error = _4G.ftpCloseSession();

      if (error == 0)
      {
        Serial.println(F("2.3. FTP close session OK"));
      }
      else
      {
        Serial.print(F("2.3. Error calling 'ftpCloseSession' function. error: "));
        Serial.println(error, DEC);
      }
    }
    else
    {
      Serial.print(F( "FTP connection error: "));
      Serial.println(error, DEC);
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    Serial.println(F("4G module not started"));
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
