/*
    ----------- 4G_09 - Uploading files to a FTP server  -----------

    Explanation: This example shows how to upload a file to a FTP server
    from Arduino.

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
// Define filenames for SD card and FTP server:
///////////////////////////////////////////////////////////////////////
char SD_FILE[]     = "SENT.TXT";
char SERVER_FILE[] = "COOKING.TXT";
///////////////////////////////////////////////////////////////////////

// SD settings
///////////////////////////////////////
# define SD_CS (4)
///////////////////////////////////////

// define variables
int error;
uint32_t previous;
uint8_t sd_answer;
File myFile;


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

  //////////////////////////////////////////////////
  // 1. Create a new file to upload
  //////////////////////////////////////////////////

  ///////////////////////////////////
  // 1.1. Init SD card
  ///////////////////////////////////
  Serial.println("Initializing SD card...");

  sd_answer = SD.begin(SD_CS);
  if (sd_answer != 0) 
  {
    Serial.println("1. SD init OK");
  }
  else
  {
    Serial.println("1. SD init ERROR");
  }
  
  ///////////////////////////////////
  // 1.2. Delete file if exists
  ///////////////////////////////////

  sd_answer = SD.exists(SD_FILE);
  if (sd_answer == 1)
  {
    SD.remove(SD_FILE);
    Serial.println(F("2. File deleted"));
  }
  else
  {
    Serial.println(F("2. File NOT deleted"));
  }

  ///////////////////////////////////
  // 1.3. Create file
  ///////////////////////////////////
  myFile = SD.open(SD_FILE, FILE_WRITE);

  sd_answer = SD.exists(SD_FILE);
  if (sd_answer == 1)
  {
    Serial.println(F("3. New file"));
  }
  else
  {
    Serial.println(F("3. NO new file"));
  }

  ///////////////////////////////////
  // 1.4. Append contents
  ///////////////////////////////////
  Serial.println(F("4. Appending text..."));
  for (int i = 0; i < 10; i++)
  {
    if (SD_FILE)
    {
      myFile.println("This is a new message from Cooking-Hacks");
    }
  }

  ///////////////////////////////////
  //1.5. Close SD
  ///////////////////////////////////
  myFile.close();
  Serial.println(F("5. SD off"));
  Serial.println(F("Setup done\n\n"));
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

    // check answer
    if (error == 0)
    {
      Serial.println(F("2.1. FTP open session OK"));

      previous = millis();

      //////////////////////////////////////////////
      // 2.2. FTP upload
      //////////////////////////////////////////////
      
      error = _4G.ftpUpload(SERVER_FILE, SD_FILE);

      if (error == 0)
      {

        Serial.print(F("2.2. Uploading SD file to FTP server done! "));
        Serial.print(F("Upload time: "));
        Serial.print((millis() - previous) / 1000, DEC);
        Serial.println(F(" s"));
      }
      else
      {
        Serial.print(F("2.2. Error calling 'ftpUpload' function. Error: "));
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
        Serial.print(F("CMEE error: "));
        Serial.println(_4G._errorCode, DEC);        
      }
    }
    else
    {
      Serial.print(F( "2.1. FTP connection error: "));
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
    delay(10000);
}
