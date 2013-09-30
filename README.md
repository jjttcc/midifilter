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
