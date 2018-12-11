# asciiCore
Simple particle simulation in ascii art.  
GitHub: https://github.com/YujiSODE/asciiCore  
>Copyright (c) 2018 Yuji SODE \<yuji.sode@gmail.com\>  
>This software is released under the MIT License.  
>See LICENSE or http://opensource.org/licenses/mit-license.php
______

## 1. Description
It generates map list and displays this list.  
Command `::asciiCore::setObject` can define an object and returns object ID. Command `::asciiCore::remove` can remove one or more objects using object ID. Simulation settings can be reset by `::asciiCore::reset;`.  
Command `::asciiCore::run` runs simulation using defined objects. Map data can be cleared using command `::asciiCore::clear`. Simulated result can be output as a single JavaScript file using command `::asciiCore::output_JS`.

## 3. Script
#### Tcl
It requires Tcl 8.6+.  
- `asciiCore.tcl`: main script in Tcl
#### JavaScript
- `asciiCore_preview.js`: script to show simulated result in HTML

## 4. Library list
- Sode, Y. 2018. lSum.tcl: https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0
- Sode, Y. 2018. lPairwise.tcl: the MIT License; https://gist.github.com/YujiSODE/0d520f3e178894cd1f2fee407bbd3e16

## 5. Reference
- Tanaka, K. 2017. JavaScript game programming. Future Coders, Impress R&D. ISBN: 978-4-8443-9755-7
