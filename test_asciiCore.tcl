source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::resize 20 20;
#################
::asciiCore::setObject @ 1;
::asciiCore::setObject + 1 {1 0} {-1 0};
::asciiCore::setObject 1 1 {15 10} {-1 1};
::asciiCore::setObject 2 1 {10 15} {1 -1};
::asciiCore::setObject 3 1 {9 2} {-1 0};
#################
::asciiCore::run 3 1000;
parray ::asciiCore::idMap;
::asciiCore::output_JS;
