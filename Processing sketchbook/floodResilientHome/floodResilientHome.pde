// Author: Val Williams 31Jul18
// Written for Flood Resilient Home Display, to automatically play short informational film when an item is 
//  placed on the display.  (Items without sensors do not cause any trigger.) 
// Each sensor is associated with a particular item/film. 
// The film plays when its sensor is 1 (i.e. the item is triggered/placed on display). 
// Optionally, the film stops playing when its sensor is 0 (i.e. the item is removed from the display)
// There is a queue of films to be played.  Each film can appear on the queue only once. 
// A film can be replayed: remove item from display for count of debounceSize, then replace. 
// Removal/placement for a count of less than debounceSize is ignored. 
// 
// Instead of triggering on placement of items onto display, the program can be used with separate console,
//  where pressing a button causes the film to play. Here the button is momentary (the user does not have to
//  hold the button down), but the film plays to the end unless interrupted by a different button press.
//
// Expected input from serial port as comma-separated list of sensor values (0 or 1)
// Currently supports 15 sensors/items/films
//
// This program uses the Processing video library (which must be installed)
// If the  following error occurs when this program is run, you will need to change the sketchbook location
//  using File->Preferences to the installation location of processing (e.g. C:\Program Files (x86)) and then
//  reinstall the video library:
//  "A library relies on native code that's not available. Or only works properly when the sketch is run as a
//  32[64]-bit application." 

import java.util.Map;
import processing.serial.*;
import processing.video.Movie;

// if using separate console, set playToCompletion true so that film continues after button released
//boolean playToCompletion = true;    // true if film should play to completion even when item removed from display
boolean playToCompletion = false;   // false if film should stop when item removed from display

// if using separate console, set stopPlayIfOtherSensorPlaced true so that film stops as soon as a different
// button is pressed, so that new film can be seen
// stopPlayIfOtherSensorPlaced=true should be used in conjunction with playToCompletion=true 
//boolean stopPlayIfOtherSensorPlaced = true;   // true if film should stop if another sensor triggers during play
boolean stopPlayIfOtherSensorPlaced = false;  // false if placing an item has no effect on current film

// list of films to play for each sensor, in order of sensor input number
// note: if you want additional information films, you can add these at the end of the list
// and can put them in the playList on start-up
String[] sensorFilm = { "transit.mov",             // boiler
                        "lion.avi",                // kitchen cupboards
                        "launch1.mp4",             // damp proof membrane
                        "launch2.mp4",             // removable doors
                        "transit.mov",             // flooring
                        "transit.mov",             // fridge
                        "transit.mov",             // wall insulation
                        "transit.mov",             // oven
                        "transit.mov",             // telephone
                        "transit.mov",             // one-way valve to prevent seqge reflux
                        "transit.mov",             // raised sockets
                        "transit.mov",             // concrete lower steps
                        "transit.mov",             // sump and pump to drain water from floor
                        "transit.mov",             // washing machine
                        "transit.mov"};            // uPVC windows

// the last 5 values of each sensor (used for debounce) - there must be the same number of readings per row as there are sensors
boolean[][] sensorHistory = {
                             {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false},
                             {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false},
                             {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false},
                             {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false},
                             {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
                            };    // currently have 15 sensors
                            
// number of readings that must match before reading is actioned
// set to sensorHistory.length to use the full range of sensor readings
// set to 1 if you want to react immediately to a sensor reading (i.e. no debounce)
// set between these two values for a small debounce
// NOTE: debounceSize must be <=sensorHistory.length and >0
//int debounceSize = sensorHistory.length;      // item must be in position for sensorHistory.length readings before film plays
//int debounceSize = 3;                         // film plays after item has been in place for 3 readings
int debounceSize = 1;                         // film plays as soon as item is placed (or console switch pressed)

// current debounced state (the last time all sensorHistory records were the same)
boolean[] sensorState =      {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false};

int historyIndex = 0;                             // current Index into sensorHistory (which is used as a circular buffer)
// index number of films waiting to play (in order)
// -1 indicates no film to play
// if you want films to play on start-up, put their index values in this playList 
// (the playList can be any length; it does not have to match the number of sensors)
int[] playList = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}; 

boolean playing = false;

Serial serialPort;
 
Movie[] m = new Movie[sensorFilm.length];

void setup()
{
  // read all films into memory, so they're ready to play as soon as they're needed
  for (int i = 0; i < sensorFilm.length; i++)
    m[i] = new Movie(this, sensorFilm[i]);
    
  //fullScreen();
  size(700,500);
  background(color(0));
  frameRate(10);
  serialPort = new Serial(this, "COM7", 9600);
  serialPort.clear();
  
  // defensive programming to protect against invalid setting of debounceSize
  if (debounceSize < 1)
    debounceSize = 1;
  else if (debounceSize > sensorHistory.length)
    debounceSize = sensorHistory.length;
}


void draw()
{
  // read the sensors, accumulate sensorHistory, and update playList
  readSensors();
  
  // defensive programming: if the next film to play is not a valid Index, remove it from the playList
  while (playList[0] >= sensorFilm.length)
    removeFromPlayListAtIndex(0);
    
  // play/stop films
  if (!playing && playList[0] >=0)
  {
    // play the film
    playing = true;
    m[playList[0]].play();
    //println("Film duration: " + m[playList[0]].duration());
  }
  if (playing && (playList[0] >= 0))
  {
    if (m[playList[0]].available())
    {
      m[playList[0]].read();
      image(m[playList[0]],0,0);
    }
    // check whether film reached the end
    // (note we have to round to 3decplaces when comparing, as different video formats may use different precision for each of these
    if (round2(m[playList[0]].time(),3) >= round2(m[playList[0]].duration(),3))
    {
      println("Reached end of film");
      stopPlaying();
      removeFromPlayListAtIndex(0);
    }
  }
}

