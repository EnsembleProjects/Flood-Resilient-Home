// Author: Val Williams 2Aug18
// reads 15 input sensors (reed switches or buttons or anything else)
// their port numbers and type (open/closed) are configurable below
// (don't use port 13 as input, because it's the onboard LED)
// sends comma-separated list of 0 or 1 to the serial port
// if any sensor input is On, the onboard LED is lit

const int LED_PIN = 13;                     // LED pin - active-high

const int numSensors = 15;
int pinValue[numSensors];
int portNumber[numSensors] = {0,1,2,3,4,5,6,7,8,9,10,11,12,15,16};  // input port number for each sensor
int portType[numSensors] = {INPUT_PULLUP,   // 0
                            INPUT_PULLUP,   // 1
                            INPUT_PULLUP,   // 2 - cabinet switch
                            INPUT,          // 3 - Hall effect PCB switch
                            INPUT,          // 4 - Keyes PCB reed switch
                            INPUT_PULLUP,   // 5
                            INPUT_PULLUP,   // 6
                            INPUT_PULLUP,   // 7 - buttonA
                            INPUT_PULLUP,   // 8 - buttonB
                            INPUT_PULLUP,   // 9 - reed switch
                            INPUT_PULLUP,   // 10 - reed switch
                            INPUT_PULLUP,   // 11 - reed switch
                            INPUT_PULLUP,   // 12
                            INPUT_PULLUP,   // 13
                            INPUT_PULLUP};  // 14
// set true if port normally-open, false if normally closed
boolean portInverted[numSensors] = {true,   // 0
                                    true,   // 1
                                    true,   // 2
                                    true,   // 3
                                    false,  // 4
                                    true,   // 5
                                    true,   // 6
                                    true,   // 7
                                    true,   // 8
                                    true,   // 9
                                    true,   // 10
                                    true,   // 11
                                    true,   // 12
                                    true,   // 13
                                    true};  // 14

void setup() 
{
  Serial.begin(9600);
  for (int i = 0; i < numSensors; i++)  // set input type for sensor ports
    pinMode(portNumber[i], portType[i]);
  pinMode(LED_PIN, OUTPUT);             //set LED pin as output
}

void loop() 
{
  boolean ledOn = false;

  // read the state of all switches into pinValue array
  // and set ledOn if any of them are activated
  for (int i = 0; i < numSensors; i++)
  {
    if (portInverted[i])
      pinValue[i] = !(digitalRead(portNumber[i]));
    else
      pinValue[i] = (digitalRead(portNumber[i]));
    if (pinValue[i] == HIGH)
    {
      ledOn = true;
      //Serial.print("Sensor "); Serial.print(i, DEC); Serial.println(" activated");
    }
  }

  // turn the LED on if there are any active sensors, else turn it off
  if (ledOn)
    digitalWrite(LED_PIN, HIGH);      // Turn the LED on
  else
  {
    digitalWrite(LED_PIN, LOW);       // Turn the LED off
    //Serial.println("no active sensors");
  }
  
  // send the sensor readings to the Serial output as comma-separated list, e.g. 0,1,1...
  for (int i = 0; i < numSensors-1; i++)
  {
    Serial.print(pinValue[i], DEC);
    Serial.print(",");
  }
  Serial.println(pinValue[numSensors-1], DEC); 
  delay(500);
}

