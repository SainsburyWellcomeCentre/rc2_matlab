/* repeat_encoders.ino
   Write EncA to TTL0
   Write EncB to TTL1
*/

const int EncA = 0;
const int EncB = 1;

const int TTL0 = 6;
const int TTL1 = 14;


void setup() {
  
  pinMode(EncA, INPUT);
  pinMode(EncB, INPUT);
  
  pinMode(TTL0, OUTPUT);
  pinMode(TTL1, OUTPUT);
}


void loop() {

  digitalWrite(TTL0, digitalRead(EncA));
  digitalWrite(TTL1, digitalRead(EncB));
}
