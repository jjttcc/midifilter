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

[To-be-completed]

Dependencies
===============

[To-be-listed]
