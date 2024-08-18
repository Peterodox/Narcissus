--[[
A derivative work of LibEasing

Original Lua implementations from 'EmmanuelOga'
https://github.com/EmmanuelOga/easing/

Adapted from
Tweener's easing functions (Penner's Easing Equations)
and http://code.google.com/p/tweener/ (jstweener javascript version)

Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local _, addon = ...
local EasingFunctions = {};
addon.EasingFunctions = EasingFunctions;


local sin = math.sin;
local cos = math.cos;
local pow = math.pow;
local pi = math.pi;

--t: total time elapsed
--b: beginning position
--e: ending position
--d: animation duration

function EasingFunctions.linear(t, b, e, d)
	return (e - b) * t / d + b
end

function EasingFunctions.outSine(t, b, e, d)
	return (e - b) * sin(t / d * (pi / 2)) + b
end

function EasingFunctions.inOutSine(t, b, e, d)
	return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
end

function EasingFunctions.outQuart(t, b, e, d)
    t = t / d - 1;
    return (b - e) * (pow(t, 4) - 1) + b
end

function EasingFunctions.outQuint(t, b, e, d)
    t = t / d
    return (b - e)* (pow(1 - t, 5) - 1) + b
end

function EasingFunctions.inQuad(t, b, e, d)
    t = t / d
    return (e - b) * pow(t, 2) + b
end