/*asciiCore
*asciiCore_preview.js
*===================================================================
*	Copyright (c) 2018 Yuji SODE <yuji.sode@gmail.com>
*
*	This software is released under the MIT License.
*	See LICENSE or http://opensource.org/licenses/mit-license.php
*===================================================================
* A simple tool for showing ascii art
*=== Synopsis ===
* `asciiCore_preview(asciiArt?,delay?);`
* this function shows an array of ascii art in <pre> HTML element
* that has id of "asciiCore", and it returns intervalID for `clearInterval(intervalID)`
*--- Parameters ---
* - asciiArt: an array of ascii art
* - delay: an optional delay in milliseconds with default value of 250
*/
//===================================================================
//this function shows an array of ascii art in <pre> HTML element that has id of "asciiCore", and it returns intervalID for `clearInterval(intervalID)`
function asciiCore_preview(asciiArt,delay){
	// - asciiArt: an array of ascii art
	// - delay: an optional delay in milliseconds with default value of 250
	var slf=window,n=asciiArt.length,pre=slf.document.getElementById('asciiCore'),i=1,T='';
	delay=!delay?250:delay;
	//initial value
	pre.textContent=asciiArt[0];
	T=slf.setInterval(()=>{pre.textContent=asciiArt[i%n],i+=1;},delay);
	return T;
}
