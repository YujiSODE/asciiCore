# asciiCore
Simple particle simulation in ascii art.  
GitHub: https://github.com/YujiSODE/asciiCore  
>Copyright (c) 2018 Yuji SODE \<yuji.sode@gmail.com\>  
>This software is released under the MIT License.  
>See LICENSE or http://opensource.org/licenses/mit-license.php
______
## Synopsis
- `::asciiCore::clear;`
- `::asciiCore::getMap;`
- `::asciiCore::xCoord x;`
- `::asciiCore::yCoord y;`
- `::asciiCore::plot id;`
- `::asciiCore::setEnvX name value;`
- `::asciiCore::setEnvY name value;`
- `::asciiCore::getEnvX;`
- `::asciiCore::getEnvY;`
- `::asciiCore::setObject char rho ?xy0? ?v0? ?a0? ?cr?;`
- `::asciiCore::setIsolated id;`
- `::asciiCore::unsetIsolated id;`
- `::asciiCore::setFree id;`
- `::asciiCore::unsetFree id;`
- `::asciiCore::remove ?idList?;`
- `::asciiCore::ifCollision id1 id2;`
- `::asciiCore::getCollision id1 id2;`
- `::asciiCore::step;`
- `::asciiCore::resize w h;`
- `::asciiCore::setScales dw dh;`
- `::asciiCore::reset;`
- `::asciiCore::objectInfo ?idList?;`
______
- `::asciiCore::run ?n? ?delay?;`
- `::asciiCore::preview ?delay?;`
- `::asciiCore::output_JS ?name?;`

## Description
It generates map list and displays this list.

## Script
#### Tcl
It requires Tcl 8.6+.  
- `asciiCore.tcl`
#### JavaScript
- `asciiCore_preview.js`

## Library list
- Sode, Y. 2018. lSum.tcl: https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0
- Sode, Y. 2018. lPairwise.tcl: the MIT License; https://gist.github.com/YujiSODE/0d520f3e178894cd1f2fee407bbd3e16

## Reference
- Tanaka, K. 2017. JavaScript game programming. Future Coders, Impress R&D. ISBN: 978-4-8443-9755-7
