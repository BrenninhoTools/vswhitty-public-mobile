package;

import flixel.FlxCamera;
import flixel.FlxSprite;

/**
 * A button drawn from a Sparrow atlas: a resting frame and a pressed frame, refreshed from the touches over it.
 * Check for a tap with `TouchUtil.tappedOn(button, button.touchCamera)`, or `justPressed` for an instant reaction.
 */
class ImageButton extends FlxSprite
{
	public var pressed(default, null):Bool = false;
	public var justPressed(default, null):Bool = false;

	/** Extra pixels around the button that still count as touching it, so small buttons are easy to hit. */
	public var hitPadding:Float = 20;

	/** Camera the button is drawn on, when it isn't the default one. Needed to hit-test correctly. */
	public var touchCamera:FlxCamera = null;

	/**
	 * @param image 		name of the atlas in images/ (without extension)
	 * @param prefix 		prefix of the frames in the atlas xml
	 * @param pressedFrame 	index of the frame shown while the button is held, frame 0 is the resting one
	 * @param displayWidth 	width of the button on screen, in game pixels
	 */
	public function new(image:String, prefix:String, pressedFrame:Int, displayWidth:Float)
	{
		super();

		frames = Paths.getSparrowAtlas(image);

		animation.addByIndices('idle', prefix, [0], '', 24, false);
		animation.addByIndices('pressed', prefix, [pressedFrame], '', 24, false);
		animation.play('idle');

		setGraphicSize(Std.int(displayWidth));
		updateHitbox();

		antialiasing = true;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		var down = TouchUtil.pressedWithin(this, hitPadding, touchCamera);

		justPressed = down && !pressed;

		if (down != pressed)
		{
			pressed = down;
			animation.play(down ? 'pressed' : 'idle');
		}

		super.update(elapsed);
	}
}
