package;

import flixel.util.FlxColor;
import shaders.AmongUsColorSwapShader;
#if !macro
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
#end
import math.Vector3;

using StringTools;

class StrumNote extends NoteObject
{

	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;

	public var daStyle = 'style';
	public var pixelNotes:Array<String> = ['pixel'];
	
	override function destroy()
	{
		defScale.put();
		super.destroy();
	}	
	public var isQuant:Bool = false;
	private var colorSwap:AmongUsColorSwapShader;
	private var currentRed:FlxColor;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var useRGBColors:Bool = true;
	public var useDefaultColors:Bool = true;
	
	//private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function getZIndex(?daZ:Float)
	{
		if(daZ==null)daZ = z;
		var animZOffset:Float = 0;
		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
			animZOffset += 1;
		return z + desiredZIndex + animZOffset;
	}

	function updateZIndex()
	{
		zIndex = getZIndex();
	}
	

	public function new(x:Float, y:Float, leData:Int, ?skin:String = 'QUANTNOTE_assets') {
		colorSwap = new AmongUsColorSwapShader();
		shader = colorSwap;
		super(x, y);
		noteData = leData;
		// trace(noteData);

		currentRed = 0xffffff;
		//colorChange.red = currentRed;

		if (skin == '' || skin == null)
			skin = 'NOTE_assets';
		texture = skin; // Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		isQuant = false;

		if (texture == null || texture.length < 1)
		{
			texture = 'QUANTNOTE_assets';
		}

		daStyle = texture;
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (ClientPrefs.noteSkin == 'Quants')
		{
			isQuant = true;
		}
		else
		{
			isQuant = false; 
		}

		switch (texture)
		{
			case 'pixel':
				loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'), true, Math.floor(width), Math.floor(height));

				antialiasing = false;
				useRGBColors = false;
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

				// animation.add('green', [6]);
				// animation.add('red', [7]);
				// animation.add('blue', [5]);
				// animation.add('purple', [4]);
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.add('static', [0]);
						animation.add('pressed', [4, 8], 12, false);
						animation.add('confirm', [12, 16], 24, false);
					case 1:
						animation.add('static', [1]);
						animation.add('pressed', [5, 9], 12, false);
						animation.add('confirm', [13, 17], 24, false);
					case 2:
						animation.add('static', [2]);
						animation.add('pressed', [6, 10], 12, false);
						animation.add('confirm', [14, 18], 12, false);
					case 3:
						animation.add('static', [3]);
						animation.add('pressed', [7, 11], 12, false);
						animation.add('confirm', [15, 19], 24, false);
				}
			case 'tenzus':
				frames = Paths.getSparrowAtlas('noteSkin/tenzus_notes');
				_loadStrumAnims();

				useRGBColors = false;
			default:
				frames = Paths.getSparrowAtlas('noteSkin/QUANTNOTE_assets');
				_loadStrumAnims();
		}
		
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	/*public function loadNoteAnims() {
		if (noteScript != null && noteScript.scriptType == 'hscript'){
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.exists("loadNoteAnims") && Reflect.isFunction(noteScript.get("loadNoteAnims"))){
				noteScript.executeFunc("loadNoteAnims", [this], this, ["super" => _loadNoteAnims]);
				return;
			}
		}
		_loadNoteAnims();
	}*/

	function _loadStrumAnims() {
		switch (texture)
		{
			default:
				animation.addByPrefix('green', 'arrowUP');
				animation.addByPrefix('blue', 'arrowDOWN');
				animation.addByPrefix('purple', 'arrowLEFT');
				animation.addByPrefix('red', 'arrowRIGHT');
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.addByPrefix('static', 'arrowLEFT');
						animation.addByPrefix('pressed', 'left press', 24, false);
						animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1:
						animation.addByPrefix('static', 'arrowDOWN');
						animation.addByPrefix('pressed', 'down press', 24, false);
						animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 2:
						animation.addByPrefix('static', 'arrowUP');
						animation.addByPrefix('pressed', 'up press', 24, false);
						animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 3:
						animation.addByPrefix('static', 'arrowRIGHT');
						animation.addByPrefix('pressed', 'right press', 24, false);
						animation.addByPrefix('confirm', 'right confirm', 24, false);
				}
		
				antialiasing = ClientPrefs.globalAntialiasing;
				setGraphicSize(Std.int(width * 0.7));
		}
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		x -= Note.swagWidth / 2;
		x = x - (Note.swagWidth * 2) + (Note.swagWidth * noteData) + 54;

		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if(animation.curAnim != null){
			if(animation.curAnim.name == 'confirm') 
				centerOrigin(); 
			
		}
		updateZIndex();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note) {
		animation.play(anim, force);
		centerOrigin();
		centerOffsets();
		updateZIndex();

		colorSwap.active = false;

		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (note != null)
				{
					if(isQuant) {
						if (useRGBColors)
						{
							currentRed = note.colorSwap.red;
							colorSwap.red = currentRed;
							colorSwap.green = 0xffffff;
							colorSwap.blue = note.colorSwap.blue;
						}
	
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
	
						if (useRGBColors)
							colorSwap.active = true;
						isQuant = true;
					} else {
						colorSwap.hue = note.colorSwap.hue;
						colorSwap.saturation = note.colorSwap.saturation;
						colorSwap.brightness = note.colorSwap.brightness;
	
						if (useRGBColors)
						{
							colorSwap.red = note.colorSwap.red;
							colorSwap.green = 0xffffff;
							colorSwap.blue = note.colorSwap.blue;
							colorSwap.active = true;
						}
						isQuant = false;
					}
				}
				else
				{
					colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
					colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
					colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
	
					if(animation.curAnim.name == 'pressed' && useRGBColors) {
						colorSwap.active = true;
						colorSwap.red = FlxColor.interpolate(currentRed, 0x87a3ad, 0.6);
						colorSwap.blue = 0x201E31;
						colorSwap.green = 0xffffff;
					}
				}
		}
	}
}