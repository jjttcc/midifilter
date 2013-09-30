ALSA MIDI Filter
===============

A MIDI filter that uses the ALSA MIDI libraries (via the MIDI::ALSA perl
module) to provide configurable filtering functionality

Synopsis
===============

    midifilter <configfile>

Description
===============

The midifilter script, with the help of supporting perl modules, runs as an
ALSA MIDI client that can receive input from a source (such as a MIDI
keyboard connected to the computer), perform various filtering and other
functionality based on the type and content of the MIDI input, and send the
result to one or more other MIDI clients.

The file config1 is an example configuration file that can be used as a
guide for developing one's preferred configuration.

See "Detailed Documentation," below, for some instructions on how to use this
application.

Dependencies
===============

Filter::Macro
MIDI::ALSA
Mouse
Music::Note
threads
espeak (in default configuration)

License:  GNU GPL, verson 2
===============

Copyright 2013  Jim Cochrane - GNU GPL, verson 2 (See the LICENSE file
for the details.)

Detailed Documentation
===============

## Introduction

This section is an attempt (limited by the volunteer/free-software nature of
the project) to document in some detail what features are available in ALSA
MIDI Filter and how to use them.  It's a work in progress with the goal of
reducing as much as possible the frustration users encounter when they suspect
they can do something with an application, but, after reading, googling, and
researching, they still have no idea how to do it.  I'd consider the evolution
of this section successful if in the near and far future (i.e., after October
1, 2013), users' frustration levels are reduced enough that most people are
reasonably happy with the software.

## General Concepts

The midifilter script reads a configuration file, whose name is supplied as an
argument on the command line, to determine what ALSA MIDI connections to
establish, what MIDI events to listen for, and what to do when any of these
events are received.  The main logic of midifilter is based on the idea that a
configured MIDI event type (a type of control-change event configured in the
config file with the 'override\_cc\_control\_number' tag) will trigger
"override" mode.  While the process is in that mode, the next MIDI note event
received will, if it is one of a set of configured values, trigger a
specific action or a further state change, depending on the nature of the
configured action.  Here's an example to try to make this rather vague
sounding explanation more concrete and helpful:  Let's say the config file
includes these settings:

override\_cc\_control\_number: 7   # channel volume
program\_change\_high: 108    # pitch to trigger prog change, adjusted upward
program\_change\_low: 107     # pitch to trigger prog change, adjusted downward

With an 88-key keyboard, sending a channel volume event (e.g., by pressing
down the "volume" pedal) and then hitting the top C on the keyboard twice
will cause a program change event for patch 127 to be sent to the configured
MIDI output clients, while a channel volume event followed by hitting the top
B (MIDI value 107) and then the top C (108) will cause a program change for
patch 87 to be sent.  What happens in this scenario is that the channel volume
event puts midifilter into "override" mode, the top C (or B) puts it into
program-change mode, and the next pitch tells midifilter which patch to send
to the connected MIDI clients.  The program\_change\_high setting adjusts the
value of the patch sent such that the highest note on the keyboard triggers
the highest possible patch value (thus sending 127); and the
program\_change\_low setting adjusts the patch value so that the lowest note
on the keyboard triggers the lowest possible patch value.  Thus,
channel-volume, B7 (107), and then A0 (21), will trigger a program change to
patch 0.
