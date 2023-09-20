declare name        "dB Meter";
declare version     "1.0";
declare author      "Pierre Lecomte";
declare license     "CC-BY-NC-SA-4.0";
declare copyright   "(c) Pierre Lecomte";
declare options "[osc:on]";

//###dB Meter###
// This tool is a $N$-channel dB meter.
//
// Use the flag `-xmit 2` in the `faust2...` scripts to retrieve the dB values of the meter via OSC. See [here](https://faustdoc.grame.fr/manual/osc/#turning-transmission-on){:target="_blank"} for more details.
// {:.info}
//
// ## Compilation parameter
// - `N`: number of input channels
//
// ## Inputs / Outputs
// - Inputs: $N$
// - Outputs: $N$
//
// ## User Interface
// For the $n$-th channel, with $0 < n < N-1$:
//
// |             Element         |     OSC         | Min value | Max value |
// |:---------------------------:|:---------------:|:---------:|:---------:|
// |          Signal level (dB)  | `loudspeaker_i` |    -70    |     6     |
//
//
//######

import("stdfaust.lib");

// COMPILATION PARAMETERS
N = 6; // number of channel

// DO NOT EDIT BELOW HERE

// vmeter produces an osc alias and send the value of the bargraph on this alias when -xmit 2 is used at execution time
vmeter(x,i) = x<:attach(x, envelop(x) : vbargraph("[osc:/loudspeaker_%i -70 6][unit:dB]", -70, 6));
envelop = abs : max(ba.db2linear(-70)) : ba.linear2db : min(6)  : max ~ -(80.0/ma.SR);

process = hgroup("dB meters", par(i, N, vgroup("%2i", vmeter(_, i))));
