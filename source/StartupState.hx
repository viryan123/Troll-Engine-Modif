import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.events.KeyboardEvent;
import sys.FileSystem;
import Github.Release;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;

#if desktop
import Discord.DiscordClient;
import lime.app.Application;
#end

using StringTools;

// Loads the title screen, alongside some other stuff.

class StartupState extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	static var loaded = false;
	static var recentRelease:Release;

	static function clearTemps(dir:String){
		for(file in FileSystem.readDirectory(dir)){
			var file = './$dir/$file';
			if(FileSystem.isDirectory(file))
				clearTemps(file);
			else if (file.endsWith(".tempcopy"))
				FileSystem.deleteFile(file);
		}
	}
	public static function load():Void
	{
		if (loaded)
			return;
		loaded = true;

		#if html5
		Paths.initPaths();
		#end
		#if hscript
		scripts.FunkinHScript.init();
		#end
		
		#if MODS_ALLOWED
		Paths.getModDirectories();
		Paths.loadRandomMod();
		#end
		
		PlayerSettings.init();
		
		Highscore.load();

		FlxTransitionableState.defaultTransIn = FadeTransitionSubstate;
		FlxTransitionableState.defaultTransOut = FadeTransitionSubstate;
		
		// this shit doesn't work
		#if desktop
		Paths.sound("cancelMenu");
		Paths.sound("confirmMenu");
		Paths.sound("scrollMenu");

		Paths.music('freakyIntro');
		Paths.music('freakyMenu');
		#end

		ClientPrefs.initialize();
		ClientPrefs.load();

		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.showFPS;

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		getRecentGithubRelease();
		clearTemps("./");
		
		#if desktop
		if (!DiscordClient.isInitialized){
			DiscordClient.initialize();
			Application.current.onExit.add(function(exitCode)
			{
				DiscordClient.shutdown();
			});
		}
		#end
	}


	#if DO_AUTO_UPDATE
	// gets the most recent release and returns it
	// if you dont have download betas on, then it'll exclude prereleases
	public static function getRecentGithubRelease(){
		if (ClientPrefs.checkForUpdates)
		{
			var github:Github = new Github(); // leaving the user and repo blank means it'll derive it from the repo the mod is compiled from
			// if it cant find the repo you compiled in, it'll just default to troll engine's repo
			recentRelease = github.getReleases((release:Release) ->
			{
				return (Main.downloadBetas || !release.prerelease);
			})[0];
			if (FlxG.save.data.ignoredUpdates == null)
			{
				FlxG.save.data.ignoredUpdates = [];
				FlxG.save.flush();
			}
			if (recentRelease != null && FlxG.save.data.ignoredUpdates.contains(recentRelease.tag_name))
				recentRelease = null;
			Main.recentRelease = recentRelease;
			
		}else{
			Main.recentRelease = null;
			Main.outOfDate = false;
		}
		return Main.recentRelease;
	}
	#else
	public static function getRecentGithubRelease()
	{
		Main.recentRelease = null;
		Main.outOfDate = false;
		return null;
	}
	#end


	public function new(){
		super();

		persistentDraw = true;
		persistentUpdate = true;

		FlxG.fixedTimestep = false;

		#if (windows || linux) // I have no idea if this also applies to other targets
		FlxG.stage.addEventListener(
			KeyboardEvent.KEY_DOWN, 
			(e)->{
				// Prevent flixel from listening to key inputs when switching fullscreen mode
				if (e.keyCode == FlxKey.ENTER && e.altKey)
					e.stopImmediatePropagation();

				// Also add F11 to switch fullscreen mode :D
				if (e.keyCode == FlxKey.F11){
					FlxG.fullscreen = !FlxG.fullscreen;
					e.stopImmediatePropagation();
				}
			}, 
			false, 
			100
		);
		#end
	}

	var warnText:FlxText;
	private var step = 0;

	override function update(elapsed)
	{
		// this is kinda stupid but i couldn't find any other way to display the warning while the title screen loaded 
		// could be worse lol
 		switch (step){
			case 0:
				warnText = new FlxText(0, 0, FlxG.width,
					"Hey, watch out!\n
					This Mod contains some flashing lights!\n
					You can disable them in the Options Menu.\n
					You've been warned!",
					32);
				warnText.setFormat(Paths.font('Normal Text.ttf'), 32, FlxColor.WHITE, CENTER);
				warnText.screenCenter(Y);
				add(warnText);

				//MusicBeatState.switchState(new editors.StageBuilderState());
				step = 1;
			case 1:
 				load();
				TitleState.load();
				
				var waitTime = 1.5 - Sys.cpuTime();
				if (waitTime > 0) Sys.sleep(waitTime);
				
				step = 2;
			case 2:
 				FlxTween.tween(warnText, {alpha: 0}, 1, {ease: FlxEase.expoIn, onComplete: function(twn){
					#if DO_AUTO_UPDATE
					// this seems to work?
					if (Main.checkOutOfDate())
						MusicBeatState.switchState(new UpdaterState(recentRelease)); // UPDATE!!
					else
					#end
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;
						MusicBeatState.switchState(new TitleState());
					}	
				}});
				step = 3; 

		}

		super.update(elapsed);
	}
}