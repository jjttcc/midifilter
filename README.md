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

## Current Features

The following events can be triggered and sent to the configured MIDI clients
(when appropriate):

* program-change - From note event where patch number is determined by the
  pitch value.
* bank-select
* transpositions - Transpose pitches within a certain configured range up or
  down by a specified number of half steps.
* Trigger external commands.
* Send real-time START, STOP, and CONTINUE messages.
* Trigger a mode (which I call "program-change sample mode") in which
  midifilter cycles through the entire range of patches, with a pause in
  between each patch.  In other words, it sends patch 0, pauses for a
  configured number of seconds, sends patch 1, etc., until it has reached
  patch 127.  This allows the user to try out - "sample" - each patch of
  the current bank without having to explicitly invoke a program change.

License:  GNU GPL, verson 2
===============

Copyright 2013  Jim Cochrane - GNU GPL, verson 2 (See the LICENSE file
for the details.)

Dependencies
===============

    Filter::Macro
    MIDI::ALSA
    Mouse
    Music::Note
    threads
    espeak (used in default configuration)

Platforms
===============

ALSA (as far as I know) is only available on Linux.  Therefore, the
ALSA MIDI Filter only runs on Linux systems

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

    override_cc_control_number: 7
    program_change_high: 108
    program_change_low: 107

With an 88-key keyboard, sending a channel volume - decimal value 7 - event
(e.g., by pressing down the "volume" pedal) and then hitting the top C on
the keyboard twice will cause a program change event for patch 127 to be
sent to the configured MIDI output clients, while a channel volume event
followed by hitting the top B (MIDI value 107) and then the top C (108) will
cause a program change for patch 87 to be sent. What happens in this
scenario is that the channel volume event puts midifilter into "override"
mode, the top C (or B) puts it into program-change mode, and the next pitch
tells midifilter which patch to send to the connected MIDI clients. The
program\_change\_high setting adjusts the value of the patch sent such that
the highest note on the keyboard triggers the highest possible patch value
(thus sending 127); and the program\_change\_low setting adjusts the patch
value so that the lowest note on the keyboard triggers the lowest possible
patch value. Thus, channel-volume, B7 (107), and then A0 (21), will trigger
a program change to patch 0. (The purpose of these upward or downward
adjustments is, of course, to make the entire range of patch values of 0..127
available, since MIDI keyboards generally do not have more than 88 keys.)

## Configuration Tags

Following is a list of configuration tags that midifilter recognizes when
it finds them in the specified configuration file, with an accompanying
description of what each tag does.

* from - Specifies a port from which MIDI events will be input: name and
  sub-port number. Case does not matter. (E.g., 'from: mia, 0')
* to - Specifies a port to which MIDI events will be sent: name and sub-port
  number. Case does not matter. (E.g., 'to: rosegarden, 0')
* program\_change\_high - Specifies which MIDI-note pitch will - when in
  "override" mode - trigger a switch to program-change mode such that the next
  MIDI note event (whose patch number [0 .. 127] is derived from the pitch
  value, adjusted upward) will cause a program-change to be sent.
* program\_change\_low - Specifies which MIDI-note pitch will - when in
  "override" mode - trigger a switch to program-change mode such that the next
  MIDI note event (whose patch number [0 .. 127] is derived from the pitch
  value, adjusted downward) will cause a program-change to be sent.
* bank\_select\_up - Specifies which MIDI-note pitch will (when in "override"
  mode) trigger a bank-select MIDI event to be sent to change to the
  next "higher" bank, compared to the current bank (based on MSB/LSB values).
* bank\_select\_down - Specifies (when in "override" mode) which MIDI-note
  pitch will trigger a bank-select MIDI event to be sent to change to the
  previous (lower) bank, compared to the current bank (based on MSB/LSB
  values).
* external\_cmd - Specifies a pitch with which an external command is to be
  triggered (when in "override" mode), along with the command to execute.
* real\_time\_start - Specifies that a MIDI real-time START message be sent to
  the configured MIDI output clients.
* real\_time\_stop - Specifies that a MIDI real-time STOP message be sent to
  the configured MIDI output clients.
* real\_time\_continue - Specifies that a MIDI real-time CONTINUE message be
  sent to the configured MIDI output clients.
* override\_cc\_control\_number - Specifies the 2nd-byte value (decimal) of a
  control-change message type that will trigger "override" mode.  For example,
  7 would indicate that channel volume messages are to trigger "override"
  mode.  (See http://www.midi.org/techspecs/midimessages.php for details,
  including control-change types, of MIDI messages according to the MIDI
  standard.)
* bottom\_note - Specifies the MIDI value of the lowest pitch on the MIDI
  keyboard or device being used for input.
* top\_note - Specifies the MIDI value of the highest pitch on the MIDI
  keyboard or device being used for input.
* program\_change\_sample - Specifies the MIDI pitch value that (when in
  "override" mode) triggers the "program-change sample" mode.
* cancel\_program\_change\_sample - Specifies the MIDI pitch value that (when
  in "override" mode) cancels "program-change sample" mode.
* program\_change\_sample\_seconds - Specifies the number of seconds to wait,
  when in program-change sample mode, before issuing the next program-change
  message.
* stop\_program\_change\_sample - Specifies the MIDI pitch value that (when
  in "override" mode) stops "program-change sample" mode.
* continue\_program\_change\_sample - Specifies the MIDI pitch value that
  (when in "override" mode), if program-change sampe mode has been stopped,
  resumes - restarts it.
* transpose\_spec - Specification of a transposition.  See documentation below
  for more details.
* announcer - Specifies the program to use for "announcements."

Feedback
===============

I think I am reasonably competent at writing documentation, but far from
perfect.  If you find a flaw in this documentation, or in the software, for
that matter, that you think needs correcting, feel free to send me a message
about the issue via github.
