#test_asciiCore01.tcl
source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::resize 20 10;
#::asciiCore::setEnvX wind [expr {-1.0*0.08}];
::asciiCore::setEnvY gravity [expr {9.8*0.08}];
#################
::asciiCore::setObject * 1 {6 3};
::asciiCore::setObject D 1 {4 0};
::asciiCore::setObject C 1 {4 4} 
#################
set i 0;
while {$i<10} {
	::asciiCore::setFree [::asciiCore::setIsolated [::asciiCore::setObject @ 10 [list $i 8]]];
	incr i 1;
};
#################
::asciiCore::run 10 1000;
parray ::asciiCore::idMap;
::asciiCore::output_JS;
