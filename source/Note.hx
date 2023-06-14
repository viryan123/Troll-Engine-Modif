package;

import JudgmentManager.Judgment;
import PlayState.Wife3;
import haxe.io.Path;
import editors.ChartingState;
import flixel.math.FlxPoint;
import math.Vector3;
import openfl.utils.Assets;
import shaders.AmongUsColorSwapShader;
import scripts.*;
import playfields.*;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef HitResult = {
	judgment: Judgment,
	hitDiff: Float
}

@:enum abstract SplashBehaviour(Int) from Int to Int
{
	var DEFAULT = 0; // only splashes on judgements that have splashes
	var DISABLED = -1; // never splashes
	var FORCED = 1; // always splashes
}
class Note extends NoteObject
{
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var hitResult:HitResult = {
		judgment: UNJUDGED,
		hitDiff: 0
	}

	override function destroy()
	{
		defScale.put();
		super.destroy();
	}
	public var mAngle:Float = 0;
	public var bAngle:Float = 0;
	
	public var noteScript:FunkinScript;


	public static var quants:Array<Int> = [
		4, // quarter note
		8, // eight
		12, // etc
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	public static function getQuant(beat:Float){
		var row = Conductor.beatToNoteRow(beat);
		for(data in quants){
			if(row%(Conductor.ROWS_PER_MEASURE/data) == 0){
				return data;
			}
		}
		return quants[quants.length-1]; // invalid
	}
	public var noteDiff:Float = 1000;

	// quant shit
	public var noteQuant:Int = -1;
	public var quant:Int = 4;
	public var extraData:Map<String, Dynamic> = [];
	public var isQuant:Bool = false; // mainly for color swapping, so it changes color depending on which set (quants or regular notes)
	public var canQuant:Bool = true;
	
	// basic stuff
	public var beat:Float = 0;
	public var strumTime:Float = 0;
	public var visualTime:Float = 0;
	public var mustPress:Bool = false;
	@:isVar
	public var canBeHit(get, null):Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var spawned:Bool = false;
	function get_canBeHit()return PlayState.instance.judgeManager.judgeNote(this)!=UNJUDGED;
	
	
	// note type/customizable shit
	
	public var noteType(default, set):String = null;  // the note type
	public var causedMiss:Bool = false;

	public var usesDefaultColours:Bool = true; // whether this note uses the default note colours (lets you change colours in options menu)
	public var useRGBColors:Bool = true;

	public var blockHit:Bool = false; // whether you can hit this note or not
	#if PE_MOD_COMPATIBILITY
	public var lowPriority:Bool = false; // Unused. shadowmario's shitty workaround for really bad mine placement, yet still no *real* hitbox customization lol!
	#end
	@:isVar
	public var noteSplashDisabled(get, set):Bool = false; // disables the notesplash when you hit this note
	function get_noteSplashDisabled()
		return noteSplashBehaviour==DISABLED;
	function set_noteSplashDisabled(val:Bool){
		noteSplashBehaviour = val?DISABLED:DEFAULT;
		return val;
	}

	public var noteSplashBehaviour:SplashBehaviour = DEFAULT;
	public var noteSplashTexture:String = null; // spritesheet for the notesplash
	public var noteSplashHue:Float = 0; // hueshift for the notesplash, can be changed in note-type but otherwise its whatever the user sets in options
	public var noteSplashSat:Float = 0; // ditto, but for saturation
	public var noteSplashBrt:Float = 0; // ditto, but for brightness
	//public var ratingDisabled:Bool = false; // disables judging this note
	public var missHealth:Float = 0; // damage when hitCausesMiss = true and you hit this note	
	public var texture(default, set):String = null; // texture for the note
	public var noAnimation:Bool = false; // disables the animation for hitting this note
	public var noMissAnimation:Bool = false; // disables the animation for missing this note
	public var hitCausesMiss:Bool = false; // hitting this causes a miss
	public var breaksCombo:Bool = false; // hitting this will cause a combo break
	public var hitsoundDisabled:Bool = false; // hitting this does not cause a hitsound when user turns on hitsounds
	public var gfNote:Bool = false; // gf sings this note (pushes gf into characters array when the note is hit)
	public var characters:Array<Character> = []; // which characters sing this note, leave blank for the playfield's characters
	public var fieldIndex:Int = -1; // Used to denote which PlayField to be placed into
	// Leave -1 if it should be automatically determined based on mustPress and placed into either bf or dad's based on that.
	// Note that holds automatically have this set to their parent's fieldIndex
	public var field:PlayField; // same as fieldIndex but lets you set the field directly incase you wanna do that i  guess

	// custom health values
	public var ratingHealth:Map<String, Float> = [];

	// hold/roll shit
	public var sustainMult:Float = 1;
	public var tail:Array<Note> = []; 
	public var unhitTail:Array<Note> = [];
	public var parent:Note;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var holdingTime:Float = 0;
	public var tripTimer:Float = 0;
	public var isRoll:Bool = false;

	// event shit (prob can be removed??????)
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	// etc

	public var colorSwap:AmongUsColorSwapShader;
	public var inEditor:Bool = false;
	public var desiredZIndex:Float = 0;
	
	// do not tuch
	public var baseScaleX:Float = 1;
	public var baseScaleY:Float = 1;
	public var zIndex:Float = 0;
	public var z:Float = 0;
	public var realNoteData:Int;
	public static var swagWidth:Float = 160 * 0.7;
	
	
	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var pixelInt:Array<Int> = [0, 1, 2, 3];
	public var pixelNote:Bool = false;


	// mod manager
	public var garbage:Bool = false; // if this is true, the note will be removed in the next update cycle
	public var alphaMod:Float = 1;
	public var alphaMod2:Float = 1; // TODO: unhardcode this shit lmao
	public var typeOffsetX:Float = 0; // used to offset notes, mainly for note types. use in place of offset.x and offset.y when offsetting notetypes
	public var typeOffsetY:Float = 0;
	public var multSpeed(default, set):Float = 1;
	public var rawNoteData:Int = 0;
	// useless shit mostly
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick

	public var distance:Float = 2000; //plan on doing scroll directions soon -bb
	public static var defaultNotes = [
		'No Animation',
		'GF Sing',
		''
	];

	@:isVar
	public var isSustainEnd(get, null):Bool = false;
	public var holdParent:Bool=false;

	public function get_isSustainEnd():Bool
	{
		if (isSustainNote && animation != null && animation.curAnim != null && animation.curAnim.name != null && animation.curAnim.name.endsWith("end"))
			return true;

		return false;
	}

	private function set_multSpeed(value:Float):Float {
/* 		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value; */
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
/* 		if(isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			baseScaleY = scale.y;
			updateHitbox();
		} */
	}

	public var noteTypeTexture(default, set):String = null; // texture for the noteType
	private function set_noteTypeTexture(value:String):String {
		if(noteTypeTexture != value) {
			reloadNote('',value);
		}
		noteTypeTexture = value;
		return value;
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote(value);
		}
		texture = value;
		return value;
	}

