package;

import flixel.FlxG;

/**
 * The on-screen pause button (images/pauseButton) for PlayState, in the top right corner.
 */
class PauseButton extends ImageButton
{
	static inline var MARGIN:Float = 10;

	public function new()
	{
		// pause0000 is the resting pose, pause0008 is the big light one shown when pressed
		super('pauseButton', 'pause', 8, 90);

		x = FlxG.width - width - MARGIN;
		y = MARGIN;
	}
}
