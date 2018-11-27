source -encoding utf-8 ./asciiCore.tcl;
::asciiCore::setObject @ 1;
::asciiCore::setObject + 1 {1 0} {-1 0};
::asciiCore::setObject * 1 {5 0} {-1 1};
::asciiCore::setObject * 1 {0 5} {1 -1};
::asciiCore::show 5 1000;
after 250;
::asciiCore::preview;
::asciiCore::output_JS;
