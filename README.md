# KeyboardSteer for Farming Simulator 2019

## Status
I tried to publish version 0.0.3.1 on Modhub but I got it back for review. The automatic camera reversal if one switches the driving direction seems to be too disturbing. I guess the only consequence would be to split this mod into the old keyboard steer functions and a new gearbox. This means even more work and even elss motivation. I do not know how to continue.

## Motivation
Although I have a steering wheel, but almost always play with the keyboard. On winding roads, I am again and again landed in the ditch in front of nights or power poles.

## Description
This script varies the steering speed depending on the speed you are driving, and it rotates the camera to match the steering angle and direction.
Shift-Left limits throttle, cruise control and maximum rounds per minute to 75%. With Shift-right and the cursor keys you can peek in the corresponding direction.
If you press Ctrl left together with W then the driving direction snaps to fixed directions.

All functions are switchable with the following default key combinations:
* Ctrl Left + C: Settings
* Ctrl Left + W: Snap Angle
* Shift Left: Throttle limiter / reduced cruise control speed
* Shift Right + Cursor: look forward, backwards, left right
* Space: Change direction (aka shuttle control)
* Please check the keys for shifting. G27/G29 gear shifters are supported.
* The 7th gear of the gear shifter is special. If you use action binding ksmShifter7 please make sure that shuttle control is enabled. This action binding will swtich into 1st reverse gear. 
* In case of a 4x4 transmission the gears 5 and 6 are used to shift the range down or up. Best transmission in combination with a gear shifter is maybe the FPS. The shifter operates on gears 7 to 12. The reverse gear is 6th.

## Developer version
Please be aware you're using a developer version, which may and will contain errors, bugs, mistakes and unfinished code. 

You have been warned.

If you're still ok with this, please remember to post possible issues that you find in the developer version. 
That's the only way we can find sources of error and fix them. 
Be as specific as possible:

* tell us the version number
* only use the vehicles necessary, not 10 other ones at a time
* which vehicles are involved, what is the intended action?
* Post! The! Log! to [Gist](https://gist.github.com/) or [PasteBin](http://pastebin.com/)

## Credits
* Stefan Biedenstein
