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
#asciiCore_reference.txt
#
#=== [Reference] ===
# - Tanaka, K. 2017. JavaScript game programming. Future Coders, Impress R&D
#   ISBN: 978-4-8443-9755-7
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
	#=== initial value for diameter ===
	variable D [expr {min($dW,$dH)}];
	#initial values for map
	set i 0;
	while {$i<$mH} {
		lappend map "_[string repeat "\x20_" [expr {$mW-1}]]";
		incr i 1;
	};
	#=== log ===
	variable LOG {};
	variable nStep 0;
	#=== epsilon ===
	variable epsilon 1.0;
	while {1.0+$epsilon!=1.0} {
		set epsilon [expr {$epsilon/2}];
	};
	#=== environmental accelerations ===
	variable EnvX;array set EnvX {};
	variable EnvY;array set EnvY {};
	#-------------------------------------------------------------------
	#=== variables used for collision ===
	variable nextVx1 0.0;
	variable nextVy1 0.0;
	variable nextVx2 0.0;
	variable nextVy2 0.0;
	#-------------------------------------------------------------------
	#=== array parameters for objects ===
	#-------------------------------------+
	#parameter format:`value(object_id)=v`|
	#-------------------------------------+
	#objects and their density and mass
	variable Char;array set Char {};
	variable Rho;array set Rho {};
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
	#coefficient of restitution
	variable CR;array set CR {};
	#isolation
	variable Isolation;array set Isolation {};
	#### Procedures ####
	#-------------------------------------------------------------------
	#=== lPairwise.tcl (Yuji SODE, 2018); the MIT License: https://gist.github.com/YujiSODE/0d520f3e178894cd1f2fee407bbd3e16 ===
	#It returns pairwise combination of given list
	proc lPairwise {list} {set n [llength $list];set i 1;set LIST {};while {$n>1} {set i 1;while {$i<$n} {lappend LIST [list [lindex $list 0] [lindex $list $i]];incr i 1;};set list [lrange $list 1 end];set n [llength $list];};return $LIST;};
	#-------------------------------------------------------------------
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
		set x [expr {double($x)}];
		return [expr {wide(floor($x/$dW))}];
	};
	#it returns vertical coordinate
	proc yCoord {y} {
		variable dH;
		set y [expr {double($y)}];
		return [expr {wide(floor($y/$dH))}];
	};
	#it plots an object on map
	proc plot {id} {
		# - $id: object ID
		variable map;variable idMap;variable mW;variable mH;variable Char;variable X;variable Y;
		#map coordinates
		set x [::asciiCore::xCoord $X($id)];
		set y [::asciiCore::yCoord $Y($id)];
		expr {!($x<0)&&!($x>$mW-1)&&!($y<0)&&!($y>$mH-1)?[lappend idMap($x,$y) $id]:0};
		return [expr {!($x<0)&&!($x>$mW-1)&&!($y<0)&&!($y>$mH-1)?[lset map "$y $x" $Char($id)]:$map}];
	};
	#it set an environmental acceleration in the horizontal direction
	proc setEnvX {name value} {
		variable EnvX;
		set value [expr {double($value)}];
		array set EnvX "$name $value";
		return "$name $value";
	};
	#it set an environmental acceleration in the vertical direction
	proc setEnvY {name value} {
		variable EnvY;
		set value [expr {double($value)}];
		array set EnvY "$name $value";
		return "$name $value";
	};
	#it returns total of environmental acceleration in the horizontal direction
	proc getEnvX {} {
		variable EnvX;
		set E [array names EnvX];
		return [expr {[llength $E]>0?lSum([lmap e $E {list $EnvX($e);}]):0.0}];
	};
	#it returns total of environmental acceleration in the vertical direction
	proc getEnvY {} {
		variable EnvY;
		set E [array names EnvY];
		return [expr {[llength $E]>0?lSum([lmap e $E {list $EnvY($e);}]):0.0}];
	};
	#it defines an object and returns its ID
	proc setObject {char rho {xy0 {0.0 0.0}} {v0 {0.0 0.0}} {a0 {0.0 0.0}} {cr 1.0}} {
		# - $char: an object character
		# - $rho: object density
		# - $xy0: a list of initial object position with format of `{x y}`
		# - $v0: a list of initial object velocities with format of `{vx vy}`
		# - $a0: a list of initial object accelerations with format of `{ax ay}`
		# - $cr: coefficient of restitution
		variable Char;variable Rho;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable CR;variable Isolation;variable dW;variable dH;
		#ID is an object id
		set ID [format %x [expr {round(rand()*10**10)}]];
		#V is approximated object volume
		set V [expr {double($dW*$dH)}];
		#=== array parameters for objects ===
		#------ objects and their density and mass ------
		array set Char "$ID $char";
		array set Rho "$ID [expr {double($rho)}]";
		array set M "$ID [expr {double($Rho($ID)*$V)}]";
		#------ position ------
		array set X "$ID [expr {double([lindex $xy0 0])}]";
		array set Y "$ID [expr {double([lindex $xy0 1])}]";
		#------ velocities and accelerations ------
		array set vX "$ID [expr {double([lindex $v0 0])}]";
		array set vY "$ID [expr {double([lindex $v0 1])}]";
		array set aX "$ID [expr {double([lindex $a0 0])}]";
		array set aY "$ID [expr {double([lindex $a0 1])}]";
		#------ coefficient of restitution ------
		array set CR "$ID [expr {double($cr)}]";
		#------ isolation ------
		array set Isolation "$ID [expr {!1}]";
		#=== initial plot of the object ===
		::asciiCore::plot $ID;
		return $ID;
	};
	#it makes given object isolated
	proc setIsolated {id} {
		# - $id: object ID
		variable Isolation;
		array set Isolation "$id [expr {!0}]";
	};
	#it makes given object non-isolated
	proc unsetIsolated {id} {
		# - $id: object ID
		variable Isolation;
		array set Isolation "$id [expr {!1}]";
	};
	#it removes objects with given ID list
	#all objects are removed if ID list is omitted
	proc remove {{idList {}}} {
		# - $idList: a list of object ID
		variable Char;variable Rho;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable CR;variable Isolation;
		set idList [expr {![llength $idList]?[array names Char]:$idList}];
		foreach e $idList {
			array unset Char $e;
			array unset M $e;
			array unset Rho $e;
			array unset X $e;
			array unset Y $e;
			array unset vX $e;
			array unset vY $e;
			array unset aX $e;
			array unset aY $e;
			array unset CR $e;
			array unset Isolation $e;
		};
	};
	#it returns if there is collision
	#returned value is true when there is collision
	proc ifCollision {id1 id2} {
		# - $id1 and $id2: object IDs
		variable X;variable Y;variable D;
		set x1 $X($id1);set x2 $X($id2);
		set y1 $Y($id1);set y2 $Y($id2);
		set d [expr {lSum("$x1**2 $x2**2 $y1**2 $y2**2 -2*$x1*$x2 -2*$y1*$y2")}];
		return [expr {!(($d-$D**2)>0)}];
	};
	#it estimates velocity vectors after collision
	proc getCollision {id1 id2} {
		# - $id1 and $id2: object IDs
		variable M;variable X;variable Y;variable vX;variable vY;variable CR;variable D;variable epsilon;variable nextVx1;variable nextVy1;variable nextVx2;variable nextVy2;
		set x1 $X($id1);set x2 $X($id2);
		set y1 $Y($id1);set y2 $Y($id2);
		set vx1 $vX($id1);set vx2 $vX($id2);
		set vy1 $vY($id1);set vy2 $vY($id2);
		#mass
		set m1 $M($id1);set m2 $M($id2);
		#coefficient of restitution
		set cr [expr {lSum("$CR($id1) $CR($id2)")/2}];
		#distance
		set d [expr {lSum("$x1**2 $x2**2 $y1**2 $y2**2 -2*$x1*$x2 -2*$y1*$y2")}];
		set d [expr {$d!=0.0?$d:$epsilon}];
		#-------------------------------------------------------------------
		#=== unit normal vectors ===
		set normalX1 [expr {lSum("$x2 -$x1")/$d}];
		set normalY1 [expr {lSum("$y2 -$y1")/$d}];
		set normalX2 [expr {lSum("$x1 -$x2")/$d}];
		set normalY2 [expr {lSum("$y1 -$y2")/$d}];
		#=== unit tangent vectors ===
		set tangentX1 $normalY1;
		set tangentY1 [expr {-$normalX1}];
		set tangentX2 $normalY2;
		set tangentY2 [expr {-$normalX2}];
		#=== inner products ===
		#--- unit normal vectors and velocities ---
		set dotNorm1 [expr {lSum("$normalX1*$vx1 $normalY1*$vy1")}];
		set dotNorm2 [expr {lSum("$normalX2*$vx2 $normalY2*$vy2")}];
		#--- unit tangent vectors and velocities ---
		set dotTan1 [expr {lSum("$tangentX1*$vx1 $tangentY1*$vy1")}];
		set dotTan2 [expr {lSum("$tangentX2*$vx2 $tangentY2*$vy2")}];
		#=== normal components ===
		set normX1 [expr {$normalX1*$dotNorm1}];
		set normY1 [expr {$normalY1*$dotNorm1}];
		set normX2 [expr {$normalX2*$dotNorm2}];
		set normY2 [expr {$normalY1*$dotNorm2}];
		#=== tangent components ===
		set tanX1 [expr {$tangentX1*$dotTan1}];
		set tanY1 [expr {$tangentY1*$dotTan1}];
		set tanX2 [expr {$tangentX2*$dotTan2}];
		set tanY2 [expr {$tangentY2*$dotTan2}];
		#=== next vectors ===
		set vx1_2 [expr {lSum("$normX2 $tanX1")}];
		set vy1_2 [expr {lSum("$normY2 $tanY1")}];
		set vx2_2 [expr {lSum("$normX1 $tanX2")}];
		set vy2_2 [expr {lSum("$normY1 $tanY2")}];
		#vector sizes
		set v1_2 [expr {lSum("$vx1_2**2 $vy1_2**2")}];
		set v2_2 [expr {lSum("$vx2_2**2 $vy2_2**2")}];
		#when vector size is 0
		set v1_2 [expr {$v1_2!=0.0?$v1_2:$epsilon}];
		set v2_2 [expr {$v2_2!=0.0?$v2_2:$epsilon}];
		#next unit vectors
		set unitVx1 [expr {$vx1_2/$v1_2}];
		set unitVy1 [expr {$vy1_2/$v1_2}];
		set unitVx2 [expr {$vx2_2/$v2_2}];
		set unitVy2 [expr {$vy2_2/$v2_2}];
		#-------------------------------------------------------------------
		#=== next velocities ===
		set v12X [expr {lSum("$vx1 -$vx2")}];
		set v12Y [expr {lSum("$vy1 -$vy2")}];
		set v21X [expr {lSum("$vx2 -$vx1")}];
		set v21Y [expr {lSum("$vy2 -$vy1")}];
		set m12 [expr {lSum("$m1 $m2")}];
		#when total mass is 0
		set m12 [expr {$m12!=0.0?$m12:$epsilon}];
		#--- next velocities: v1=>u1 and v2=>u2 ---
		#u1
		set uX1 [expr {lSum("$v21X*$m2*$cr $m1*$vx1 $m2*$vx2")/$m12}];
		set uY1 [expr {lSum("$v21Y*$m2*$cr $m1*$vy1 $m2*$vy2")/$m12}];
		#vector size
		set u1 [expr {lSum("$uX1**2 $uY1**2")}];
		#u2
		set uX2 [expr {lSum("$v12X*$m1*$cr $m1*$vx1 $m2*$vx2")/$m12}];
		set uY2 [expr {lSum("$v12Y*$m1*$cr $m1*$vy1 $m2*$vy2")/$m12}];
		#vector size
		set u2 [expr {lSum("$uX1**2 $uY1**2")}];
		#-------------------------------------------------------------------
		#=== next values ===
		set nextVx1 [expr {$unitVx1*$u1}];
		set nextVy1 [expr {$unitVy1*$u1}];
		set nextVx2 [expr {$unitVx2*$u2}];
		set nextVy2 [expr {$unitVy2*$u2}];
		#=== removing variables ===
		unset x1 x2 y1 y2 vx1 vx2 vy1 vy2 m1 m2 cr d;
		#-------------------------------------------------------------------
		unset normalX1 normalY1 normalX2 normalY2;
		unset tangentX1 tangentY1 tangentX2 tangentY2;
		unset dotNorm1 dotNorm2 dotTan1 dotTan2;
		unset normX1 normY1 normX2 normY2;
		unset tanX1 tanY1 tanX2 tanY2;
		unset vx1_2 vy1_2 vx2_2 vy2_2 v1_2 v2_2 unitVx1 unitVy1 unitVx2 unitVy2;
		unset v12X v12Y v21X v21Y m12 uX1 uY1 u1 uX2 uY2 u2;
		#-------------------------------------------------------------------
		return "$nextVx1 $nextVy1 $nextVx2 $nextVy2";
	};
	#it calculates next step
	proc step {} {
		variable mW;variable mH;variable dW;variable dH;variable Char;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable aX;variable aY;variable Isolation;variable D;variable nextVx1;variable nextVy1;variable nextVx2;variable nextVy2;variable EnvX;variable EnvY;
		#max width and height
		set maxW [expr {double($mW)*$dW}];
		set maxH [expr {double($mH)*$dH}];
		#list of all IDs
		set idList [array names Char];
		set IDs [::asciiCore::lPairwise $idList];
		set nId [llength $IDs];
		#environmental accelerations
		#set xEnv [::asciiCore::getEnvX];
		#set yEnv [::asciiCore::getEnvY];
		#--- conditions ---
		#$nId<1 => an element
		#$nId<3 => 2 elements
		#other => 3 or more elements
		if {$nId<1} {
			set vX($idList) [expr {lSum("$vX($idList) $aX($idList)")}];
			set vY($idList) [expr {lSum("$vY($idList) $aY($idList)")}];
		} elseif {$nId<3} {
			set IDs [string map {\{ {} \} {}} $IDs];
			set IDs [split $IDs \x20];
			set ID1 [lindex $IDs 0];
			set ID2 [lindex $IDs 1];
			set col [::asciiCore::ifCollision $ID1 $ID2];
			expr {!!$col?[::asciiCore::getCollision $ID1 $ID2]:0};
			set vX($ID1) [expr {!!$col?lSum("$nextVx1 $aX($ID1)"):lSum("$vX($ID1) $aX($ID1)")}];
			set vY($ID1) [expr {!!$col?lSum("$nextVy1 $aY($ID1)"):lSum("$vY($ID1) $aY($ID1)")}];
			set vX($ID2) [expr {!!$col?lSum("$nextVx2 $aX($ID2)"):lSum("$vX($ID2) $aX($ID2)")}];
			set vY($ID2) [expr {!!$col?lSum("$nextVy2 $aY($ID2)"):lSum("$vY($ID2) $aY($ID2)")}];
		} else {
			foreach e $IDs {
				set e [string map {\{ {} \} {}} $e];
				set ID1 [lindex $e 0];
				set ID2 [lindex $e 1];
				set col [::asciiCore::ifCollision $ID1 $ID2];
				expr {!!$col?[::asciiCore::getCollision $ID1 $ID2]:0};
				set vX($ID1) [expr {!!$col?lSum("$nextVx1 $aX($ID1)"):lSum("$vX($ID1) $aX($ID1)")}];
				set vY($ID1) [expr {!!$col?lSum("$nextVy1 $aY($ID1)"):lSum("$vY($ID1) $aY($ID1)")}];
				set vX($ID2) [expr {!!$col?lSum("$nextVx2 $aX($ID2)"):lSum("$vX($ID2) $aX($ID2)")}];
				set vY($ID2) [expr {!!$col?lSum("$nextVy2 $aY($ID2)"):lSum("$vY($ID2) $aY($ID2)")}];
			};
		};
		#=== plotting objects ===
		foreach e $idList {
			set X($e) [expr {lSum("$X($e) $vX($e)")}];
			set Y($e) [expr {lSum("$Y($e) $vY($e)")}];
			::asciiCore::plot $e;
		};
		#=== removing variables ===
		#unset maxW maxH idList IDs nId xEnv yEnv;
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
		variable dW;variable dH;variable Char;variable Rho;variable M;variable D;
		set dW [expr {double($dw>0?$dw:$dW)}];
		set dH [expr {double($dh>0?$dh:$dH)}];
		#V is approximated object volume
		set V [expr {double($dW*$dH)}];
		#new value for diameter
		set D [expr {min($dW,$dH)}];
		#clearing map
		::asciiCore::clear;
		#replot objects on map
		foreach e [array names Char] {
			#new value for mass
			set M($e) [expr {double($Rho($e)*$V)}];
			::asciiCore::plot $e;
		};
		return "$dW $dH";
	};
	#it resets size and scales for map, and removes all objects
	proc reset {} {
		variable LOG {};variable nStep 0;variable nextVx1 0.0;variable nextVy1 0.0;variable nextVx2 0.0;variable nextVy2 0.0;variable EnvX;variable EnvY;
		set nEnvX [array names EnvX];
		set nEnvY [array names EnvY];
		if {![llength $nEnvX]} {
			foreach e $nEnvX {array unset EnvX $e;};
		};
		if {![llength $nEnvY]} {
			foreach e $nEnvY {array unset EnvY $e;};
		};
		::asciiCore::remove;
		::asciiCore::resize 10 10;
		::asciiCore::setScales 1.0 1.0;
		::asciiCore::clear;
		unset nEnvX nEnvY;
	};
	#it returns object information
	#information of all objects are returned if ID list is omitted
	proc objectInfo {{idList {}}} {
		# - $idList: a list of object ID
		variable Char;variable Rho;variable M;variable X;variable Y;variable vX;variable vY;variable aX;variable aY;variable Isolation;
		set idList [expr {![llength $idList]?[array names Char]:$idList}];
		#info is information list
		set info [list [list ID Char Rho M X Y vX vY aX aY Isolation]];
		foreach e $idList {
			lappend info [list $e $Char($e) $Rho($e) $M($e) $X($e) $Y($e) $vX($e) $vY($e) $aX($e) $aY($e) $Isolation($e)];
		};
		return $info;
	};
};
##===================================================================
#it runs simulation
proc ::asciiCore::run {{n 10} {delay 250}} {
	# - $n: model simulated for n-1 time steps, i.e., 0th step is the initial step
	# - $delay: delay in milliseconds with default value of 250
	variable LOG;variable nStep;variable dW;variable dH;variable epsilon;
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
	puts stdout "unit scales: ${dW} x ${dH}\nsteps: [expr {$nStep-1}]";
	puts stdout "epsilon: $epsilon";
};
#it shows simulation result
proc ::asciiCore::preview {{delay 250}} {
	# - $delay: delay in milliseconds with default value of 250
	variable LOG;variable epsilon;
	set n [llength $LOG];
	#Clearing display
	puts stdout "\u1b\[2J";
	foreach e $LOG {
		puts -nonewline stderr "\u1b\[1;1H$e";
		after $delay;
	};
	puts stdout "\n\#===================================================================";
	puts stdout "steps: [expr {$n-1}]";
	puts stdout "epsilon: $epsilon";
};
#it outputs log as JavaScript code
proc ::asciiCore::output_JS {{name {}}} {
	# - $name: a name for output JavaScript function with default value of "asciiCore[numbers]"
	variable LOG;
	set logJS {};
	set js {};
	#--- name ---
	set name [expr {[llength $name]>0?$name:"asciiCore[clock seconds]"}];
	set name [string map {\x20 _ \t _ . _ , _} $name];
	#--- JavaScript function ---
	set js "var\x20$name=function()";
	set logJS [join [lmap e $LOG {string map {\n \\n} "\"$e\"";}] ,];
	append js "\{return\x20\[$logJS\]\;\}\;";
	#--- output ---
	set C [open "$name.js" w];
	fconfigure $C -encoding utf-8;
	puts -nonewline $C $js;
	close $C;unset C;
	#=== removing variables ===
	unset logJS js;
	return "$name.js";
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
