declare name        "st_encoder";
declare version     "1.1";
declare author      "Pierre Lecomte";
declare license     "CC-BY-NC-SA-4.0";
declare copyright   "(c) Pierre Lecomte";
declare options "[osc:on]";

// Changelog
// (2022-09) v1.1
// - Doppler effect
// - No more clicks when moving sources

//###Stereo Encoder###
// This tool encodes a stereo source in an Ambisonic sound scene up to a maximal degree $L$.
// See the [encoder]({% link docs/encoder.md %}) tool for details on point source and plane wave encoding details. 
// The left and right channels are positionned in space on a sphere of radius $r$ as shown on
// <div style="width:75%; margin:0 auto;" align="center" markdown="1">
// {% figure caption: "Position of the left (blue dot) and right (red dot) channels on a sphere of radius $r$. 
// The angle between the two paths is $\alpha$ (in purple) and the rotation angle around the vector $\vec{u}_r$ is the angle $\beta$ (in green). 
// In the configuration shown, $(r = 1~\text{m}, \theta = 60^\circ, \phi = 50^\circ), \alpha = 60^\circ$ and $\beta = 45^\circ$." label:stereo_spat%}
// ![Image]({{site.baseurl}}/assets/docs/stereo_spat.png){:.rounded.border.shadow}
// {%endfigure%}
// </div>
// in Fig.{% figref stereo_spat %}. The user chooses a position $(r, \theta, \phi)$ (the black dot in Fig.{% figref stereo_spat %}). 
// The width of the stereo source is then set with the angle $\alpha$ (in purple on Fig.{% figref stereo_spat %}). 
// This is the angle between the two directions of the left channel (blue dot in Fig.{% figref stereo_spat %}) and the right channel (red dot in Fig.{% figref stereo_spat %}), symmetrically distributed with respect to the direction $(\theta, \phi)$. 
// Thus, the left channel is at an angle of $\alpha/2$ with respect to the direction of the black point, as is the right channel. 
// Finally the roll angle, noted $\beta$, (in green in the Fig.{%figref stereo_spat %} allows to turn the stereo source around the vector $\vec{u}_r$.
// For a source width $\alpha = 0^\circ$ or $\alpha = 360^\circ$ the left and right channels are superimposed and the angle $\beta$ has no influence.
//
// ## Compilation parameters
// - `L`: maximal Spherical Harmonics degree (i.e., Ambisonics order), $L > 0$,
// - `doppler` : Possibility of Doppler effect : `0` => No, `1` => Yes.
//
// ## Inputs / Outputs
// - Inputs: $2$
// - Outputs: $(L+1)^2$
//
// ## User Interface
// For the $i$-th source:
//
// |             Element         |     OSC        | Min value | Max value |
// |:---------------------------:|:--------------:|:---------:|:---------:|
// |          Gain (dB)          |   `gain`       |    -20    |    20     |
// |   Doppler (`doppler = 1`)   |   `doppler_i`  |      0    |     1     |
// |        Radius $r$ (m)       |  `radius`      |    0.75   |    50     |
// | Azimuth $\theta$ ($^\circ$) | `azimuth`      |    -180   |    180    |
// | Elevation $\phi$ ($^\circ$) |  `elevation`   |    -90    |    90     |
// | Width $\alpha$ ($^\circ$)   |  `width`       |    0      |    360    |
// | Roll  $\beta$  ($^\circ$)   |  `roll`        |    -180   |    180    |
// |           Doppler           |   `doppler`    |      0    |     1     |
//
//
//######

import("stdfaust.lib");
import("ylm.lib");
import("radial.lib");
import("grids.lib");


// COMPILATION PARAMETERS
L = 3; // maximal SH degree
doppler = 0; // Activate the possibility of Doppler effect : 0 => No, 1 => Yes

// DO NOT EDIT BELOW HERE
rspk = 1; // speaker radius (for near-field filters stabilization)
rmin = 0.75;
rmax = 50;

