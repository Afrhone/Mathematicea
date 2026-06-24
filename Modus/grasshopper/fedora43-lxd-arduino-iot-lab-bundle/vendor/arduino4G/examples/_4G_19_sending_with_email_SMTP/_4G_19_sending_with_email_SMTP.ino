/*
    --------------- 4G_19 - Sending e-mail --------------- 

    Explanation: This example shows how to use send a email using SMTP
    mailbox server.

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

//////////////////////////////////////////////////
char sender_address[] = "";
char sender_user[] = "";
char sender_password[] = "";
char smtp_server[] = "";
char message[] ="This is a e-mail test from Cooking-Hacls";
char receiver_address[] = "";
char subject[] = "e-mail test";
//////////////////////////////////////////////////

uint8_t error;


void setup()
{
  //////////////////////////////////////////////////
  // 0. sets operator parameters
  //////////////////////////////////////////////////
  _4G.set_APN(apn, login, password);

  //////////////////////////////////////////////////
  // 0.1 Show APN settings via Serial port
  //////////////////////////////////////////////////
  _4G.show_APN();

  //////////////////////////////////////////////////
  // 1. Switch on the 4G module
  //////////////////////////////////////////////////
  error = _4G.ON();

  if (error == 0)
  {
    Serial.println(F("1. 4G module ready..."));

    ////////////////////////////////////////////////
    // 2. Reset e-mail parameters
    ////////////////////////////////////////////////
    error = _4G.emailResetConfig();

    if (error == 0)
    {
      Serial.println(F("2. Reset done OK"));    
    }
    else
    {
      Serial.print(F("2. Error reset configuration. Code: "));
      Serial.println(error, DEC);
    } 
    
    ////////////////////////////////////////////////
    // 3. Set SMTP server
    ////////////////////////////////////////////////
    error = _4G.emailSetServerSMTP(smtp_server);

    if (error == 0)
    {
      Serial.println(F("3. SMTP server set OK"));    
    }
    else
    {
      Serial.print(F("3. Error set server. Code: "));
      Serial.println(error, DEC);
    } 

    ////////////////////////////////////////////////
    // 4. Set sender address
    ////////////////////////////////////////////////
    error = _4G.emailSetSenderAddress(sender_address);

    if (error == 0)
    {
      Serial.println(F("4. Sender addres set OK")); 
    }
    else
    {
      Serial.print(F("4. Error set address. Code: "));
      Serial.println(error, DEC);
    }    

    ////////////////////////////////////////////////
    // 5. Set sender user
    ////////////////////////////////////////////////
    error = _4G.emailSetSenderUser(sender_user);

    if (error == 0)
    {
      Serial.println(F("5. Sender user set OK")); 
    }
    else
    {
      Serial.print(F("5. Error set user. Code: "));
      Serial.println(error, DEC);
    }    

    ////////////////////////////////////////////////
    // 6. Set sender login password
    ////////////////////////////////////////////////
    error = _4G.emailSetSenderPassword(sender_password);

    if (error == 0)
    {
      Serial.println(F("6. Sender password set OK")); 
    }
    else
    {
      Serial.print(F("6. Error set password. Code: "));
      Serial.println(error, DEC);
    }    
    
    ////////////////////////////////////////////////
    // 7. Configure SMTP server security and port
    ////////////////////////////////////////////////
    error = _4G.emailSMTPConfig(EMAIL_NONSSL,25);

    if (error == 0)
    {
      Serial.println(F("7. Configure SMTP server OK")); 
    }
    else
    {
      Serial.print(F("7. Error configuring SMTP server. Code: "));
      Serial.println(error, DEC);
    }     
     
    ////////////////////////////////////////////////
    // 8. Save e-mail configuration settings
    ////////////////////////////////////////////////
    error = _4G.emailSaveConfig();

    if (error == 0)
    {
      Serial.println(F("8. Save configuration OK")); 
    }
    else
    {
      Serial.print(F("8. Error saving configuration. Code: "));
      Serial.println(error, DEC);
    }      
  }
  else
  {
    Serial.print(F("1. Error starting module. Code: "));
    Serial.println(error, DEC);
  } 
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
    // 2. Send e-mail
    ////////////////////////////////////////////////
    error = _4G.emailSend(receiver_address,subject,message);

    if (error == 0)
    {
      Serial.println(F("2. Sending e-mail OK")); 
    }
    else
    {
      Serial.print(F("2. Error sending e-mail. Code: "));
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
