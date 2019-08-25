# WindowKeeper

This software automates window repositioning when reconnecting to external monitors on macOS.

For instance, imagine that you are using your MacBook at home, with two external monitors. As a university student, you take the laptop with you in the morning. Then at school and during class breaks, you are working on your homework using your laptop. In the evening, when you come home and hook the laptop back to the two external monitors, your program windows get automatically repositioned the way you left them.

## Dependencies
* [Hammerspoon](http://www.hammerspoon.org)
* [hs._asm.undocumented.spaces](https://github.com/asmagill/hs._asm.undocumented.spaces)

## Requirements
* macOS

## Installation notes
* Install Hammerspoon by following its [installation notes](http://www.hammerspoon.org/go/)
* Install a Spaces API plugin, following its [installation notes](https://github.com/asmagill/hs._asm.undocumented.spaces#installation)
* Download this repository, and install the Spoon, as described [here](https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md#how-do-i-install-a-spoon)
* Add the content of `init.lua` file, found at the root of this repository, to your `~/.hammerspoon/.init.lua` file. If it does not exist, create it.
