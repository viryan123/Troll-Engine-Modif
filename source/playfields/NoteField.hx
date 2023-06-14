package playfields;

import modchart.Modifier;
import flixel.math.FlxPoint;
import openfl.geom.ColorTransform;
import flixel.graphics.FlxGraphic;
import openfl.display.Shader;
import flixel.math.FlxMath;
import math.Vector3;
import flixel.system.FlxAssets.FlxShader;
import modchart.ModManager;
import openfl.Vector;
import flixel.util.FlxSort;
import flixel.math.FlxAngle;

using StringTools;

typedef RenderObject =
{
	graphic:FlxGraphic,
	shader:Shader,
	alphas:Array<Float>,
	glows:Array<Float>,
	uvData:Vector<Float>,
	vertices:Vector<Float>,
	zIndex:Float,
}

class NoteField extends FieldBase
{
	var smoothHolds = true; // ClientPrefs.coolHolds;

	public var holdSubdivisions:Int = Std.int(ClientPrefs.holdSubdivs) + 1;
	public var optimizeHolds = ClientPrefs.optimizeHolds;

	public function new(field:PlayField, modManager:ModManager)
	{
		super(0, 0);
		this.field = field;
		this.modManager = modManager;
	}

	/*
	 * The Draw Distance Modifier
	 * Multiplied by the draw distance to determine at what time a note will start being drawn
	 * Set to ClientPrefs.drawDistanceModifier by default, which is an option to let you change the draw distance.
	 * Best not to touch this, as you can set the drawDistance modifier to set the draw distance of a notefield.
	 */
	public var drawDistMod:Float = ClientPrefs.drawDistanceModifier;

	/*
	 * The ID used to determine how you apply modifiers to the notes
	 * For example, you can have multiple notefields sharing 1 set of mods by giving them all the same modNumber
	 */
	public var modNumber(default, set):Int = 0;
	function set_modNumber(d:Int){
		modManager.getActiveMods(d); // generate an activemods thing if needed
		return modNumber = d;
	}

	/*
	 * The PlayField used to determine the notes to render
	 * Required!
	 */
	public var field:PlayField;

	/*
	 * The ModManager to be used to get modifier positions, etc
	 * Required!
	 */
	public var modManager:ModManager;

	/*
	 * The song's scroll speed. Can be messed with to give different fields different speeds, etc.
	 */
	public var songSpeed:Float = 1.6;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	/*
	 * The position of every receptor for a given frame.
	 */
	public var strumPositions:Array<Vector3> = [];

    /*
	 * Used by preDraw to store RenderObjects to be drawn
    */
	@:allow(proxies.ProxyField)
    var drawQueue:Array<RenderObject> = [];

