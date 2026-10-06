package;

import flixel.FlxG;

/**
 * The on-screen BACK button (images/backButton), sitting in the bottom right corner.
 * MusicBeatState and MusicBeatSubstate add it and check for taps on it.
 */
class BackButton extends ImageButton
{
	static inline var MARGIN:Float = 10;

	public function new()
	{
		// back0000 is the resting pose, back0005 is the dark pressed one
		super('backButton', 'back', 5, 120);

		x = FlxG.width - width - MARGIN;
		y = FlxG.height - height - MARGIN;
	}
}