	public function updateColours(ignore:Bool=false){		
		if(!ignore && !usesDefaultColours)return;
		if (colorSwap==null)return;
		if(isQuant){
			var idx = quants.indexOf(quant);
			colorSwap.red = ClientPrefs.quantColors[idx][0];
			colorSwap.blue = ClientPrefs.quantColors[idx][1];
			colorSwap.green = 0xffffff;
			colorSwap.active = true;
		}else{
			colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;

			if (useRGBColors)
			{
				colorSwap.red = ClientPrefs.coloumColors[noteData % 4][0];
				colorSwap.blue = ClientPrefs.coloumColors[noteData % 4][1];
				colorSwap.green = 0xffffff;
				colorSwap.active = true;
			}
		}

		if (noteScript != null && noteScript.scriptType == 'hscript')
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("onUpdateColours", [this], this);
		}
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;

		updateColours();

		// just to make sure they arent 0, 0, 0
		colorSwap.hue += 0.0127;
		colorSwap.saturation += 0.0127;
		colorSwap.brightness += 0.0127;
		var hue = colorSwap.hue;
		var sat = colorSwap.saturation;
		var brt = colorSwap.brightness;
		
		if(noteData > -1 && noteType != value) {
			noteScript = null;
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					noteTypeTexture = value;
					noteSplashTexture = 'HURTnoteSplashes';
					usesDefaultColours = false;
					useRGBColors = false;
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;

				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
				default:
					if (!inEditor && PlayState.instance != null)
						noteScript = PlayState.instance.notetypeScripts.get(value);
					else if(inEditor && ChartingState.instance!=null)
						noteScript = ChartingState.instance.notetypeScripts.get(value);
					
					if (noteScript != null && noteScript.scriptType == 'hscript')
					{
						var noteScript:FunkinHScript = cast noteScript;
						noteScript.executeFunc("setupNote", [this], this);
					}
						
			}
			noteType = value;
		}
		if(usesDefaultColours){
			if(colorSwap.hue != hue || colorSwap.saturation != sat || colorSwap.brightness != brt){
				usesDefaultColours = false;// just incase
			}
		}

		if(colorSwap.hue==hue)
			colorSwap.hue -= 0.0127;

		if(colorSwap.saturation==sat)
			colorSwap.saturation -= 0.0127;

		if(colorSwap.brightness==brt)
			colorSwap.brightness -= 0.0127;

		if (!useRGBColors)
			colorSwap.active = false;

		if (noteScript != null && noteScript.scriptType == 'hscript')
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("postSetupNote", [this], this);
		}

		if(isQuant){
			if (noteSplashTexture == 'noteSplashes' || noteSplashTexture == null || noteSplashTexture.length <= 0)
				noteSplashTexture = 'QUANTnoteSplashes'; // give it da quant notesplashes!!
			else if (Paths.exists(Paths.getPath("images/QUANT" + noteSplashTexture + ".png",
				IMAGE)) #if MODS_ALLOWED || Paths.exists(Paths.modsImages("QUANT" + noteSplashTexture)) #end)
				noteSplashTexture = 'QUANT${noteSplashTexture}';
		}

		if (isQuant && noteSplashTexture.startsWith("QUANT") || !isQuant){
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	public var style:String = '';

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?rollNote:Bool = false,?style = '', ?inEditor:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;
		
		this.prevNote = prevNote;
		this.style = style;
		isRoll = rollNote;
		isSustainNote = sustainNote;

		if (canQuant && ClientPrefs.noteSkin == 'Quants'){
			if(prevNote != null && isSustainNote)
				quant = prevNote.quant;
			else
				quant = getQuant(Conductor.getBeatInMeasure(strumTime));
		}
		beat = Conductor.getBeat(strumTime);
		this.inEditor = inEditor;

		x += PlayState.STRUM_X + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;
		if(!inEditor)visualTime = PlayState.instance.getNoteInitialTime(this.strumTime);

		this.noteData = noteData;

		var sustainType = 0;
		if(isSustainNote){
			sustainType=1;
			if(isRoll)sustainType=2;
		}

		if(noteData > -1) {
			texture = '';
			colorSwap = new AmongUsColorSwapShader();
			shader = colorSwap;

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData > -1 && noteData < 4) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % 4];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote!=null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			sustainMult = 0.5; // early hit mult but just so note-types can set their own and not have sustains fuck them
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			//if(ClientPrefs.downScroll) flipY = true;

			//offsetX += width* 0.5;
			copyAngle = false;

			prevNote.holdParent=true;
			switch (sustainType)
			{
				case 2:
					animation.play(colArray[noteData % 4] + 'rollend');
				case 1:
					animation.play(colArray[noteData % 4] + 'holdend');
			}

			updateHitbox();

			//offsetX -= width* 0.5;
			
			if (pixelNote)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				switch (sustainType)
				{
					case 2:
						prevNote.animation.play(colArray[prevNote.noteData % 4] + 'roll');
					case 1:
						prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.instance.songSpeed * 100;

				if (pixelNote)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}

				
				prevNote.updateHitbox();
				prevNote.defScale.copyFrom(prevNote.scale);
				// prevNote.setGraphicSize();
			}

			if (pixelNote)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		defScale.copyFrom(scale);
		//x += offsetX;
	}

	public static var quantShitCache = new Map<String, String>();
	var lastNoteScaleToo:Float = 1;
	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	public var originalHeightForCalcs:Float = 6;

	public function reloadNote(?texture:String = '', type:String = '')
	{
		if (texture == null)
			texture = '';

		if (noteScript != null && noteScript.scriptType == 'hscript')
		{
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.executeFunc("onReloadNote", [this, texture], this) == Globals.Function_Stop)
				return;
		}

		if(texture.length < 1) {
			if (texture == null || texture.length < 1)
			{
				texture = 'QUANTNOTE_assets';
			}
		}

		var animName:String = animation.curAnim != null ? animation.curAnim.name : null;
		var lastScaleY:Float = scale.y;

		var wasQuant = isQuant;
		isQuant = false;

		if (canQuant && ClientPrefs.noteSkin == 'Quants')
		{
			isQuant = true;
		}
		else
		{
			isQuant = false;
		}

		switch (style)
		{
			case 'pixel':
				if (isSustainNote)
				{
					loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets' + 'ENDS'));
					width = width / 4;
					height = height / 2;
					originalHeightForCalcs = height;
					loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets' + 'ENDS'), true, Math.floor(width), Math.floor(height));
				}
				else
				{
					loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'));
					width = width / 4;
					height = height / 5;
					loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'), true, Math.floor(width), Math.floor(height));
				}

				if (isSustainNote)
				{
					offsetX += lastNoteOffsetXForPixelAutoAdjusting;
					lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
					offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
				}

				loadPixelNoteAnims();

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

				antialiasing = false;
				useRGBColors = false;
				pixelNote = true;
			case 'tenzus':
				frames = Paths.getSparrowAtlas('noteSkin/tenzus_notes');
				loadNoteAnims();

				pixelNote = false;
				useRGBColors = false;
				antialiasing = ClientPrefs.globalAntialiasing;
			default:
				frames = Paths.getSparrowAtlas('noteSkin/QUANTNOTE_assets');
				loadNoteAnims();

				pixelNote = false;
				antialiasing = ClientPrefs.globalAntialiasing;
		}

		addCustomNote(type);

		if (wasQuant != isQuant)
			updateColours();
		
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		defScale.copyFrom(scale);
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor){
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}

		if (noteScript != null && noteScript.scriptType == 'hscript')
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("postReloadNote", [this,texture], this);
		}
	}
	public function loadNoteAnims() {
		if (noteScript != null && noteScript.scriptType == 'hscript'){
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.exists("loadNoteAnims") && Reflect.isFunction(noteScript.get("loadNoteAnims"))){
				noteScript.executeFunc("loadNoteAnims", [this], this, ["super" => _loadNoteAnims]);
				return;
			}
		}
		_loadNoteAnims();
	}

	function _loadNoteAnims() {
		switch (texture)
		{
			default:
				animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

				if (isSustainNote)
				{
					animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?????
					animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
					animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
				}
		
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
		}
	}
	function addCustomNote(type:String) {
		switch (type)
		{
			case 'Hurt Note':
				frames = Paths.getSparrowAtlas('noteType/HURTNOTE_assets');
				loadNoteAnims();

				pixelNote = false;
				antialiasing = ClientPrefs.globalAntialiasing;
		}

		if (noteScript != null && noteScript.scriptType == 'hscript'){
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.exists("loadNoteTypeAnims") && Reflect.isFunction(noteScript.get("loadNoteTypeAnims"))){
				noteScript.executeFunc("loadNoteTypeAnims", [this, type], this);
			}
		}
	}

	function loadPixelNoteAnims()
		{
			if (isSustainNote)
			{
				animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
				animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
			}
			else
			{
				animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
			}
		}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

/* 		if (isSustainNote)
		{
			if (prevNote != null && prevNote.isSustainNote)
				zIndex = z + prevNote.zIndex;
			
			else if (prevNote != null && !prevNote.isSustainNote)
				zIndex = z + prevNote.zIndex - 1;
			
		}
		else
			zIndex = z;
		

		zIndex += desiredZIndex;
		zIndex -= (mustPress == true ? 0 : 1); */

		if(!inEditor){
			if (noteScript != null && noteScript.scriptType == 'hscript'){
				var noteScript:FunkinHScript = cast noteScript;
				noteScript.executeFunc("noteUpdate", [elapsed], this);
			}
		}
		
		//colorSwap.daAlpha = alphaMod * alphaMod2;
		
		if (hitByOpponent)
			wasGoodHit = true;
		var diff = (strumTime - Conductor.songPosition);
		if (diff < -Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
