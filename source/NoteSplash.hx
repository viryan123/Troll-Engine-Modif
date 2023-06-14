package;

import flixel.util.FlxColor;
import shaders.AmongUsColorSwapShader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import math.Vector3;

class NoteSplash extends NoteObject
{
	public var noteType:String;
	public var useRGBColors:Bool = true;

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var colorSwap:AmongUsColorSwapShader = null;
	public var vec3Cache:Vector3 = new Vector3();

	public function new(x:Float = 0, y:Float = 0, type:String, data:Int, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, redColor:FlxColor = 0)
	{
		super(x, y);
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end

		noteType = type;
		noteData = data;
		colorSwap = new AmongUsColorSwapShader();
		shader = colorSwap;

		switch (noteType)
		{
			default:
				switch (PlayState.SONG.splashSkin)
				{
					case 'tenzus':
						frames = Paths.getSparrowAtlas('noteSplash/tenzus_splash', 'shared');

						for (i in 1...3) {
							animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
							animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
							animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
							animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
						}

						scale.set(0.8, 0.8);
						updateHitbox();
					default:
						frames = Paths.getSparrowAtlas('noteSplash/noteSplash', 'shared');

						for (i in 1...3)
						{
							animation.addByPrefix("note1-" + i, "note impact " + i + " blue", 24, false);
							animation.addByPrefix("note2-" + i, "note impact " + i + " green", 24, false);
							animation.addByPrefix("note0-" + i, "note impact " + i + " purple", 24, false);
							animation.addByPrefix("note3-" + i, "note impact " + i + " red", 24, false);
						}

						offset.x += 90;
						offset.y += 80;
				}
		}

		if (ClientPrefs.noteSkin == 'Quants')
		{
			if (useRGBColors)
			{
				colorSwap.active = true;

				colorSwap.red = redColor;
				colorSwap.green = 0xffffff;
				colorSwap.blue = 0xffffff;
			}	

			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			colorSwap.hue = hueColor;
			colorSwap.saturation = satColor;
			colorSwap.brightness = brtColor;
		}

		antialiasing = true;
		alpha = 0.6;
	}

	public function playStatePlay()
	{
		switch (noteType)
		{
			default:
				switch (PlayState.SONG.splashSkin)
				{
					case 'tenzus':
						var animNum:Int = FlxG.random.int(1, 2);
						animation.play('note' + noteData + '-' + animNum, true);
						if(animation.curAnim != null)animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
					default:
						var animNum:Int = FlxG.random.int(1, 2);
						if (ClientPrefs.noteSkin == 'Quants')
							animation.play('note3' + '-' + animNum, true);
						else
							animation.play('note' + noteData + '-' + animNum, true);
				}
		}

		animation.finishCallback = function(name)
		{
			alpha = 0;
			kill();
			destroy();
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
