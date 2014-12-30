GTween Introduction
===================

Gingee's GTween library is an open-source lightweight tweenning library for Haxe using openfl.
It helps to quickly and effortlessly create rich tweens of any object with numerous parameters over time. 
it can be used with any type of object with any type of public field its value is a Float / UInt / Int.

GTweens supports modifiers and can handle looping and easing functions.

License
=======
GTween is free, open-source software under the supplied license.

Usage
=====

Usage example I:
GTween.tweenTo(obj, 1.5, {x:500});

Usage example II:
GTween.tweenFrom(obj, 1.5, {points:500, onComplete:completeFunc, onUpdate:updateFunc, ease:Linear.easeIn, loop:GTween.OSCILLATE});

Usage example III:
GTween.tweenTo(obj, .5, {rotation:500, loop:GTween.OSCILLATE, ease:Bounce.easeIn, onStart:onStart, onComplete:onComplete, delay:.1, onCompleteParams:[1, 15], numLoops:3});
