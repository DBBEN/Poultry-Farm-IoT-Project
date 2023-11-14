#include <Arduino.h>
#include <Firebase_ESP_Client.h>
#include <NTPClient.h>
#include <DNSServer.h>
#include <WiFiManager.h>
#include <LiquidCrystal_I2C.h>
#include <PZEM004Tv30.h>
#include <ESP32Servo.h>
#include <DHT.h>
#include <WiFi.h>

#include "json/FirebaseJson.h"
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

#define UPLOAD_INTERVAL             2000
#define READ_INTERVAL               5000
#define REFRESH_INTERVAL            150
#define MAX_VOLTAGE                 260
#define MAX_CURRENT                 100
#define MAX_POWER                   26000
#define MAX_TEMP                    125
#define MAX_HUM                     100
#define API_KEY                     "AIzaSyAaY9ryEzY4YCQh07b3WedqtCMI07yWs7o"
#define DATABASE_URL                "https://pfip-b0793-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define USER_EMAIL                  "pfip@gmail.com"
#define USER_PASS                   "246810"
//----------------------------------------------------------------------------------------------------------------
FirebaseJson content;
FirebaseJson json;
FirebaseJsonData result;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

WiFiManager wifiManager;
Servo _servo;
PZEM004Tv30 pzem(Serial2, PZEM_RX_PIN, PZEM_TX_PIN);
DHT dht(DHT_PIN, DHTTYPE);
LiquidCrystal_I2C lcd(LCD_I2C_ADDR, LCD_COLUMNS, LCD_ROWS);

// Define NTP Client to get time
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "asia.pool.ntp.org");

int _temp, _hum;
float _pow, _curr, _energy; 
int _vol;

int _setVol, _setTemp, _setServo;
bool _setSwitch = false;
unsigned long _setAlarm;

int _homeFlag = 0;
char tempBuff[20], humBuff[20], volBuff[20], currBuff[20], powBuff[20], enerBuff[20];
unsigned long lastReadingTime, lastDisplayTime, lastUploadTime, timestamp, lastRefresh;

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

void energyLayout(){
  lcd.print("E: ");
}

unsigned long getTime() {
  timeClient.update();
  unsigned long now = timeClient.getEpochTime();
  return now;
}

void activateServo(){
  _servo.write(0);
  delay(1000);
  _servo.write(180);
  delay(1000);
  _servo.write(0);
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

  delay(1000);

  // WIFI - FIREBASE -------------------------------------------------------------
  WiFi.mode(WIFI_STA);
  wifiManager.setConnectRetries(2);
  wifiManager.setConnectTimeout(10);
  wifiManager.setConfigPortalTimeout(500);
  wifiManager.setConfigPortalBlocking(false);
  wifiManager.autoConnect("Poultry Farm IoT Device");

  Serial.print("Total heap: ");
  Serial.println(ESP.getHeapSize());
  Serial.print("Free heap: ");
  Serial.println(ESP.getFreeHeap());

  delay(2000);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASS;
  
  config.token_status_callback = tokenStatusCallback;
  //config.max_token_generation_retry = 5;

  Firebase.reconnectNetwork(false);
  fbdo.setBSSLBufferSize(15000 , 15000);
  fbdo.setResponseSize(4096);
  fbdo.keepAlive(5, 5, 1);
  Firebase.begin(&config, &auth);
  // ------------------------------------------------------------------------------
  lcd.clear();
  lcd.print("Connected!");
  Serial.println("Connected!");
  delay(2000);
 
  lcd.clear();

  digitalWrite(RELAY_PIN, LOW);
  
  timeClient.begin();
  timeClient.setTimeOffset(28800);

  powerLayout();
}

