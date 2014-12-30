package com.gingee.gTween;

import com.gingee.gTween.animator.Animator;
import openfl.events.Event;
import haxe.Timer;
import haxe.ds.ObjectMap;

class GTween
{
	private var _timeInSec:Float;
	private var _from:Bool = false;
	private var _startTime:Float;
	private var _delay:Float;
	private var _duration:Float;
	private var _object:Dynamic;
	private var _vars:Dynamic;
	private var _started:Bool = false;
	private var _tweens:Array<TweenDesc>;
	private var _easing = easeNone;
	private var _paused:Bool = false;
	private var _pausePrecentage:Float = 0;
	
	public static var VERSION:String = '1.0.5';
	public static var OSCILLATE:String = 'osc';
	public static var LOOP:String = 'loop';
	/**
	 * GTween is a class that helps create rich tweens. it can be used on any type of object with any type of field that has a getter and a setter and its value is a Float.
	 * <br/><br/>
	 * @param obj:Dynamic - the object that we wish to tween.<br/>
	 * @param timeInSec:Float - Tween time in seconds.
	 * @param vars:Dynamic - tweening parameters.<br/>
	 * Among vars fields, you can use following <br/>
	 * delay:Float - delay time in Seconds. tween will start after that delay. </br>
	 * ease:Float->Float->Float->Float->Float - the easing function. import from com.gingee.gTween.ease.*;<br/>
	 * loop:String - looping capabilities. use GTween.OSCILLATE for back-and-forth behaviour. use GTween.LOOP for repeating behaviour. will run infinitly.<br/>
	 * numLoops:Int - loop repetitions number. do not specify /use null for infinite.
	 * onUpdate:Void->Void - a function to invoke when current tween is updating.<br/>
	 * onComplete:Void->Void - a function to invoke when tween has completed.<br/>
	 * onStart:Void->Void - a function to invoke when tween has started. (after delay, if was defined)<br/>
	 * onCompleteParams:Array - an array of parameters to pass when onComplete is invoked.<br/>
	 * To create a tween please use the static methods GTween.tweenTo() and GTween.tweenFrom().
	 * <br/><br/>
	 * Example I:
	 * <br/><br/>
	 * GTween.tweenTo(someDisplayDynamic, 1.5, {x:500, y:600, onComplete:someFunction, onUpdate:someUpdateFunction, ease:Bounce.easeIn});
	 * <br/><br/>
	 * Example II:
	 * <br/><br/>
	 * GTween.tweenFrom(someDynamic, 1.5, {points:500, onComplete:someFunction, onUpdate:someUpdateFunction, ease:Linear.easeIn, loop:GTween.LOOP});
	 */
	public function new(obj:Dynamic, timeInSec:Float, vars:Dynamic, from:Bool)
	{
		if (obj == null) {throw 'Cant tween a null object';}
		_from = from;
		_vars = vars;
		_object = obj;
		_timeInSec = timeInSec;
		
		_delay = Reflect.hasField(_vars, 'delay') ? Reflect.field(_vars, 'delay')*1000 : 0;
		_startTime = getTimer() + _delay;
		_duration = timeInSec == 0 ? .001 : timeInSec;
		
		_tweens = [];
		addThisToTweens();

		for (k in Reflect.fields(vars))
		{
			var val:Float = Reflect.getProperty(vars, k);
			var objVal:Float = Reflect.getProperty(_object, k);

			if(Reflect.field(_object, k) != null || /* fix for JS fields like __x*/ Reflect.hasField(_object, "__" + k))
			{
				var td:TweenDesc = new TweenDesc();
				td.prop = k;
				
				if(from)
				{
					td.delta = objVal - val;
					td.start = val;
				}
				else
				{
					td.start = objVal;
					td.delta = val - objVal;
				}
				
				_tweens.push(td);
			}
		}
		
		if(Reflect.hasField(_vars, 'ease'))
			_easing = Reflect.field(_vars, 'ease');

		ignite();
	}
	
	private function reverseVars():Void
	{
		var ln:Int = _tweens.length;
		for ( i in 0...ln ) 
		{
			var td:TweenDesc = _tweens[i];
			if(td != null)
				Reflect.setProperty(_vars, td.prop, td.start);
		}
	}
	
	private function update(tm:Float):Void
	{
		var iii:Int = 0;
		var currentTime:Float = getTimer();


		if(currentTime < _startTime)
			return;

		if(!_started && Reflect.hasField(_vars, 'onStart')) 
		{
			_started = true;
			try{
				invoke(_vars, 'onStart', null);
			}catch(e : String){}
		}
		
		var time:Float = (tm - _startTime) * 0.001;
		var precentage:Float;
		var i:Int;
		
		if (time >= _duration) 
		{
			time = _duration;
			precentage = 1;//(_duration == 0.001) ? 1 : 0;
		} 
		else
		{
			precentage = _easing(time, 0, 1, _duration);
		}

		for( i in 0..._tweens.length )
		{
			var td:TweenDesc = this._tweens[i];
			Reflect.setProperty(_object, td.prop, td.start + (precentage * td.delta));
		}
		
		if (Reflect.hasField(_vars, 'onUpdate'))
			invoke(_vars, 'onUpdate', null);
		
		if (time == _duration)
		{
			if(Reflect.hasField(_vars, 'loop'))
			{
				complete();
				
				var remainningLoops:Bool = true;
				
				if(Reflect.hasField(_vars, 'numLoops'))
				{
					var numLoops:Int = Reflect.field(_vars, 'numLoops');
					Reflect.setProperty(_vars, 'numLoops', numLoops - 1);
					if(numLoops - 1 <= 0) remainningLoops = false;
				}
				
				if(remainningLoops)
				{
					var loop:String = Reflect.field(_vars, 'loop');
					if(loop == OSCILLATE)
					{
						reverseVars();
						tweenTo(_object, _timeInSec, _vars);
					}
					else if(loop == LOOP)
					{
						resetValues();
						tweenTo(_object, _timeInSec, _vars);
					}
				}
				destroy();
			}
			else
			{
				complete();
				destroy();
			}
		}
	}
	