// User interface
g       =   hslider("[1][unit:dB][osc:/gain -20 20][style:knob]Gain",0,-20,20,0.1): ba.db2linear; // gain
r       =   hslider("[2][unit:m][osc:/radius %rmin %rmax][style:knob]Radius", 1, rmin, rmax, 0.01) : si.smoo ;// radius
t       =	hslider("[3][unit:°][osc:/azimuth -180 180][style:knob]Azimuth", 0, -180, 180, 0.01) * ma.PI/180; // azimuth
p       =	hslider("[4][unit:°][osc:/elevation -90 90][style:knob]Elevation", 0, -90, 90, 0.01) * ma.PI/180 : si.smoo; // elevation
width   =   hslider("[5][unit:°][osc:/width 0 360][style:knob]Width", 60, 0, 360, 0.01) * ma.PI/180; // width
roll    =   hslider("[6][unit:°][osc:/roll -180 180][style:knob]Roll", 0, -180, 180, 0.01) * ma.PI/180; // roll
d       =   checkbox("[7][osc:/doppler 0 1]Doppler"); // Doppler effect


// https://en.wikipedia.org/wiki/Spherical_coordinate_system#Integration_and_differentiation_in_spherical_coordinates

// Left-Right channels Cartesian coordinates in basis $(u_r, u_\theta, u_\phi)$
l1 = (r * cos(width / 2), 0, r * cos(width / 2) * tan(width / 2)); // Left-channel
r1 = (r * cos(width / 2), 0, -r * cos(width / 2) * tan(width / 2)); // Right-channel

// Transition matrix between from basis $(u_r, u_\theta, u_\phi)$ to basis $(x, y, z)$.
m(0) = (cos(t) * cos(p), cos(t) * sin(p), -1 * sin(t));
m(1) = (cos(p) * sin(t), sin(t) * sin(p), cos(t));
m(2) = (sin(p), -1 * cos(p), 0);

// Rotation matrix around vector $u_r$ in basis $(u_r, u_\theta, u_\phi)$
rot(0) = (1, 0, 0);
rot(1) = (0, cos(roll), -1 * sin(roll));
rot(2) = (0, sin(roll), cos(roll));

// It should be possible to combine the two above matrices. However, it is left as it is for readibility: the simplifications are left to the compiler.. :)

// Left-Right channels Cartesian coordinates in basis $(u_r, u_\theta, u_\phi)$ rotated of a angle roll around $u_r$.
l2 = l1 <: par(i, 3, buswg(rot(i)) :>_);
r2 = r1 <: par(i, 3, buswg(rot(i)) :>_);

// Left-Right final channels Cartesian coordinates in basis $(x, y, z)$.
l3  = l2 <: par(i, 3, buswg(m(i)) :>_);
r3  = r2 <: par(i, 3, buswg(m(i)) :>_);

// Left-Right channels in Spherical coordinates
tl3 = ba.take(2, cart2spher(l3 : (_,!,!), l3 : (!,_,!), l3 : (!,!,_)));
pl3 = ba.take(3, cart2spher(l3 : (_,!,!), l3 : (!,_,!), l3 : (!,!,_)));
tr3 = ba.take(2, cart2spher(r3 : (_,!,!), r3 : (!,_,!), r3 : (!,!,_)));
pr3 = ba.take(3, cart2spher(r3 : (_,!,!), r3 : (!,_,!), r3 : (!,!,_)));

// Doppler delay or not
dd = case{
        (0) => _;
        (1) => ddelay(rmax, r * d);
        }(doppler);

source(0) =     hgroup("",dd *g<:par(l, L+1, nf(l,r,rspk)<:par(i,2*l+1,_)):>syvec((L+1)^2, tl3, pl3)); // left channel
source(1) =     hgroup("",dd *g<:par(l, L+1, nf(l,r,rspk)<:par(i,2*l+1,_)):>syvec((L+1)^2, tr3, pr3)); // right channel

process = par(i, 2, source(i)):>si.bus((L+1)^2);
