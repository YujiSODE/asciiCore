#test_asciiCore01.tcl
source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::resize 20 10;
::asciiCore::setEnvY gravity [expr {9.8*0.08}];
#################
::asciiCore::setObject A 1 {6 3};
::asciiCore::setObject B 1 {4 0};
#################
set i 0;
while {$i<10} {
	::asciiCore::setFree [::asciiCore::setIsolated [::asciiCore::setObject @ 10 [list $i 8]]];
	incr i 1;
};
#################
::asciiCore::run 10 1000;
parray ::asciiCore::idMap;
::asciiCore::output_JS {asciiCore_sample01};
