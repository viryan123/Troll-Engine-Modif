package;

import flixel.math.FlxPoint;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
	Overlay that displays FPS and memory usage.

	Based on this tutorial:
	https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
**/
class Overlay extends Sprite
{
	var times:Array<Float> = [];
	var memPeak:UInt = 0;

	// display info
	static var displayFps = true;
	static var displayMemory = true;

	public var bgSprite:Bitmap;

	var fpsCounter:TextField;
	var textFormat:TextFormat;

	public static var offset:FlxPoint = new FlxPoint();

	@:isVar public static var __bitmap(get, null):BitmapData = null;

	private static function get___bitmap():BitmapData
	{
		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);
		return __bitmap;
	}

	public function new(x:Float, y:Float)
	{
		super();

		this.x = x;
		this.y = x;

		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0;
		addChild(bgSprite);

		fpsCounter = new TextField();
		fpsCounter.defaultTextFormat = new TextFormat(Paths.font("CONSOLA.ttf"), 18, 0xFFFFFF);
		fpsCounter.text = "";

		fpsCounter.autoSize = LEFT;
		fpsCounter.selectable = false;
		addChild(fpsCounter);

		addEventListener(Event.ENTER_FRAME, update);
	}

	static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB'];

	public static function getInterval(num:UInt):String
	{
		var size:Float = num;
		var data = 0;
		while (size > 1000 && data < intervalArray.length - 1)
		{
			data++;
			size = size / 1000;
		}

		size = Math.round(size * 100) / 100;
		return size + " " + intervalArray[data];
	}

	function update(_:Event)
	{
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		var mem = System.totalMemory;
		if (mem > memPeak)
			memPeak = mem;

		if (visible)
		{
			fpsCounter.text = '' // set up the text itself
				+ (displayFps ? (times.length > ClientPrefs.framerate ? ClientPrefs.framerate : times.length) + " FPS\n" : '') // Framerate
				+ (displayMemory ? '${getInterval(mem)} / ${getInterval(memPeak)}\n' : ''); // Current and Total Memory Usage
		}

		var width = Math.max(fpsCounter.width, fpsCounter.width) + (x * 2);
		var height = fpsCounter.height;

		// x = 10 + offset.x;
		// y = 2 + offset.y;

		bgSprite.alpha = 0.5;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;
	}

	public static function updateDisplayInfo(shouldDisplayFps:Bool, shouldDisplayMemory:Bool)
	{
		displayFps = shouldDisplayFps;
		displayMemory = shouldDisplayMemory;
	}
}
