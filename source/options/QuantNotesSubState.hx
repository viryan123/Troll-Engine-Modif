// while this CAN be apart of NotesSubState
// fuck you
package options;

import flixel.addons.plugin.taskManager.FlxTask;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import shaders.AmongUsShader;
import flixel.math.FlxPoint;

using StringTools;

class QuantNotesSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var grpQuants:FlxTypedGroup<AttachedText>;
	private var shaderArray:Array<AmongUsShader> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var presetsText:FlxText;

	var posX = 230;

	public static var quantColors:Array<Array<Int>> = [
		[0xf9393f, 0x651038], // 4th
		[0x00ffff, 0x004a54], // 8th
		[0xc24b99, 0x3c1f56], // 12th
		[0x12fa05, 0x034415], // 16th

		[0x00ff9d, 0x1580b7], // 20th
		[0xfc73bc, 0x630800], // 24th
		[0xff5c1f, 0x690f3d], // 32nd
		[0x005eff, 0x0d2d73], // 48th

		[0x737373, 0x2e2e2e], // 64th
		[0x00ff9d, 0x1580b7], // 96th
		[0x00ff9d, 0x1580b7], // 192nd
	];

	public static var quantizations:Array<String> = [
		"4th",
		"8th",
		"12th",
		"16th",
		"20th",
		"24th",
		"32nd",
		"48th",
		"64th",
		"96th",
		"192nd"
	];

	var daCam:FlxCamera;
	var cambg:FlxCamera;
	var spacing:Float = 200;
	var off:Float = 250;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var origCamFollow:FlxPoint = new FlxPoint();
	var bg:FlxSprite;
	public function new() {
		super();

		cambg = new FlxCamera();
		cambg.bgColor.alpha = 0;
		FlxG.cameras.add(cambg, false);

		daCam = new FlxCamera();
		daCam.bgColor.alpha = 0;
		FlxG.cameras.add(daCam, false);
		
		origCamFollow.copyFrom(daCam.scroll);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);


		var backdrop = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		backdrop.setGraphicSize(FlxG.width, FlxG.height);
		backdrop.updateHitbox();
		backdrop.screenCenter(XY);
		backdrop.alpha = 0.5;
		add(backdrop);

		blackBG = new FlxSprite(posX - 25).makeGraphic(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		bg = new FlxSprite().loadGraphic(Paths.image('menuBGMagenta'));
		//bg.color = 0xFF09F25E;
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 0.6));
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.active = false;
		//add(bg);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpQuants = new FlxTypedGroup<AttachedText>();
		add(grpQuants);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		daCam.follow(camFollowPos, null, 1);

		var optionText:Alphabet;
		var quantAngles = [0, 90, 270, 180];
		var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
		for (i in 0...ClientPrefs.quantColors.length) {
			var yPos:Float = (165 * i) + 35;
			yPos = (195 * i) + 35;
			for (j in 0...6) {
				var set = ClientPrefs.quantColors[i];
				var color:FlxColor = set[Std.int(j/3)];
				var text = [color.red, color.green, color.blue][j%3];
				optionText = new Alphabet(0, yPos + 60 - 20 + (70 * Std.int(j/3)), Std.string(text), true);
				optionText.x = posX + (spacing * (j % 3)) + off;
				updateOffset(optionText, text);
				grpNumbers.add(optionText);
			}


			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('noteSkin/QUANTNOTE_assets');
			var txt:AttachedText = new AttachedText(quantizations[i], 0, 0, true);
			txt.sprTracker = note;
			txt.copyAlpha=true;
			add(txt);
			note.animation.addByPrefix('idle', animations[i % 4]);
			note.animation.play('idle');
			note.angle = quantAngles[i % 4];
			note.antialiasing = ClientPrefs.globalAntialiasing;
			grpNotes.add(note);

			var newShader:AmongUsShader = new AmongUsShader();
			note.shader = newShader;
			newShader.red = ClientPrefs.quantColors[i][0];
			newShader.green = 0xffffff;
			newShader.blue = ClientPrefs.quantColors[i][1];
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(0, 0, "R       G       B", false, false, 0, 0.65);
		hsbText.x = posX + 240;
		add(hsbText);

		presetsText = new FlxText(10, FlxG.height - 120, 200, "Press ALT for presets", 20);
		presetsText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		presetsText.scrollFactor.set(0, 0);
		presetsText.active = false;
		add(presetsText);

		changeSelection();

		camFollowPos.setPosition(camFollow.x, camFollow.y);

		cameras = [daCam];

		backdrop.cameras = [cambg];
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				var perNums = 6;
				for (i in 0...perNums) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				presetsText.visible = false;
				var perNums = 6;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * perNums) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}

			if(presetsText.visible) {
				if(FlxG.keys.justPressed.ALT) {
					openSubState(new NotesPresetSubSubState());
				}
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			if(!changingNote) {
				camFollowPos.setPosition(origCamFollow.x, origCamFollow.y);
				daCam.follow(null, null, 1);
				daCam.scroll.copyFrom(origCamFollow);
				FlxG.cameras.remove(daCam);
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}

		/*for(i in 0...grpNotes.length){
			var yIndex = i;
			var item = grpNotes.members[i];
			if(curSelected>2)
				yIndex -= curSelected - 2;

			var lerpVal:Float = 0.4 * (elapsed / (1/120) );

			var yPos:Float = (165 * yIndex) + 35;

			item.y = FlxMath.lerp(item.y, yPos, lerpVal);
			if(i == curSelected){
				hsbText.y = FlxMath.lerp(hsbText.y, yPos-70, lerpVal);
				blackBG.y = FlxMath.lerp(blackBG.y, yPos-20, lerpVal);
			}
		}*/

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		if(!FlxG.keys.pressed.SHIFT) {
			if(change > 0) {
				if(typeSelected < 3) {
					changeType(3);
					return;
				} else {
					changeType(-3);
				}
			} else if(change < 0) {
				if(typeSelected >= 3) {
					changeType(-3);
					return;
				} else {
					changeType(3);
				}
			}
		}
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.quantColors.length-1;
		if (curSelected >= ClientPrefs.quantColors.length)
			curSelected = 0;

		var set = ClientPrefs.quantColors[curSelected];
		var color:FlxColor = set[Std.int(typeSelected/3)];

		curValue = [color.red, color.green, color.blue][typeSelected%3];
		updateValue();

		var perNums = 6;

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];

			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70 - (10);
				blackBG.y = item.y - 20;

				camFollow.setPosition(FlxG.width / 2, item.getGraphicMidpoint().y);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		var perNums = 6;
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = perNums-1;
		if (typeSelected > perNums-1)
			typeSelected = 0;

		var set = ClientPrefs.quantColors[curSelected];
		var color:FlxColor = set[Std.int(typeSelected/3)];

		curValue = [color.red, color.green, color.blue][typeSelected%3];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		var rbI = Std.int(type/3);
		var color:FlxColor = quantColors[selected][rbI];
		curValue = [color.red, color.green, color.blue][type%3];

		var red:FlxColor = ClientPrefs.quantColors[selected][0];
		var blue:FlxColor = ClientPrefs.quantColors[selected][1];

		var rounded = Math.round(curValue);

		trace(color.red, color.green, color.blue);

		switch(type) {
			case 0: red.red = rounded;
			case 1: red.green = rounded;
			case 2: red.blue = rounded;
			case 3: blue.red = rounded;
			case 4: blue.green = rounded;
			case 5: blue.blue = rounded;
		}

		trace(color.red, color.green, color.blue);

		ClientPrefs.quantColors[selected] = [red, blue];

		shaderArray[selected].red = ClientPrefs.quantColors[selected][0];
		shaderArray[selected].green = 0xffffff;
		shaderArray[selected].blue = ClientPrefs.quantColors[selected][1];

		var perNums = 6;
		var item = grpNumbers.members[(selected * perNums) + type];
		item.changeText(Std.string(curValue));
		updateOffset(item, Std.int(curValue));
	}

	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 255;
		var min:Float = 0;

		if(roundedValue < min) {
			curValue = min;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		var red:FlxColor = ClientPrefs.quantColors[curSelected][0];
		var blue:FlxColor = ClientPrefs.quantColors[curSelected][1];

		//var currentColor:FlxColor = ClientPrefs.quantColors[curSelected][Std.int(typeSelected/3)];

		switch(typeSelected) {
			case 0: red.red = roundedValue;
			case 1: red.green = roundedValue;
			case 2: red.blue = roundedValue;
			case 3: blue.red = roundedValue;
			case 4: blue.green = roundedValue;
			case 5: blue.blue = roundedValue;
		}

		ClientPrefs.quantColors[curSelected] = [red, blue];

		shaderArray[curSelected].red = red;
		shaderArray[curSelected].green = 0xffffff;
		shaderArray[curSelected].blue = blue;

		var perNums = 6;
		var item = grpNumbers.members[(curSelected * perNums) + typeSelected];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1))* 0.5;
		if(roundedValue < 0) item.offset.x += 10;
	}

	function updateOffset(alph:Alphabet, value:Int) {
		alph.offset.x = (40 * (alph.lettersArray.length - 1)) / 2;
		if(value < 0) alph.offset.x += 10;
	}
}
