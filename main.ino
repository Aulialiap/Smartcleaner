#include <EEPROM.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Wire.h> 
#include <LowPower.h>
#include <Servo.h>
#define buzzer 13
#define button2 3
#define button1 2
Servo ServoMotor;

byte SMILEY[] = {B00000, B00000, B01010, B01010, B00000, B10001, B01110, B00000};
byte Locked[] = {B00000, B01110, B01010, B11111, B11011, B11011, B11111, B00000};

void InitialPassword();
bool checking(char[],char[]);
void PrintPress(char[],bool);
void ChangePassword();
void HematDaya();
void wakeUp();

char USSD[4]="*123";
char password[4];
char initial_password[4];
char key_pressed = 0;
LiquidCrystal_I2C LCD(0x27, 16, 2);
int input = LOW; 
int kondisi_sblm = LOW; 
unsigned long waktu_debouncing = 0; 
unsigned long delay_debouncing = 50;
bool master = false;

const byte rows = 4;
const byte cols = 4;
char hexaKeys[rows][cols] = {
    {'1','2','3','A'},
    {'4','5','6','B'},
    {'7','8','9','C'},
    {'*','0','#','D'}
};
byte rowPins[rows] = {4,5,6,7};
byte colPins[cols] = {8,9,10,11}; 
Keypad keypad = Keypad(makeKeymap(hexaKeys), rowPins, colPins, rows, cols);


void setup() {
  Serial.begin(9600);
  ServoMotor.attach(12);
  pinMode(button1, INPUT_PULLUP);
  pinMode(button2, INPUT_PULLUP);
  pinMode(buzzer, OUTPUT);
  LCD.init();
  LCD.backlight();
  LCD.createChar(0,SMILEY);
  LCD.createChar(1,Locked);
  InitialPassword();
  attachInterrupt(digitalPinToInterrupt(button1), wakeUp, FALLING);
  attachInterrupt(digitalPinToInterrupt(button2), Master, FALLING);
}

void loop() {
  master = false;
  HematDaya();
  LCD.display();
  LCD.backlight();
  LCD.clear();
  LCD.setCursor(3,0);
  LCD.print("Enter Pass");
  PrintPress(password,false);
  if(checking(password,USSD)==true){
    ChangePassword();
  } else{
    if(checking(password,initial_password)==true){
      UnlockPass();
    }else if(checking(password,initial_password)==false){
      LockPass();
    }
  }
  LCD.clear();
  clearpass();
  ServoMotor.write(180);
  delay(200);
}

void PrintPress(char a[], bool flagInitial) {
  unsigned long previousMillis = millis();
  unsigned long interval = 10000;  
  LCD.setCursor(6, 1);
  int i = 0;
  while (i < 4) {
    if(flagInitial==false){
      unsigned long currentMillis = millis();
      if (currentMillis - previousMillis >= interval) {
        return;
      }
    }
    key_pressed = keypad.getKey();
    if (key_pressed != NO_KEY) {
      a[i] = key_pressed;
      LCD.print(a[i]);
      i++;
      delay(200);
      previousMillis = millis();
    }
    if(flagInitial==true){
      for(int i = 0; i < 4; i++){
        EEPROM.write(i, a[i]); 
      }
    }
  }
}

bool checking(char pw[], char a[]){
  if(!(strncmp(pw,a,4))){
    return true;
  } else{
    return false;
  }
}

void wakeUp(){}
void HematDaya(){
  ServoMotor.write(180);
  delay(200);
  LCD.noBacklight();
  LCD.noDisplay();
  LowPower.powerDown(SLEEP_FOREVER, ADC_OFF, BOD_OFF);
}

void Master(){
  if (master == false){
    int kondisi = digitalRead(button2); 
    int press = false;
    if(kondisi != kondisi_sblm){ 
      waktu_debouncing = millis(); 
    } 
    if((millis()-waktu_debouncing) > delay_debouncing){ 
      if(kondisi != input){ 
        input = kondisi; 
      } 
    } 
    kondisi_sblm = kondisi; 
    if(input == HIGH){
      press = true;
    }else{
      press = false;
    }
    if(press == true){
      ServoMotor.write(180);
      delay(200);
    }else{
      ServoMotor.write(0);
      delay(200);
    }
    master = true;
  }
}

void InitialPassword(){
  LCD.clear();
  LCD.setCursor(3,0);
  LCD.print("WITTYLATCH");
  LCD.setCursor(0,1);
  LCD.print("Electronic Lock");
  LCD.write(byte(0));
  delay(3000);
  LCD.clear();
  LCD.setCursor(2,0);
  LCD.print("Set Password");
  LCD.setCursor(6, 1);
  PrintPress(initial_password, true);
  LCD.clear();
  ServoMotor.write(180);
  delay(200);
}

void UnlockPass(){
  LCD.clear();
  LCD.setCursor(1,0);
  ServoMotor.write(0);
  digitalWrite(buzzer, HIGH);
  LCD.print("Pass Accepted!");
  LCD.setCursor(5,1);
  LCD.print("Unlock");
  delay(500);
  digitalWrite(buzzer, LOW);
  LCD.clear();
  for (int j = 0; j < 16; j++) {
    LCD.clear();
    if(j>2){
      LCD.setCursor(j-4,0);
      LCD.print("HAVE");
      LCD.write(byte(0));
    }
    LCD.setCursor(15 - j, 1);
    LCD.print("A NICE DAY");
    delay(45);
  }
  digitalWrite(buzzer, HIGH);
  delay(500);
  digitalWrite(buzzer, LOW);
  delay(15000);
}

void LockPass(){
    LCD.clear();
    LCD.setCursor(1,0);
    ServoMotor.write(180);
    digitalWrite(buzzer, HIGH);
    LCD.print("Wrong Password");
    LCD.setCursor(7,1);
    LCD.write(byte(1));
    LCD.write(byte(1));
    delay(1000);
    digitalWrite(buzzer, LOW);
    delay(1000);
}

void ChangePassword(){
  LCD.clear();
  LCD.setCursor(2,0);
  LCD.print("Change Pass");
  LCD.setCursor(1,1);
  LCD.print("Please  Verify");
  delay(1500);
  LCD.clear();
  LCD.setCursor(1,0);
  LCD.print("Enter Old Pass");
  PrintPress(password, false);
  if(checking(password,initial_password)==true){
    LCD.clear();
    LCD.setCursor(1,0);
    LCD.print("Enter New Pass");
    PrintPress(initial_password, true);
    LCD.clear();
    LCD.setCursor(6,0);
    LCD.print("PASS");
    LCD.setCursor(2,1);
    LCD.print("HAS CHANGED!");
    delay(2000);
  }else{
    LCD.clear();
    LCD.setCursor(1,0);
    LCD.print("Wrong Password");
    LCD.setCursor(3,1);
    LCD.print("Try  Again");
    delay(2000);
  }
}

void clearpass(){
  for(int i = 0; i < 4; i++){
    password[i] = 0;
  }
}
