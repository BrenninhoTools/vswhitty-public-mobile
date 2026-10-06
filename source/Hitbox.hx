package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * On-screen controls for PlayState: the screen is split into four full-height lanes (left, down, up, right).
 * A finger on a lane acts as the key for that arrow; sliding a finger into another lane presses that one.
 *
 * Lane order matches the note data used by PlayState: 0 = left, 1 = down, 2 = up, 3 = right.
 *
 * How visible it is comes from the "Hitbox Opacity" option (FlxG.save.data.hitboxOpacity, 0-100).
 * At 0 it is invisible, but still works.
 */
class Hitbox extends FlxSpriteGroup
{
	static var LANE_COLORS:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

	static inline var EDGE_WIDTH:Int = 3;

	public var buttonLeft(get, never):TouchButton;
	public var buttonDown(get, never):TouchButton;
	public var buttonUp(get, never):TouchButton;
	public var buttonRight(get, never):TouchButton;

	public var lanes(default, null):Array<TouchButton> = [];

	/** Screen areas (in game pixels) where touches are ignored, e.g. where the pause button sits. */
	public var deadZones:Array<FlxRect> = [];

	var opacity:Float;

	var laneWidth:Int;
	var down:Array<Bool> = [false, false, false, false];

	public function new()
	{
		super();

		laneWidth = Math.ceil(FlxG.width / LANE_COLORS.length);
		opacity = getOpacity();

		for (i in 0...LANE_COLORS.length)
		{
			var lane = new TouchButton(i * laneWidth, 0, laneWidth, FlxG.height, LANE_COLORS[i]);
			lane.setBitmap(makeLaneBitmap(laneWidth, FlxG.height, LANE_COLORS[i]));
			lane.autoPoll = false;
			lane.idleAlpha = 0.3 * opacity;
			lane.pressedAlpha = 0.8 * opacity;
			lane.setDown(false);
			lanes.push(lane);
			add(lane);
		}

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		for (i in 0...down.length)
			down[i] = false;

		TouchUtil.forEachPressed(function(x:Int, y:Int)
		{
			for (zone in deadZones)
				if (x >= zone.x && x <= zone.x + zone.width && y >= zone.y && y <= zone.y + zone.height)
					return;

			var lane = Std.int(Math.max(0, Math.min(down.length - 1, Math.floor(x / laneWidth))));
			down[lane] = true;
		});

		for (i in 0...down.length)
			lanes[i].setDown(down[i]);

		super.update(elapsed);
	}

	/** Lift every lane, for when the player isn't in control anymore (pause, game over...) */
	public function releaseAll():Void
	{
		for (lane in lanes)
			lane.setDown(false);
	}

	/** The saved opacity as 0-1, 1 when it was never set. */
	static function getOpacity():Float
	{
		var percent:Float = FlxG.save.data.hitboxOpacity == null ? 100 : FlxG.save.data.hitboxOpacity;
		return Math.max(0, Math.min(100, percent)) / 100;
	}

	/** A column that is solid at the bottom, fades out towards the top and has a thin line on each side. */
	static function makeLaneBitmap(width:Int, height:Int, color:FlxColor):BitmapData
	{
		var bitmap = TouchButton.makeGradient(width, height, color);

		// the lines fade with the same curve as the gradient, so they don't show on the empty top of the screen
		var rect = new Rectangle(0, 0, EDGE_WIDTH, 1);
		for (row in 0...height)
		{
			var t = row / height;
			var line = FlxColor.fromRGB(color.red, color.green, color.blue, Std.int(200 * t));
			rect.y = row;
			rect.x = 0;
			bitmap.fillRect(rect, line);
			rect.x = width - EDGE_WIDTH;
			bitmap.fillRect(rect, line);
		}

		return bitmap;
	}

	inline function get_buttonLeft():TouchButton
		return lanes[0];

	inline function get_buttonDown():TouchButton
		return lanes[1];

	inline function get_buttonUp():TouchButton
		return lanes[2];

	inline function get_buttonRight():TouchButton
		return lanes[3];
}
