# Flood-Resilient-Home

Automates play of information film-clip for flood resilient home display.
Can be used in two ways:
 1. film clip plays when user places item in specific place on display
 2. film clip plays when user presses a button to find out about that item.
In the former case, the system can be configured to play each clip to completion, 
or to stop the clip when the item is removed from the display.
In the latter case, the system can play the film clip to completion regardless 
of whether the button continues to be pressed.
There is also a choice of whether to change film clip immediately when a 
different button is pressed or a different item is placed. 

Arduino handles the sensor/switch input and sends a comma-separated sequence 
on the serial port.  Each item (0-15) is 0 (not pressed/placed) or 1.
Processing3 tracks the serial input and queues film clips in response to 
placements/switches pressed.