	private function resetValues():Void
	{
		for( i in 0..._tweens.length )
		{
			var td:TweenDesc = this._tweens[i];
			Reflect.setProperty(_object, td.prop, td.start);
		}
	}
	
	public function pause():Void
	{
		if(_paused)
			return;
		
		_paused = true;
		var timePassed:Float = getTimer() - _startTime;
		_pausePrecentage = timePassed/(_duration*1000);
		
		removeThisFromTweens();
		terminateIfPossible();
	}
	
	public function resume():Void
	{
		if(!_paused)
			return;
		
		_paused = false;
		_startTime = getTimer() - (_pausePrecentage*(_duration*1000));
		addThisToTweens();
		
		ignite();
	}
	

	private function complete():Void 
	{
		removeThisFromTweens();
		terminateIfPossible();
		
		if (Reflect.hasField(_vars, 'onComplete'))
		{
			var onCompleteParams:Dynamic = Reflect.field(_vars, 'onCompleteParams');
			if(Reflect.hasField(_vars, 'numLoops') && Reflect.field(_vars, 'numLoops') - 1 <= 0)
				invoke(_vars, 'onComplete', onCompleteParams);
			else if(_vars.numLoops == null)
				invoke(_vars, 'onComplete', onCompleteParams);
		}
	}
	
	private function addThisToTweens():Void
	{
		if(!_tween.exists(_object))
			_tween.set(_object, new Array<Dynamic>());
			
		var arr = _tween.get(_object);
		arr.push(this);
		_tween.set(_object, arr);
	}

	private function removeThisFromTweens():Void
	{
		var arr:Array<Dynamic> = _tween.get(_object);
		
		if(arr == null)
			return;
		
		var indx:Int = arr.indexOf(this);
		if(indx == -1) return;
		
		(_tween.get(_object)).splice(indx, 1);
		
		if(_tween.get(_object).length == 0)
			 _tween.remove(_object);
	}
	
	public function completeAllMovements():Void
	{
		var ln = _tweens.length;
		for(i in 0...ln)
		{
			var td:TweenDesc = _tweens[i];
			
			if(_object != null)
				Reflect.setProperty(_object, td.prop, td.start + (1 * td.delta));
		}
	}

	private function destroy():Void
	{
		_object = null;
		_vars = null;
	}
	
	/* ..................................... STATIC ............................ */
	
	private static var _tween:ObjectMap<Dynamic, Array<Dynamic>> = new ObjectMap<Dynamic, Array<Dynamic>>();
	private static var _updater:GTweenUpdater = new GTweenUpdater();
	private static var _animating:Bool = false;
	
	public static function updateTweens(e:Event):Void
	{
		var tm:Float = getTimer();

		for (k in _tween)
		{
			var ln = k.length;
			for(i in 0...ln)
			{
				var tween:GTween = k[i];
				if(tween != null) tween.update(tm);
			}
		}
	}

	private static function terminateIfPossible():Void
	{
		if(!noTweensLeft())
			return;

		_animating = false;
		Animator.removeAnimation(_updater);
	}

	private static function ignite():Void
	{
		if(_animating)
			return;

		_animating = true;
		Animator.submitAnimation(_updater);
	}
	
	public static function removeAllTweens(completeAnimation:Bool = true):Void
	{
		for (k in Reflect.fields(_tween))
		{
			var twns:Array<GTween> = Reflect.field(_tween, k);
			
			if(twns != null)
			{
				var ln:Int = twns.length;
				for(i in 0...ln)
				{
					var an:GTween = twns[i];
					if(an != null)
					{
						if(completeAnimation)
							an.completeAllMovements();
						an.destroy();
					}
				}
				
				_tween.remove(k);
			}
		}
		
		terminateIfPossible();
	}
	
	public static function removeTweensOf(obj:Dynamic, completeAnimation:Bool = true):Void
	{
		if(obj == null)
			return;
		
		var twns:Array<Dynamic> = _tween.get(obj);
		
		if(twns != null)
		{
			var ln:Int = twns.length;
			for(i in 0...ln)
			{
				if(Std.is(twns[i], GTween))
				{
					var an:GTween = cast(twns[i], GTween);
					if(an != null)
					{
						if(completeAnimation) an.completeAllMovements();
						an.destroy();
					}
				}
			}
			
			_tween.remove(obj);
		}
		
		terminateIfPossible();
	}

	private static function invoke(obj:Dynamic, func:String, params):Void
	{
		Reflect.callMethod(obj, Reflect.field(obj, func), params);
	}

	private static function getTimer():Float
	{
		return Timer.stamp() * 1000;
	}

	public static function tweenTo(obj:Dynamic, timeInSec:Float, vars:Dynamic):GTween
	{
		return new GTween(obj, timeInSec, vars, false);
	}
	
	public static function tweenFrom(obj:Dynamic, timeInSec:Float, vars:Dynamic):GTween
	{
		return new GTween(obj, timeInSec, vars, true);
	}
	
	private static function easeNone(t:Float, b:Float, c:Float, d:Float):Float 
	{
		return c*t/d + b;
	}
	
	public static function noTweensLeft():Bool 
	{
		var ii:Int = 0;
		for(key in _tween.keys())
			ii++;

		return ii == 0;
	}
}