void readSensors()
{
  // read the sensor inputs
  if (serialPort.available() > 0)
  {
    // read serial port
    String input = trim(serialPort.readStringUntil('\n'));
    // make sure this is a full line of input with all the sensor readings
    // (sometimes you see half a line, or two merged lines, on the serial port)
    if (input != null)
    {
      String[] inputValue = input.split(",");
      if (inputValue.length == sensorHistory[0].length)
      {
        //println("serial data: " + input);
        // copy readings to next position in sensorHistory (converting to boolean)
        for (int i = 0; i < sensorHistory[0].length; i++)
          sensorHistory[historyIndex][i] = inputValue[i].equals("1");
        // increment to next position in sensorHistory for next readings, wrapping when the end is reached
        if (debounceSize > 1)
        {
          historyIndex++;
          if (historyIndex >= debounceSize)
            historyIndex = 0;
        }
        
        // for debug: display the complete history
        //for (int h = 0; h < sensorHistory.length; h++)
        //{
        //  for (int i = 0; i < sensorHistory[0].length; i++)
        //  {
        //    print(sensorHistory[h][i]); print(" ");
        //  }
        //  println("");
        //}
        //println("");
          
        // for each sensor, check all readings in sensorHistory:
        //      if all true, append to playList
        //      if all false, remove from playList (if it's there), and stop it playing (if it is)
        for (int i = 0; i < sensorHistory[0].length; i++)
        {
          // check if all the history values for this sensor have changed from the last valid state
          boolean changed = true;
          for (int h = 0; h < debounceSize; h++)
          {
            if (sensorState[i] == sensorHistory[h][i])
            {
              changed = false;          // if any of the history values for this sensor are unchanged, ignore them all
              break;
            }
          }
          // if all the history values for this sensor have changed, then update its state
          if (changed)
          {
            sensorState[i] = sensorHistory[0][i];
            println("sensor " + i + " is now " + (sensorState[i]?"On":"Off"));
            // if sensor is now On (item in position), then append to playList
            if (sensorState[i])
            {
              if (i != playList[0])                   // if this film is not the one playing
              {
                if (stopPlayIfOtherSensorPlaced)      // if sensor placement interrupts current film
                {
                  println("Film " + i + " interrupted");
                  stopPlaying();                      // then stop current film
                  removeFromPlayListAtIndex(0);       // and remove it from the playList
                }
                appendToPlayList(i);                  // append film for new item to playList
              }
            }
            else    // sensor is now Off (item removed from display)
            {
              if (!playToCompletion)                  // if item removal causes film to stop playing
              {
                println("Film " + i + " stopped");
                if (i == playList[0])                 // if this film is the one playing
                  stopPlaying();                      // then stop film playing 
                removeFromPlayList(i);                // remove this item from the playList
              }
            }
          }
        }
      }
    }
  }
}

// stop playing the current film
void stopPlaying()
{
  println("Stopped playing");
  playing = false;
  if (playList[0] >= 0)
    m[playList[0]].stop();
  clear();
}

// add specified film number to playList, having checked it's not already present
//  (where filmNum is index into sensorFilm)
void appendToPlayList(int filmNum)
{
  int i;
  for (i = 0; i < playList.length && playList[i] >= 0; i++)
    if (playList[i] == filmNum)
    {
      println("film already in playlist");
      return;    // this film is already in the playlist, so don't add it again
    }
  if (i >= playList.length)
  {
    println("film not added as playList is full");
    return;      // the playList is full and has no room for this film
  }
  if (playList[i] < 0)  // if we're at the end of the playList, append this film
  {
    println("film added to playlist position " + i);
    playList[i] = filmNum;
  }
  print("playlist: ");
  for (i = 0; i < playList.length; i++)
  {
    print(playList[i]); print(" ");
  }
  println("");
}

// remove specified film number from playList (where filmNum is index into sensorFilm)
void removeFromPlayList(int filmNum)
{
  int i;
  boolean found = false;
  for (i = 0; i < playList.length; i++)
    if (playList[i] == filmNum)
    {
      found = true;
      break;
    }
  if (found)
    removeFromPlayListAtIndex(i);
}

// remove film from specified position in playList 
void removeFromPlayListAtIndex(int index)
{
  println("removing film from playlist position " + index);
  for (int j = index; j < playList.length - 1 && playList[j] >= 0; j++)
    playList[j] = playList[j+1];
  playList[playList.length - 1] = -1;
  print("playlist: ");
  for (int i = 0; i < playList.length; i++)
  {
    print(playList[i]); print(" ");
  }
  println("");
  if (playList[0] < 0)
    playing = false;
}

float round2(float number, int scale)
{
  int pow = 10;
  for (int i = 1; i < scale; i++)
    pow *= 10;
  float tmp = number * pow;
  return ((float)((int)((tmp - (int)tmp) >= 0.5f ? tmp + 1 : tmp))) / pow;
}