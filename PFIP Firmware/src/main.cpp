#include <Arduino.h>
#include <Firebase_ESP_Client.h>
#include <NTPClient.h>
#include <WiFiManager.h>
#include <LiquidCrystal_I2C.h>
#include <PZEM004Tv30.h>
#include <ESP32Servo.h>
#include <DHT.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// PINOUT --------------------------------------------------------------------------------------------------------
#define SERVO_PIN                   2
#define DHT_PIN                     4
#define BTN_PIN                     5
#define PZEM_RX_PIN                 16
#define PZEM_TX_PIN                 17
#define RELAY_PIN                   18
//----------------------------------------------------------------------------------------------------------------

// PARAMS --------------------------------------------------------------------------------------------------------
#define LCD_COLUMNS                 16
#define LCD_ROWS                    4
#define LCD_I2C_ADDR                0x27
#define DHTTYPE DHT22   // DHT 22  (AM2302), AM2321

#define READ_SENSORS_INTERVAL       3000
#define DISPLAY_SENSORS_INTERVAL    2000
#define MAX_VOLTAGE                 260
#define MAX_CURRENT                 100
#define MAX_POWER                   26000
#define API_KEY         "AIzaSyAMAhuxQ_KLs6pn98Yu-QBwpysDwPkOzD8"
#define DATABASE_URL    "https://poultryfarm-82909-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define PROJECT_ID      "poultryfarm-82909"
//----------------------------------------------------------------------------------------------------------------

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

Servo _servo;
PZEM004Tv30 pzem(Serial2, PZEM_RX_PIN, PZEM_TX_PIN);
DHT dht(DHT_PIN, DHTTYPE);
LiquidCrystal_I2C lcd(LCD_I2C_ADDR, LCD_COLUMNS, LCD_ROWS);

// Define NTP Client to get time
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

int _temp, _hum;
float _pow, _curr; 
int _vol;
int _homeFlag = 0;
char tempBuff[20], humBuff[20], volBuff[20], currBuff[20], powBuff[20];
unsigned long lastReadingTime, lastDisplayTime, timestamp;

void tempHumLayout(){
  lcd.print("TEMP: ");
  lcd.setCursor(0, 1);
  lcd.print("HUM: ");
}

void powerLayout(){
  lcd.print("V: ");
  lcd.setCursor(0, 1);
  lcd.print("C: ");
  lcd.setCursor(8, 0);
  lcd.print("P: ");
}

unsigned long getTime() {
  timeClient.update();
  unsigned long now = timeClient.getEpochTime();
  return now;
}

void setup() {
  lcd.init();
  lcd.backlight();
  Serial.begin(9600);
  dht.begin();

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BTN_PIN, INPUT);

  ESP32PWM::allocateTimer(0);
	ESP32PWM::allocateTimer(1);
	ESP32PWM::allocateTimer(2);
	ESP32PWM::allocateTimer(3);
	_servo.setPeriodHertz(50);   
	_servo.attach(SERVO_PIN, 500, 2400);
  lcd.print("Connecting...");

  // WIFI - FIREBASE -------------------------------------------------------------
  WiFiManager wifiManager;
  wifiManager.autoConnect("Poultry Farm IoT Device");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", "")){
    Serial.println("ok");
    signupOK = true;
  }
  else{
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  config.token_status_callback = tokenStatusCallback; 
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  // ------------------------------------------------------------------------------
  lcd.clear();
  lcd.print("Connected!");

  _servo.write(0);
  delay(1000);
  _servo.write(90);
  delay(1000);
  _servo.write(0);
  lcd.clear();

  digitalWrite(RELAY_PIN, HIGH);
  delay(2000);
  digitalWrite(RELAY_PIN, LOW);
  delay(2000);
  digitalWrite(RELAY_PIN, HIGH);
  

  powerLayout();
}

void loop() {
  
  if(digitalRead(BTN_PIN) == HIGH){
    lcd.clear();
    if(_homeFlag > 0) {
      _homeFlag = 0;
      powerLayout(); 
    } else { 
      _homeFlag = 1;
      tempHumLayout(); 
    }
    delay(150);
  }

  if((millis() - lastReadingTime) >= READ_SENSORS_INTERVAL || millis() < READ_SENSORS_INTERVAL){
    _temp = dht.readTemperature();
    _hum = dht.readHumidity();

    if (isnan(_temp) || isnan(_hum)) {
      Serial.println(F("Failed to read from DHT sensor!"));
      return;
    }

    _vol = pzem.voltage();
    _curr = pzem.current();
    _pow = pzem.power();

    if(isnan(_vol) || isnan(_curr) || isnan(_pow)){
      Serial.println(F("Failed to read from PZEM004 sensor!"));
      return;
    }

    if(_vol > MAX_VOLTAGE) _vol = 0;
    else if (_vol == MAX_VOLTAGE) _vol = MAX_VOLTAGE;

    if(_curr > MAX_CURRENT) _curr = 0;
    else if (_curr == MAX_CURRENT) _curr = MAX_CURRENT;

    if(_pow > MAX_POWER) _pow = 0;
    else if (_pow == MAX_POWER) _pow = MAX_POWER;

    // Serial.print("TEMP: ");
    // Serial.print(_temp);
    // Serial.print(" | HUM: ");
    // Serial.print(_hum);
    // Serial.print(" | VOL: ");
    // Serial.print(_vol);
    // Serial.print(" | CURR: ");
    // Serial.print(_curr);
    // Serial.print(" | POW: ");
    // Serial.print(_pow);
    // Serial.print(" | ADDR:");
    // Serial.print(pzem.readAddress(), HEX);
    // Serial.println();
    
    sprintf(tempBuff, "%2d%cC", _temp, char(223));
    sprintf(humBuff, "%2d%%", _hum);
    sprintf(volBuff, "%3dV", _vol);
    sprintf(currBuff, "%.2fA", _curr);
    sprintf(powBuff, "%3.1fW", _pow);

    if(Firebase.ready() && signupOK){
      FirebaseJson content;
      timestamp = getTime();
      content.set("/timestamp", timestamp);
      content.set("/temp-reading", _temp);
      content.set("/hum-reading", _hum);
      content.set("/vol-reading", _vol);
      content.set("/curr-reading", _curr);
      content.set("/pow-reading", _pow);
      if(Firebase.RTDB.setJSON(&fbdo, "/device-live", &content)); else Serial.println(fbdo.errorReason());
      if(Firebase.RTDB.pushJSON(&fbdo, "/device-records", &content)); else Serial.println(fbdo.errorReason());
    }

    lastReadingTime = millis();
  }

  if((millis() - lastDisplayTime) >= DISPLAY_SENSORS_INTERVAL || millis() < DISPLAY_SENSORS_INTERVAL){

    if(_homeFlag > 0){
      lcd.setCursor(6, 0);
      lcd.print(tempBuff);
      lcd.setCursor(5, 1);
      lcd.print(humBuff);
    } else {
      lcd.setCursor(3, 0);
      lcd.print(volBuff);
      lcd.setCursor(3, 1);
      lcd.print(currBuff);
      lcd.setCursor(11, 0);
      lcd.print(powBuff);
    }
    
    lastDisplayTime = millis();
  }

  
}

