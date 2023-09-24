// -*- compile-command: "cd .. && make app src=src/main.dsp && cd -"; -*-

declare name	"ls_main";
declare version " 0.1 ";
declare author " Henrik Frisk " ;
declare license " BSD ";
declare copyright "(c) dinergy 2023 ";
declare options "[osc:on]";
//---------------`Name` --------------------------
//
// DSP template
//
// * parameters
//
//---------------------------------------------------

import("stdfaust.lib");

N = 16; // Input channels (16 for 3rd order)

// vmeter produces an osc alias and send the value of the
// bargraph on this alias when -xmit 2 is used at execution time
vmeter(x,i) = x<:attach(x, envelop(x) : vbargraph("[osc:/loudspeaker_%i -70 6][unit:dB]", -70, 6));
envelop = abs : max(ba.db2linear(-70)) : ba.linear2db : min(6)  : max ~ -(80.0/ma.SR);

// create the objects
// bformat input 16ch
in_meter(x) = hgroup("%x", vmeter(_, x));
bformat = hgroup("[0]b-format inputs", par(i, N, in_meter(i+1)));

// stereo input
st = hgroup("[0]stereo encoder", par(i, 2, vgroup("%2i", vmeter(_, i))) : component("stereo_encoder.dsp")[L=3;]);

// mono inputs (4)
mno = hgroup("[1]mono encoders", par(i, 4, vgroup("%2i", vmeter(_, i) : component("encoder.dsp")[L=3; S=1; midi=32+i;])));

// audio inputs 2+4 inputs
encoders = vgroup("[0]inputs", bformat, vgroup("[1]encoders", mno, st));

process = vgroup("all", encoders :> hgroup("[1]decoder", component("KMHLS_Dome_3h3p_N.dsp")));