void loop() {
  if(Firebase.ready()){

    if(millis() - lastRefresh >= REFRESH_INTERVAL || lastRefresh == 0){
      if(digitalRead(BTN_PIN) == HIGH){
        lcd.clear();
        _homeFlag += 1;
        if(_homeFlag > 2) _homeFlag = 0;

        if(_homeFlag == 1) {
          energyLayout();
        } else if (_homeFlag == 2) {
          tempHumLayout();
        } else { 
          powerLayout(); 
        }
      }
      lastRefresh = millis();
    }
    
    if((millis() - lastUploadTime >= 2000) || lastUploadTime == 0){ 
      _temp = dht.readTemperature();
      _hum = dht.readHumidity();

      _vol = pzem.voltage();
      _curr = pzem.current();
      _pow = pzem.power();
      _energy = pzem.energy();

      if (isnan(_temp) || isnan(_hum)) {
        Serial.println(F("Failed to read from DHT sensor!"));
        return;
      }

      if(isnan(_vol) || isnan(_curr) || isnan(_pow)){
        // Serial.println(F("Failed to read from PZEM004 sensor!"));
        // return;
        _vol = 0;
        _curr = 0;
        _pow = 0;
        _energy = 0;
      }

      if(_vol > MAX_VOLTAGE) _vol = 0;
      if(_curr > MAX_CURRENT) _curr = 0;
      if(_pow > MAX_POWER) _pow = 0;
      if(_temp > MAX_TEMP) _temp = 0;
      if(_hum > MAX_HUM) _temp = 0;

      timestamp = getTime();
      content.set("timestamp", timestamp);
      content.set("temp-reading", _temp);
      content.set("hum-reading", _hum);
      content.set("vol-reading", _vol);
      content.set("curr-reading", _curr);
      content.set("pow-reading", _pow);
      content.set("ener-reading", _energy);
      if(Firebase.RTDB.set(&fbdo, "device-live", &content)); else Serial.println(fbdo.errorReason());
      if(Firebase.RTDB.push(&fbdo, "device-records", &content)); else Serial.println(fbdo.errorReason());

      sprintf(tempBuff, "%2d%cC", _temp, char(223));
      sprintf(humBuff, "%2d%%", _hum);
      sprintf(volBuff, "%3dV", _vol);
      sprintf(currBuff, "%.2fA", _curr);
      sprintf(powBuff, "%3.2fW", _pow);
      sprintf(enerBuff, "%3.3fkWh", _energy);

      if(_homeFlag == 2){
        lcd.setCursor(6, 0);
        lcd.print(tempBuff);
        lcd.setCursor(5, 1);
        lcd.print(humBuff);
      } else if (_homeFlag == 1){
        lcd.setCursor(3, 0);
        lcd.print(enerBuff);
      } else {
        lcd.setCursor(3, 0);
        lcd.print(volBuff);
        lcd.setCursor(3, 1);
        lcd.print(currBuff);
        lcd.setCursor(11, 0);
        lcd.print(powBuff);
      }

      lastUploadTime = millis();
    }

    else if((millis() - lastReadingTime) >= READ_INTERVAL){
      if(Firebase.RTDB.getJSON(&fbdo, "device-params/")); else Serial.println(fbdo.errorReason());
      json.setJsonData(fbdo.to<FirebaseJson>().raw());
      json.get(result, "set-switch");
      _setSwitch = result.boolValue;
      json.get(result, "set-alarm");
      _setAlarm = result.intValue;
      json.get(result, "set-servo");
      _setServo = result.intValue;
      json.get(result, "max-vol");
      _setVol = result.intValue;
      json.get(result, "set-temp");
      _setTemp = result.intValue;
      
      if(_vol > _setVol) digitalWrite(RELAY_PIN, LOW);
      if(_temp > _setTemp) digitalWrite(RELAY_PIN, LOW);
      if(_setServo == 1){
        activateServo();
        if(Firebase.RTDB.setInt(&fbdo, "device-params/set-servo", 0)); else Serial.println(fbdo.errorReason());
      }

      
      digitalWrite(RELAY_PIN, _setSwitch);
      lastReadingTime = millis();
    }
  }

}

