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
vmeterv(x,i) = x<:attach(x, envelop(x) : vbargraph("in%i[osc:/loudspeaker_%i -70 6][unit:dB]", -70, 6));
vmeterh(x,i) = x<:attach(x, envelop(x) : vbargraph("in%i[osc:/loudspeaker_%i -70 6][unit:dB]", -70, 6));
envelop = abs : max(ba.db2linear(-70)) : ba.linear2db : min(6)  : max ~ -(80.0/ma.SR);

// create the objects
// bformat input 16ch
in_meter(x) = hgroup("[x]%2x", vmeterv(_, x));
bformat = hgroup("[0]b-format inputs", par(i, N, in_meter(i+1)));

// stereo input w/ meters
//st = vgroup("[0]stereo encoder", par(i, 2, hgroup("%2i", vmeterh(_, i))) : component("stereo_encoder.dsp")[L=3;]);
// stereo input w/o meters
st = vgroup("[0]stereo encoder", component("stereo_encoder.dsp")[L=3;]);

// mono inputs (4)
mno_group(x) = hgroup("%2x", vmeterv(_, x) : component("encoder.dsp")[L=3; S=1; midi=32+x;]);
mno = hgroup("[1]mono encoders", par(i, 4, mno_group(i+1)));

// audio inputs 2+4 inputs
// encoders(m1,m2,m3,m4,sl,sr) = tgroup("[0]inputs", vgroup("[1]encoders", mno(m1,m2,m3,m4), st(sl,sr)));
encoders = tgroup("[0]inputs", bformat, vgroup("[1]encoders", mno, st));

// bypass = checkbox("bypass");
// bp = par(i, N+6, *(_));

// process = vgroup("all", encoders :> hgroup("[1]decoder", component("KMHLS_Dome_3h3p_N.dsp")));
process = vgroup("all", bformat : hgroup("[1]decoder", component("KMHLS_Dome_3h3p_N.dsp")) );

// a,b,c,d, e,f,g,h, i,j,k,l, m,n,o,p, q,r,s,t, u,v
