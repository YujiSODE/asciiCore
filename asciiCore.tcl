#asciiCore
#asciiCore.tcl
##===================================================================
#	Copyright (c) 2018 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
##===================================================================
#Particle simulation in ascii art.
#=== Synopsis ===
#namespace `::asciiCore`
#
#=== Description ===
#It generates map list and displays this list.
##===================================================================
set auto_noexec 1;
package require Tcl 8.6;
#*** <namespace ::tcl::mathfunc> ***
#=== lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0 ===
#Additional mathematical functions for Tcl expressions that returns sum of given list
proc ::tcl::mathfunc::lSum {list} {namespace path {::tcl::mathop};set S 0.0;set R 0.0;set T 0.0;foreach e $list {set R [+ $R [expr double($e)]];set T $S;set S [+ $S $R];set T [+ $S [expr {-$T}]];set R [+ $R [expr {-$T}]];};return $S;};
#*** <namespace ::asciiCore> ***
namespace eval ::asciiCore {
	#### Variables ####
	#=== map list ===
	variable map {};
	#idMap is array of id lists in a particular coordinate cell
	variable idMap;array set idMap {};
	#e.g., map coordinates (n x m)
		#\0123...n
		#0____..._
		#1____..._
		#:____..._
		#m____..._
	#mW and mH are initial width and height of the map
	#default map size=10x10
	variable mW 10;
	variable mH 10;
	#initial unit scales for map
	variable dW 1.0;
	variable dH 1.0;
	#initial value for diameter
	variable D [expr {min($dW,$dH)}];
	#initial values for map
	set i 0;
	while {$i<$mH} {
		lappend map "_[string repeat "\x20_" [expr {$mW-1}]]";
		incr i 1;
	};
	#log
	variable LOG {};
	variable nStep 0;
	#=== array parameters for objects ===
	#-------------------------------------+
	#parameter format:`value(object_id)=v`|
	#-------------------------------------+
	#objects and their mass
	variable Char;array set Char {};
	variable M;array set M {};
	#positions
	variable X;array set X {};
	variable Y;array set Y {};
	#velocities
	variable vX;array set vX {};
	variable vY;array set vY {};
	#accelerations
	variable aX;array set aX {};
	variable aY;array set aY {};
	#### Procedures ####
	#it clears map
	proc clear {} {
		variable map {};variable idMap;variable mW;variable mH;
		set i 0;
		foreach e [array names idMap] {
			array unset idMap $e;
		};
		#new values for $map
		while {$i<$mH} {
			lappend map "_[string repeat "\x20_" [expr {$mW-1}]]";
			incr i 1;
		};
	};
	#it returns the current map
	proc getMap {} {
		variable map;
		return [join [lmap e $map {list [join $e {}];}] \n];
	};
	#it returns horizontal coordinate
	proc xCoord {x} {
		variable dW;
		return [expr {wide(floor($x/$dW))}];
	};
	#it returns vertical coordinate
	proc yCoord {y} {
		variable dH;
		return [expr {wide(floor($y/$dH))}];
	};
	#it plots an object on map
	proc plot {id} {
		# - $id: object id
		variable map;variable idMap;variable mW;variable mH;variable Char;variable X;variable Y;
		#map coordinates
		set x [::asciiCore::xCoord $X($id)];
		set y [::asciiCore::yCoord $Y($id)];
		expr {!($x<0)&&!($x>$mW-1)&&!($y<0)&&!($y>$mH-1)?[lappend idMap($x,$y) $id]:0};
		return [expr {!($x<0)&&!($x>$mW-1)&&!($y<0)&&!($y>$mH-1)?[lset map "$y $x" $Char($id)]:$map}];
	};
	#it defines an object and returns its id
	proc setObject {char m {xy0 {0.0 0.0}} {v0 {0.0 0.0}} {a0 {0.0 0.0}}} {
		# - $char: an object character
		# - $m: object mass
		# - $xy0: a list of initial object position with format of `{x y}`
		# - $v0: a list of initial object velocities with format of `{vx vy}`
		# - $a0: a list of initial object accelerations with format of `{ax ay}`
		variable Char;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;
		#ID is an object id
		set ID [format %x [expr {round(rand()*10**10)}]];
		#=== array parameters for objects ===
		#------ objects and their mass ------
		array set Char "$ID $char";
		array set M "$ID [expr {double($m)}]";
		#------ position ------
		array set X "$ID [expr {double([lindex $xy0 0])}]";
		array set Y "$ID [expr {double([lindex $xy0 1])}]";
		#------ velocities and accelerations ------
		array set vX "$ID [expr {double([lindex $v0 0])}]";
		array set vY "$ID [expr {double([lindex $v0 1])}]";
		array set aX "$ID [expr {double([lindex $a0 0])}]";
		array set aY "$ID [expr {double([lindex $a0 1])}]";
		#=== initial plot of the object ===
		::asciiCore::plot $ID;
		return $ID;
	};
	#it removes objects with given id list
	#all objects are removed if id list is omitted
	proc remove {{idList {}}} {
		# - $idList: a list of object id
		variable Char;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;
		set idList [expr {![llength $idList]?[array names Char]:$idList}];
		foreach e $idList {
			array unset Char $e;
			array unset M $e;
			array unset X $e;
			array unset Y $e;
			array unset vX $e;
			array unset vY $e;
			array unset aX $e;
			array unset aY $e;
		};
	};
	#it calculates next step
	proc step {} {
		variable Char;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable D;
		foreach e [array names Char] {
			set vX($e) [expr {lSum("$vX($e) $aX($e)")}];
			set vY($e) [expr {lSum("$vY($e) $aY($e)")}];
			set X($e) [expr {lSum("$X($e) $vX($e)")}];
			set Y($e) [expr {lSum("$Y($e) $vY($e)")}];
			::asciiCore::plot $e;
		};
	};
	#it resizes map size
	proc resize {w h} {
		# - $w and $h are new width and height for the map
		variable map {};variable mW;variable mH;variable Char;variable X;variable Y;
		set re {^[1-9][0-9]*$};
		set i 0;
		set mW [expr {[regexp $re $w]?$w:$mW}];
		set mH [expr {[regexp $re $h]?$h:$mH}];
		#clearing map
		::asciiCore::clear;
		#replot objects on map
		foreach e [array names Char] {
			::asciiCore::plot $e;
		};
		return "$mW $mH";
	};
	#it sets new unit scales for map
	proc setScales {dw dh} {
		# - $dw and $dh: positive numbers for map scales
		variable dW;variable dH;variable Char;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable D;
		set dW [expr {double($dw>0?$dw:$dW)}];
		set dH [expr {double($dh>0?$dh:$dH)}];
		#new value for diameter
		set D [expr {min($dW,$dH)}];
		#clearing map
		::asciiCore::clear;
		#replot objects on map
		foreach e [array names Char] {
			::asciiCore::plot $e;
		};
		return "$dW $dH";
	};
	#it resets size and scales for map, and removes all objects
	proc reset {} {
		variable LOG {};variable nStep 0;
		::asciiCore::remove;
		::asciiCore::resize 10 10;
		::asciiCore::setScales 1.0 1.0;
		::asciiCore::clear;
	};
};
################
# a test code
proc ::asciiCore::show {{n 10} {delay 250}} {
	# - $n: model simulated for n-1 time steps, i.e., 0th step is the initial step
	# - $delay: delay in milliseconds with default value of 250
	variable LOG;variable nStep;
	set i 0;
	set n [expr {$n>0?$n:10}];
	#Clearing display
	puts stdout "\u1b\[2J";
	while {$i<$n} {
		expr {$i!=0?[::asciiCore::clear]:0};
		expr {$i!=0?[::asciiCore::step]:0};
		lappend LOG [::asciiCore::getMap];
		puts -nonewline stderr "\u1b\[1;1H[lindex $LOG $nStep]";
		after $delay;
		incr i 1;
		incr nStep 1;
	};
	puts stdout "\n\#===================================================================";
	####################
	variable dW;variable dH;variable D;
	puts stdout "(dW,dH)=($dW,$dH)\nD=$D\nsteps: [expr {$nStep-1}]";
	####################
};
#it shows simulation result
proc ::asciiCore::preview {{delay 250}} {
	# - $delay: delay in milliseconds with default value of 250
	variable LOG;
	set n [llength $LOG];
	#Clearing display
	puts stdout "\u1b\[2J";
	foreach e $LOG {
		puts -nonewline stderr "\u1b\[1;1H$e";
		after $delay;
	};
	puts stdout "\n\#===================================================================";
	puts stdout "steps: [expr {$n-1}]";
	variable idMap;
	parray idMap;
};
#it outputs JavaScript code as js file
proc ::asciiCore::output_JS {{filename {}} {delay 250}} {
	variable LOG;
	set filename [expr {[llength $filename]>0?"$filename.js":"asciiCore[clock seconds].js"}];
	set logJS [lmap e $LOG {list "\`$e\`";}]
	set logJS "\[[join $logJS ,]\]";
	############
	puts stdout $logJS;
	puts stdout $filename;
	############
	return $filename;
};
#*** License ***
#MIT License
#
#Copyright (c) 2018 Yuji Sode
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
