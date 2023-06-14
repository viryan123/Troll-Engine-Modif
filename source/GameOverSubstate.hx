package;

import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public static var instance:GameOverSubstate;

	public var boyfriend:Boyfriend;
	public var deathSound:FlxSound;

	public var defaultCamZoom:Float = 1;

	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	public var updateCamera:Bool = false;

	public static var characterName:String = null;
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	// for bowser or tankman or whatever
	public static var voicelineNumber:Null<Int> = null; // set this value to play an specific voiceline (otherwise it will be randomly chosen using the voicelineAmount value)
	public static var voicelineAmount:Int = 0; // how many voicelines exist.
	public static var voicelineName:Null<String> = null; // if set to null then it will just use the character name
	// nvm maybe ill use this next time

	public static function resetVariables() {
		characterName = null;
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		voicelineNumber = null;
		voicelineAmount = 0;
		voicelineName = null;
	}

	override function create()
	{
		instance = this;

		PlayState.instance.callOnScripts('onGameOverStart', []);
		super.create();
	}

	function doGenericGameOver()
	{
		Conductor.changeBPM(100);
		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float, ?isPlayer:Bool)
	{
		super();

		var game = PlayState.instance;

		game.setOnScripts('inGameOver', true);

		game.inst.volume = 0;
		game.inst.stop();
		game.vocals.volume = 0;
		game.vocals.stop();

		Conductor.songPosition = 0;

		var deathName:String = characterName;

		if (deathName == null){
			var character = game.playOpponent ? game.dad : game.boyfriend;
			if (character != null) deathName = character.deathName + "-dead";
		}

		var charInfo = deathName == null ? null : Character.getCharacterFile(deathName);
		
		Cache.loadWithList([
			{path: charInfo.image, type: 'IMAGE'},
			{path: deathSoundName, type: 'SOUND'},
			{path: loopSoundName, type: 'MUSIC'},
			{path: endSoundName, type: 'MUSIC'}
		]);
		
		boyfriend = new Boyfriend(x, y, deathName, isPlayer);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);
		
		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
		
		deathSound = FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width* 0.5), FlxG.camera.scroll.y + (FlxG.camera.height* 0.5));
		add(camFollowPos);

		if (PlayState.instance != null && PlayState.instance.stage != null)
			defaultCamZoom = PlayState.instance.stage.stageData.defaultZoom;
		else
			defaultCamZoom = FlxG.camera.zoom;
	}

	var isFollowingAlready:Bool = false;
	var isEnding:Bool = false;

	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultCamZoom, CoolUtil.boundTo(elapsed * 2.2, 0, 1));
		}	

		if (controls.ACCEPT && !isEnding)
		{
			isEnding = true;

			if (boyfriend != null)
				boyfriend.playAnim('deathConfirm', true);
			
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, ()->{
					return MusicBeatState.resetState();
				});
			});

			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}

		if (controls.BACK)
		{
			isEnding = true;

			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			MusicBeatState.playMenuMusic(true);
		}

		if (!isEnding && boyfriend != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished)
			{
				FlxG.sound.playMusic(Paths.music(loopSoundName), 1);
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
		
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();
	}
}