	// does all the drawing logic, best not to touch unless you know what youre doing
    override function preDraw()
    {
		drawQueue = [];
        if(!active || !exists)return;
		if ((FlxG.state is MusicBeatState))
		{
			var state:MusicBeatState = cast FlxG.state;
			@:privateAccess
			curDecStep = state.curDecStep;
		}
		else
		{
			var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
			var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
			curDecStep = lastChange.stepTime + shit;
		}
		curDecBeat = curDecStep / 4;

		var notePos:Map<Note, Vector3> = [];
		var taps:Array<Note> = [];
		var holds:Array<Note> = [];
		var drawMod = modManager.get("drawDistance");
		var drawDist = drawMod == null ? FlxG.height : drawMod.getValue(modNumber);
		drawDist *= drawDistMod;
		for (daNote in field.spawnedNotes)
		{
			if (!daNote.alive)
				continue;

			if (songSpeed != 0)
			{
				var speed = songSpeed * daNote.multSpeed * modManager.getValue("xmod", modNumber);
				var diff = Conductor.songPosition - daNote.strumTime;
				var visPos = -((Conductor.visualPosition - daNote.visualTime) * speed);
				if (visPos > drawDist)
					continue;
				if (daNote.wasGoodHit && daNote.tail.length > 0 && daNote.unhitTail.length > 0)
				{
					diff = 0;
					visPos = 0;
					continue; // stops it from drawing lol
				}
				if (!daNote.isSustainNote)
				{
					var pos = modManager.getPos(visPos, diff, curDecBeat, daNote.noteData, modNumber, daNote, ['perspectiveDONTUSE'],
						daNote.vec3Cache); // perspectiveDONTUSE is excluded because its code is done in the modifyVert function
					notePos.set(daNote, pos);
					taps.push(daNote);
				}
				else
				{
					holds.push(daNote);
				}
			}
		}

		var lookupMap:Map<Any, RenderObject> = [];

		// draw the receptors
		for (obj in field.strumNotes)
		{
			if (!obj.alive || !obj.visible)
				continue;
			var pos = modManager.getPos(0, 0, curDecBeat, obj.noteData, modNumber, obj, ['perspectiveDONTUSE'], obj.vec3Cache);
			strumPositions[obj.noteData] = pos;
			var object = drawNote(obj, pos);
			if (object == null)
				continue;
			object.zIndex += (obj.animation != null && obj.animation.curAnim != null && obj.animation.curAnim.name == 'confirm') ? 1 : 0;

			lookupMap.set(obj, object);
			drawQueue.push(object);
		}

		// draw tap notes
		for (note in taps)
		{
			if (!note.alive || !note.visible)
				continue;
			var object = drawNote(note, notePos.get(note));
			if (object == null)
				continue;
			object.zIndex = notePos.get(note).z + note.zIndex;
			lookupMap.set(note, object);
			drawQueue.push(object);
		}

		// draw hold notes (credit to 4mbr0s3 2)
		for (note in holds)
		{
			if (!note.alive || !note.visible)
				continue;
			var object = drawHold(note);
			if (object == null)
				continue;
			object.zIndex -= 1;
			lookupMap.set(note, object);
			drawQueue.push(object);
		}

		// draw notesplashes
		for (obj in field.grpNoteSplashes.members)
		{
			if (!obj.alive || !obj.visible)
				continue;
			var pos = modManager.getPos(0, 0, curDecBeat, obj.noteData, modNumber, obj, ['perspectiveDONTUSE']);
			var object = drawNote(obj, pos);
			if (object == null)
				continue;
			object.zIndex += 2;
			lookupMap.set(obj, object);
			drawQueue.push(object);
		}

		// draw strumattachments
		for (obj in field.strumAttachments.members)
		{
			if (obj == null)
				continue;
			if (!obj.alive || !obj.visible)
				continue;
			var pos = modManager.getPos(0, 0, curDecBeat, obj.noteData, modNumber, obj, ['perspectiveDONTUSE']);
			var object = drawNote(obj, pos);
			if (object == null)
				continue;
			object.zIndex += 2;
			lookupMap.set(obj, object);
			drawQueue.push(object);
		}

		if ((FlxG.state is PlayState))
			PlayState.instance.callOnHScripts("playfieldPreDraw", [this],
				["drawQueue" => drawQueue, "lookupMap" => lookupMap]); // lets you do custom rendering in scripts, if needed
		// one example would be reimplementing Die Batsards' original bullet mechanic
		// if you need an example on how this all works just look at the tap note drawing portion

		drawQueue.sort(function(Obj1:RenderObject, Obj2:RenderObject)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
		});

    }

	override function draw()
	{
		if (!active || !exists || !visible)
			return; // dont draw if visible = false
		super.draw();

		if ((FlxG.state is PlayState))
			PlayState.instance.callOnHScripts("playfieldDraw", [this],
				["drawQueue" => drawQueue]); // lets you do custom rendering in scripts, if needed

		var glowR = modManager.getValue("flashR", modNumber);
		var glowG = modManager.getValue("flashG", modNumber);
		var glowB = modManager.getValue("flashB", modNumber);

		// actually draws everything
		if (drawQueue.length > 0)
		{
			for (object in drawQueue)
			{
				if (object == null)
					continue;
				var shader:Dynamic = object.shader;
				var graphic:FlxGraphic = object.graphic;
				var alphas = object.alphas;
				var glows = object.glows;
				var vertices = object.vertices;
				var uvData = object.uvData;
				var indices = new Vector<Int>(vertices.length, false, cast [for (i in 0...vertices.length) i]);

				var transforms:Array<ColorTransform> = [];
				for (n in 0... Std.int(vertices.length / 3)){
					var glow = glows[n];
					var transfarm:ColorTransform = new ColorTransform();
					transfarm.redMultiplier = 1 - glow;
					transfarm.greenMultiplier = 1 - glow;
					transfarm.blueMultiplier = 1 - glow;
					transfarm.redOffset = glowR * glow * 255;
					transfarm.greenOffset = glowG * glow * 255; 
					transfarm.blueOffset = glowB * glow * 255;

					transfarm.alphaMultiplier = alphas[n] * this.alpha;
					transforms.push(transfarm);
				}

				for (camera in cameras)
				{
					if (camera != null && camera.canvas != null && camera.canvas.graphics != null)
					{
						if (camera.alpha == 0 || !camera.visible)
							continue;
						for(shit in transforms)
							shit.alphaMultiplier *= camera.alpha;

						var drawItem = camera.startTrianglesBatch(graphic, shader.bitmap.filter == 4, true, null, true, shader);

						drawItem.addTrianglesColorArray(vertices, indices, uvData, null, FlxPoint.weak(x, y), null, transforms);
						for (n in 0...transforms.length)
							transforms[n].alphaMultiplier = alphas[n];
					}
				}
			}
		}
	}

	function getPoints(hold:Note, ?wid:Float, vDiff:Float, diff:Float)
	{ // stolen from schmovin'
		if (wid == null)
			wid = hold.frameWidth * hold.scale.x;
		var speed = songSpeed * hold.multSpeed * modManager.getValue("xmod", modNumber);

		var p1 = modManager.getPos(-(vDiff) * speed, diff, curDecBeat, hold.noteData, modNumber, hold, []);
		var z:Float = p1.z;
		p1.z = 0;
		var quad = [new Vector3((-wid / 2)), new Vector3((wid / 2))];
		var scale:Float = 1;
		if (z != 0)
			scale = z;

		if (optimizeHolds)
		{
			// less accurate, but higher FPS
			quad[0].scaleBy(1 / scale);
			quad[1].scaleBy(1 / scale);
			return [p1.add(quad[0]), p1.add(quad[1]), p1];
		}

		var p2 = modManager.getPos(-(vDiff + 1) * speed, diff + 1, curDecBeat, hold.noteData, modNumber, hold, []);
		p2.z = 0;
		var unit = p2.subtract(p1);
		unit.normalize();

		var w = (quad[0].subtract(quad[1]).length / 2) / scale;

		var off1 = new Vector3(unit.y, -unit.x);
		var off2 = new Vector3(-unit.y, unit.x);
		off1.scaleBy(w);
		off2.scaleBy(w);
		return [p1.add(off1), p1.add(off2), p1];
	}

	var crotchet = Conductor.getCrotchetAtTime(0) / 4;

	function drawHold(hold:Note, ?prevAlpha:Float, ?prevGlow:Float):Null<RenderObject>
	{
		if (hold.animation.curAnim == null)
			return null;
		if (hold.scale == null)
			return null;

		var verts = [];
		var uv = [];
		var alphas:Array<Float> = [];
		var glows:Array<Float> = [];

		var render = false;
		for (camera in cameras)
		{
			if (camera.alpha > 0 && camera.visible)
			{
				render = true;
				break;
			}
		}
		if (!render)
			return null;
		var lastMe = null;

		var tWid = hold.frameWidth * hold.scale.x;
		var bWid = (function()
		{
			if (hold.prevNote != null && hold.prevNote.scale != null && hold.prevNote.isSustainNote)
				return hold.prevNote.frameWidth * hold.prevNote.scale.x;
			else
				return tWid;
		})();

		var basePos = modManager.getPos(0, 0, curDecBeat, hold.noteData, modNumber, hold, ['perspectiveDONTUSE']);

		var strumDiff = (Conductor.songPosition - hold.strumTime);
		var visualDiff = (Conductor.visualPosition - hold.visualTime); // TODO: get the start and end visualDiff and interpolate so that changing speeds mid-hold will look better
		var zIndex:Float = basePos.z;
		var sv = PlayState.instance.getSV(hold.strumTime).speed;
		var scalePoint = FlxPoint.weak(1, 1);
		for (sub in 0...holdSubdivisions)
		{
			var prog = sub / (holdSubdivisions + 1);
			var nextProg = (sub + 1) / (holdSubdivisions + 1);
			var strumSub = crotchet / holdSubdivisions;
			var strumOff = (strumSub * sub);
			strumOff *= sv;
			strumSub *= sv;
			var scale:Float = 1;
			var fuck = strumDiff;

			if ((hold.wasGoodHit || hold.parent.wasGoodHit) && !hold.tooLate)
			{
				scale = 1 - ((fuck + crotchet) / crotchet);
				if (scale < 0)
					scale = 0;
				if (scale > 1)
					scale = 1;
				strumSub *= scale;
				strumOff *= scale;
			}

			var topWidth = FlxMath.lerp(tWid, bWid, prog) * scalePoint.x;
			var botWidth = FlxMath.lerp(tWid, bWid, nextProg) * scalePoint.x;

			scalePoint.set(1, 1);

			var speed = songSpeed * hold.multSpeed * modManager.getValue("xmod", modNumber);

			var info:RenderInfo = modManager.getExtraInfo((visualDiff + ((strumOff + strumSub) * 0.45)) * -speed,  strumDiff + strumOff + strumSub, curDecBeat, {
				alpha: hold.alpha,
				glow: 0,
				scale: scalePoint
			}, hold, modNumber, hold.noteData);

			for (_ in 0...4)
			{
				alphas.push(info.alpha);
				glows.push(info.glow);
			}

			var top = lastMe == null ? getPoints(hold, topWidth, (visualDiff + (strumOff * 0.45)), strumDiff + strumOff) : lastMe;
			var bot = getPoints(hold, botWidth, (visualDiff + ((strumOff + strumSub) * 0.45)), strumDiff + strumOff + strumSub);

			lastMe = bot;

			var quad:Array<Vector3> = [top[0], top[1], bot[0], bot[1]];

			verts = verts.concat([
				quad[0].x, quad[0].y,
				quad[1].x, quad[1].y,
				quad[3].x, quad[3].y,

				quad[0].x, quad[0].y,
				quad[2].x, quad[2].y,
				quad[3].x, quad[3].y
			]);
			uv = uv.concat(getUV(hold, false, sub));
		}

		var vertices = new Vector<Float>(verts.length, false, cast verts);
		var uvData = new Vector<Float>(uv.length, false, uv);

		var shader = hold.shader != null ? hold.shader : new FlxShader();
		if (shader != hold.shader)
			hold.shader = shader;

		shader.bitmap.input = hold.graphic.bitmap;
		shader.bitmap.filter = hold.antialiasing ? LINEAR : NEAREST;

		return {
			graphic: hold.graphic,
			shader: shader,
			alphas: alphas,
			glows: glows,
			uvData: uvData,
			vertices: vertices,
			zIndex: zIndex
		}
	}

	private function getUV(sprite:FlxSprite, flipY:Bool, sub:Int)
	{
		// i cant be bothered
		// code by 4mbr0s3 2 (Schmovin')
		var leftX = sprite.frame.frame.left / sprite.graphic.bitmap.width;
		var topY = sprite.frame.frame.top / sprite.graphic.bitmap.height;
		var rightX = sprite.frame.frame.right / sprite.graphic.bitmap.width;
		var height = sprite.frame.frame.height / sprite.graphic.bitmap.height;

		if (!flipY)
			sub = (holdSubdivisions - 1) - sub;
		var uvSub = 1.0 / holdSubdivisions;
		var uvOffset = uvSub * sub;
		if (flipY)
		{
			return [
				 leftX,           topY + uvOffset * height,
				rightX,           topY + uvOffset * height,
				rightX, topY + (uvOffset + uvSub) * height,
				 leftX,           topY + uvOffset * height,
				 leftX, topY + (uvOffset + uvSub) * height,
				rightX, topY + (uvOffset + uvSub) * height
			];
		}
		return [
			 leftX, topY + (uvSub + uvOffset) * height,
			rightX, topY + (uvSub + uvOffset) * height,
			rightX,           topY + uvOffset * height,
			 leftX, topY + (uvSub + uvOffset) * height,
			 leftX,           topY + uvOffset * height,
			rightX,           topY + uvOffset * height
		];
	}

	function drawNote(sprite:NoteObject, pos:Vector3):Null<RenderObject>
	{
		if (!sprite.visible || !sprite.alive)
			return null;

		var render = false;
		for (camera in cameras)
		{
			if (camera.alpha > 0 && camera.visible)
			{
				render = true;
				break;
			}
		}
		if (!render)
			return null;

		var width = sprite.frameWidth * sprite.scale.x;
		var height = sprite.frameHeight * sprite.scale.y;
		var scalePoint = FlxPoint.weak(1, 1);
		var diff:Float =0;
		var visPos:Float = 0;
		if((sprite is Note)){
			var daNote:Note = cast sprite;
			var speed = songSpeed * daNote.multSpeed * modManager.getValue("xmod", modNumber);
			diff = Conductor.songPosition - daNote.strumTime;
			visPos = -((Conductor.visualPosition - daNote.visualTime) * speed);
		}

		var info:RenderInfo = modManager.getExtraInfo(visPos, diff, curDecBeat, {
			alpha: sprite.alpha,
			glow: 0,
			scale: scalePoint
		}, sprite, modNumber, sprite.noteData);

		var alpha = info.alpha;
		var glow = info.glow;
		var quad = [
			new Vector3(-width / 2, -height / 2, 0), // top left
			new Vector3(width / 2, -height / 2, 0), // top right
			new Vector3(-width / 2, height / 2, 0), // bottom left
			new Vector3(width / 2, height / 2, 0) // bottom right
		];


		for (idx => vert in quad)
		{
			var vert = VectorHelpers.rotateV3(vert, 0, 0, FlxAngle.TO_RAD * sprite.angle);
			vert.x += sprite.offsetX;
			vert.y += sprite.offsetY;

			if ((sprite is Note))
			{
				var n:Note = cast sprite;
				vert.x += n.typeOffsetX;
				vert.y += n.typeOffsetY;
			}
			vert = modManager.modifyVertex(curDecBeat, vert, idx, sprite, pos, modNumber, sprite.noteData);
			vert.x *= scalePoint.x;
			vert.y *= scalePoint.y;
			quad[idx] = vert;
		}

		scalePoint.putWeak();

		var frameRect = sprite.frame.frame;
		var sourceBitmap = sprite.graphic.bitmap;

		var leftUV = frameRect.left / sourceBitmap.width;
		var rightUV = frameRect.right / sourceBitmap.width;
		var topUV = frameRect.top / sourceBitmap.height;
		var bottomUV = frameRect.bottom / sourceBitmap.height;

		// order should be LT, RT, RB, LT, LB, RB
		// R is right L is left T is top B is bottom
		// order matters! so LT is left, top because they're represented as x, y
		var vertices = new Vector<Float>(12, false, [
			pos.x + quad[0].x, pos.y + quad[0].y,
			pos.x + quad[1].x, pos.y + quad[1].y,
			pos.x + quad[3].x, pos.y + quad[3].y,

			pos.x + quad[0].x, pos.y + quad[0].y,
			pos.x + quad[2].x, pos.y + quad[2].y,
			pos.x + quad[3].x, pos.y + quad[3].y
		]);

		var uvData = new Vector<Float>(12, false, [
			 leftUV,    topUV,
			rightUV,    topUV,
			rightUV, bottomUV,

			 leftUV,    topUV,
			 leftUV, bottomUV,
			rightUV, bottomUV,
		]);

		var shader = sprite.shader != null ? sprite.shader : new FlxShader();
		if (shader != sprite.shader)
			sprite.shader = shader;

		shader.bitmap.input = sprite.graphic.bitmap;
		shader.bitmap.filter = sprite.antialiasing ? LINEAR : NEAREST;

		return {
			graphic: sprite.graphic,
			shader: shader,
			alphas: [for (i in 0...Std.int(vertices.length / 3))alpha],
			glows: [for (i in 0...Std.int(vertices.length / 3)) glow],
			uvData: uvData,
			vertices: vertices,
			zIndex: pos.z
		}
	}
}