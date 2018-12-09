#test_asciiCore02.tcl
source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::resize 20 10;
#################
::asciiCore::setObject A 1 {6 3} {1 0};
::asciiCore::setObject B 1 {6 4} {1 0};
::asciiCore::setObject C 1 {6 5} {1 0};
::asciiCore::setObject D 1 {7 4} {1 0};
#################
set i 1;
while {$i<9} {
	::asciiCore::setObject @ 0.5 "10 $i";
	incr i 1;
};
#################
::asciiCore::run 8 1000;
parray ::asciiCore::idMap;
::asciiCore::output_JS {asciiCore_sample02};
