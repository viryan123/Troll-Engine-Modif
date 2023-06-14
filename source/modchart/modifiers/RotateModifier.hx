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

class RotateModifier extends NoteModifier { // this'll be rotateX in ModManager
	override function getName()
		return '${prefix}rotateX';

	override function getOrder()
		return Modifier.ModifierOrder.LAST + 2;

    inline function lerp(a:Float,b:Float,c:Float){
        return a+(b-a)*c;
    }
    var daOrigin:Vector3;
    var prefix:String;
	public function new(modMgr:ModManager, ?prefix:String = '', ?origin:Vector3, ?parent:Modifier){
        this.prefix=prefix;
        this.daOrigin=origin;
        super(modMgr, parent);

    }


	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
        var origin:Vector3 = new Vector3(modMgr.getBaseX(data, player), FlxG.height* 0.5);
        if(daOrigin!=null)origin=daOrigin;

        var diff = pos.subtract(origin);
		var out = VectorHelpers.rotateV3(diff, getValue(player) * FlxAngle.TO_RAD, getSubmodValue('${prefix}rotateY',player) * FlxAngle.TO_RAD, getSubmodValue('${prefix}rotateZ',player) * FlxAngle.TO_RAD);
        return origin.add(out);
    }

    override function getSubmods(){
        return [
            '${prefix}rotateY',
            '${prefix}rotateZ'
        ];
    }
}
