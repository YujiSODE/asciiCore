source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::resize 20 10;
::asciiCore::setEnvX wind [expr {-1.0*0.08}];
::asciiCore::setEnvY gravity [expr {9.8*0.08}];
#################
::asciiCore::setObject @ 1 {3 3} {1 0};
::asciiCore::setObject * 1 {6 3} {-1 0};
::asciiCore::setObject D 1 {10 0} {0 1};
::asciiCore::setObject C 1 {10 4} {0 -0.5};
#################
::asciiCore::run 10 1000;
parray ::asciiCore::idMap;
::asciiCore::output_JS;
