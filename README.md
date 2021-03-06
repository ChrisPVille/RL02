﻿# RL02-USB Interface Project

## Overview

The aim of this project is to create an open-source interface between the DEC RL02 and a modern computer via USB.  

## Background

The RL02 hard drive was a mainstay of DEC's packaged computer systems in the late 1970s and 1980s.  Storing 10MB of data, these drives featured removable platters, 55ms average seek times, and ~250KBps effective linear throughput.  Combined with the modular design and longevity of the product line, there are still many functioning drives and many disk packs out there.

Of course, to interact with the data on these disk packs, a functioning drive is not enough.  Cables, interface cards, a DEC minicomputer, and software are all required, some of which has become very rare and prohibitively expensive when available.  The most cost-effective (and educational!) solution was to create a new interface connecting the drive directly to a [simulated minicomputer](http://simh.trailing-edge.com/) running on a PC.

In addition to the historical preservation aspects, people still operate vintage computers for fun and profit.  Setting up an operating system or transferring files can be an ordeal when they can only be moved via [Kermit](http://en.wikipedia.org/wiki/Kermit_%28protocol%29) or some other archaic medium.  This interface serves to obviate the need for such things by allowing the direct interface of the RL02 with a modern computer.

## The Interface

This interface uses an FPGA to do all drive-facing tasks such as MFM data decoding, clock recovery, drive state management, data buffering, etc.  The FPGA communicates with a microcontroller, exposing its data and a command interface over SPI.  That microcontroller serves as the USB mass storage/bulk transport device for the attached PC.

### FPGA

TODO: Expand

### Microcontroller

TODO: Expand

### PCB

TODO: Expand

## How to Update

```shell
echo TODO
```

## Building The Sources

TODO: Expand

(C) 2015 Christopher Parish

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.  This is subject to the
exceptions listed in the LICENSE_EXCEPTION file.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
