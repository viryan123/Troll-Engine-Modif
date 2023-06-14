package modchart.modifiers;

import flixel.FlxSprite;
import modchart.*;
import math.*;

class OpponentModifier extends NoteModifier {
	override function getName()
		return 'opponentSwap';
    override function getPos(diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
    {
        var nPlayer = Std.int(CoolUtil.scale(player, 0, 1, 1, 0));

		var oppX = modMgr.getBaseX(data, nPlayer);
		var plrX = modMgr.getBaseX(data, player);

        var distX = oppX-plrX;

		pos.x += distX * getValue(player);

        return pos;
    }
}
