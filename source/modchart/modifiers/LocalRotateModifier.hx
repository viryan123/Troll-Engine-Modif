package modchart.modifiers;
import flixel.math.FlxAngle;
import flixel.FlxSprite;
import ui.*;
import modchart.*;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.FlxG;
import math.Vector3;
import math.*;

class LocalRotateModifier extends NoteModifier { // this'll be rotateX in ModManager
	override function getName()
		return '${prefix}rotateX';

	override function getOrder()
		return Modifier.ModifierOrder.POST_REVERSE;

    inline function lerp(a:Float,b:Float,c:Float){
        return a+(b-a)*c;
    }
    var prefix:String;
	public function new(modMgr:ModManager, ?prefix:String = '', ?parent:Modifier){
        this.prefix=prefix;
        super(modMgr, parent);

    }

	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		var x:Float = (FlxG.width* 0.5) - Note.swagWidth - 54 + Note.swagWidth * 1.5;
        switch (player)
        {
            case 0:
                x += FlxG.width* 0.5 - Note.swagWidth * 2 - 100;
            case 1:
                x -= FlxG.width* 0.5 - Note.swagWidth * 2 - 100;
        }
		
		x -= 56;

		var origin:Vector3 = new Vector3(x, FlxG.height* 0.5);

        var diff = pos.subtract(origin);
        var scale = FlxG.height;
        diff.z *= scale;
		var out = VectorHelpers.rotateV3(diff, getValue(player)* FlxAngle.TO_RAD, getSubmodValue('${prefix}rotateY',player)* FlxAngle.TO_RAD, getSubmodValue('${prefix}rotateZ',player)* FlxAngle.TO_RAD);
        out.z /= scale;
        return origin.add(out);
    }

    override function getSubmods(){
        return [
            '${prefix}rotateY',
            '${prefix}rotateZ'
        ];
    }
}
