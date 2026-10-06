package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * A rectangle (optionally with a label) that can be pressed with a finger.
 *
 * `pressed`, `justPressed` and `justReleased` are refreshed in `update()`. With `autoPoll` they come from
 * the touches over the button, otherwise whoever owns the button feeds them with `setDown()` (that's how the Hitbox works).
 */
class TouchButton extends FlxSpriteGroup
{
	public var pressed(default, null):Bool = false;
	public var justPressed(default, null):Bool = false;
	public var justReleased(default, null):Bool = false;

	public var autoPoll:Bool = true;

	/** Camera the button is drawn on, when it isn't the default one. Needed to hit-test correctly. */
	public var touchCamera:FlxCamera = null;
	public var idleAlpha:Float = 0.4;
	public var pressedAlpha:Float = 0.85;

	var bg:FlxSprite;
	var label:FlxText;

	public function new(x:Float, y:Float, width:Int, height:Int, color:FlxColor, ?text:String, gradient:Bool = false)
	{
		super(x, y);

		bg = new FlxSprite();
		if (gradient)
			bg.loadGraphic(makeGradient(width, height, color), false, 0, 0, true);
		else
			bg.makeGraphic(width, height, color);
		bg.scrollFactor.set();
		add(bg);

		if (text != null)
		{
			var size = Std.int(Math.max(16, height * 0.4));
			label = new FlxText(0, 0, width, text, size);
			label.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			// members are positioned relative to the group
			label.y = (height - label.height) / 2;
			label.scrollFactor.set();
			add(label);
		}

		scrollFactor.set();
		setDown(false);
	}

	override function update(elapsed:Float)
	{
		if (autoPoll)
			setDown(TouchUtil.pressedOn(bg, touchCamera));

		super.update(elapsed);
	}

	/** Replaces the picture of the button. Use one the same size as the button. */
	public function setBitmap(bitmap:BitmapData):Void
	{
		bg.loadGraphic(bitmap, false, 0, 0, true);
	}

	public function setDown(down:Bool):Void
	{
		justPressed = down && !pressed;
		justReleased = !down && pressed;
		pressed = down;

		bg.alpha = down ? pressedAlpha : idleAlpha;
	}

	/** Colored rectangle that is solid at the bottom and fades out towards the top. */
	public static function makeGradient(width:Int, height:Int, color:FlxColor):BitmapData
	{
		var bitmap = new BitmapData(width, height, true, 0);
		var rect = new Rectangle(0, 0, width, 1);

		for (row in 0...height)
		{
			var t = row / height;
			rect.y = row;
			bitmap.fillRect(rect, FlxColor.fromRGB(color.red, color.green, color.blue, Std.int(255 * t * t)));
		}

		return bitmap;
	}
}
