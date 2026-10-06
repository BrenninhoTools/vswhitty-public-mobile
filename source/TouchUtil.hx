package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.input.FlxPointer;

enum SwipeDirection
{
	NoSwipe;
	Up;
	Down;
	Left;
	Right;
}

/**
 * Helpers to read touches (and the mouse, on non-mobile builds) in a uniform way.
 *
 * Everything here is pull-based: each query reads the current state of FlxG.touches,
 * so there is nothing to update every frame. Only `reset()` should be called when a state is created.
 *
 * Touch UI (hitbox, back buttons, tappable menus) is enabled with `TouchUtil.MOBILE`, which is
 * true on android/ios builds and on any build compiled with `-DMOBILE_UI` (handy to test on desktop).
 */
class TouchUtil
{
	public static inline var MOBILE:Bool = #if (mobile || MOBILE_UI) true #else false #end;

	/** The mouse is only treated as a pointer on non-mobile builds, mobile already reports touches. */
	static inline var USE_MOUSE:Bool = #if mobile false #else true #end;

	/** How far (in game pixels) a pointer can travel and still count as a tap. Past it, it is a swipe. */
	public static inline var TAP_DISTANCE:Float = 40;

	/** How far (in game pixels) a finger has to be dragged to scroll a menu by one item. */
	public static inline var DRAG_STEP:Float = 60;

	static inline var MOUSE_ID:Int = -2;
	static inline var NO_ID:Int = -1;

	static var trackedId:Int = NO_ID;
	static var startX:Float = 0;
	static var startY:Float = 0;

	static var dragging:Bool = false;
	static var dragLastY:Float = 0;
	static var dragAccumulated:Float = 0;

	static var tapPointer:FlxPointer = null;
	static var swipeDir:SwipeDirection = NoSwipe;

	/** Any pointer is currently down. */
	public static var pressed(get, never):Bool;

	/** Any pointer went down this frame. */
	public static var justPressed(get, never):Bool;

	/** Any pointer was lifted this frame. */
	public static var justReleased(get, never):Bool;

	/** A pointer was lifted this frame without having moved far: a tap. */
	public static var tapped(get, never):Bool;

	/** Direction of the swipe that finished this frame, `NoSwipe` when there wasn't one. */
	public static var swipe(get, never):SwipeDirection;

	/** Forget the pointer being tracked. Call it when a state is created, so a touch that started in the previous state can't produce a tap. */
	public static function reset():Void
	{
		trackedId = NO_ID;
		dragging = false;
		tapPointer = null;
		swipeDir = NoSwipe;
	}

	/** Is some pointer that is currently down over `object`? */
	public static function pressedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		var cam = getCamera(object, camera);
		for (touch in FlxG.touches.list)
			if (touch.pressed && touch.overlaps(object, cam))
				return true;

		return USE_MOUSE && FlxG.mouse.pressed && FlxG.mouse.overlaps(object, cam);
	}

	/** Did some pointer go down over `object` this frame? */
	public static function justPressedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		var cam = getCamera(object, camera);
		for (touch in FlxG.touches.list)
			if (touch.justPressed && touch.overlaps(object, cam))
				return true;

		return USE_MOUSE && FlxG.mouse.justPressed && FlxG.mouse.overlaps(object, cam);
	}

	/** Was `object` tapped this frame? (pressed and lifted over it without dragging). Good for buttons and menu items. */
	public static function tappedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		refresh();
		return tapPointer != null && tapPointer.overlaps(object, getCamera(object, camera));
	}

	/** A pointer that is currently down (a touch first, then the mouse), or null. Its x/y are in world coordinates. */
	public static var pressedPointer(get, never):FlxPointer;

	/** Is some pointer that is currently down within `padding` pixels of `object`'s box? Gives fingers some slack on small buttons. */
	public static function pressedWithin(object:FlxObject, padding:Float, ?camera:FlxCamera):Bool
	{
		var cam = getCamera(object, camera);
		for (touch in FlxG.touches.list)
			if (touch.pressed && isNear(touch, object, padding, cam))
				return true;

		return USE_MOUSE && FlxG.mouse.pressed && isNear(FlxG.mouse, object, padding, cam);
	}

	/** Was `object` tapped this frame, counting taps up to `padding` pixels outside of its box? */
	public static function tappedWithin(object:FlxObject, padding:Float, ?camera:FlxCamera):Bool
	{
		refresh();
		return tapPointer != null && isNear(tapPointer, object, padding, getCamera(object, camera));
	}

	/**
	 * Of `objects`, the one whose center is closest (vertically) to this frame's tap, or -1 if there was no tap
	 * or every object is further than `maxDistance`. Lets a menu row be tapped anywhere along its height.
	 */
	public static function tappedNearest<T:FlxObject>(objects:Array<T>, ?camera:FlxCamera, maxDistance:Float = 50):Int
	{
		refresh();
		if (tapPointer == null)
			return -1;

		var best = -1;
		var bestDistance = maxDistance;

		for (i in 0...objects.length)
		{
			var object = objects[i];
			if (object == null || !object.visible || !object.alive)
				continue;

			var position = object.getScreenPosition(null, getCamera(object, camera));
			var distance = Math.abs(tapPointer.screenY - (position.y + object.height / 2));
			position.put();

			if (distance < bestDistance)
			{
				best = i;
				bestDistance = distance;
			}
		}

		return best;
	}

	/**
	 * Scrolling by dragging: how many `stepSize`-pixel steps the finger moved since the last call.
	 * Positive when it moved up (the next item), negative when it moved down.
	 * Call it once per frame from whatever scrolls.
	 */
	public static function dragSteps(stepSize:Float):Int
	{
		var pointer = pressedPointer;
		if (pointer == null)
		{
			dragging = false;
			dragAccumulated = 0;
			return 0;
		}

		var y:Float = pointer.screenY;
		if (!dragging)
		{
			dragging = true;
			dragLastY = y;
			dragAccumulated = 0;
			return 0;
		}

		dragAccumulated += dragLastY - y;
		dragLastY = y;

		var steps = 0;
		while (dragAccumulated >= stepSize)
		{
			dragAccumulated -= stepSize;
			steps++;
		}
		while (dragAccumulated <= -stepSize)
		{
			dragAccumulated += stepSize;
			steps--;
		}

		return steps;
	}

	static function isNear(pointer:FlxPointer, object:FlxObject, padding:Float, camera:FlxCamera):Bool
	{
		var position = object.getScreenPosition(null, camera);
		var near = pointer.screenX >= position.x - padding
			&& pointer.screenX <= position.x + object.width + padding
			&& pointer.screenY >= position.y - padding
			&& pointer.screenY <= position.y + object.height + padding;
		position.put();
		return near;
	}

	/** Calls `callback` with the screen position of every pointer that is currently down. */
	public static function forEachPressed(callback:(Int, Int) -> Void):Void
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				callback(touch.screenX, touch.screenY);

		if (USE_MOUSE && FlxG.mouse.pressed)
			callback(FlxG.mouse.screenX, FlxG.mouse.screenY);
	}

	static function getCamera(object:FlxObject, camera:FlxCamera):FlxCamera
	{
		if (camera != null)
			return camera;

		var cameras = object.cameras;
		return (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
	}

	/**
	 * Follows one pointer from press to release to tell taps from swipes.
	 * Safe to call any number of times in a frame: its result only depends on the current input state.
	 */
	static function refresh():Void
	{
		tapPointer = null;
		swipeDir = NoSwipe;

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				begin(touch.touchPointID, touch.screenX, touch.screenY);
			else if (touch.justReleased && touch.touchPointID == trackedId)
				finish(touch, touch.screenX, touch.screenY);
		}

		if (USE_MOUSE)
		{
			if (FlxG.mouse.justPressed)
				begin(MOUSE_ID, FlxG.mouse.screenX, FlxG.mouse.screenY);
			else if (FlxG.mouse.justReleased && trackedId == MOUSE_ID)
				finish(FlxG.mouse, FlxG.mouse.screenX, FlxG.mouse.screenY);
		}
	}

	static function begin(id:Int, x:Float, y:Float):Void
	{
		trackedId = id;
		startX = x;
		startY = y;
	}

	static function finish(pointer:FlxPointer, x:Float, y:Float):Void
	{
		var dx = x - startX;
		var dy = y - startY;

		if (Math.abs(dx) < TAP_DISTANCE && Math.abs(dy) < TAP_DISTANCE)
		{
			tapPointer = pointer;
			return;
		}

		if (Math.abs(dy) >= Math.abs(dx))
			swipeDir = dy < 0 ? Up : Down;
		else
			swipeDir = dx < 0 ? Left : Right;
	}

	static function get_pressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				return true;

		return USE_MOUSE && FlxG.mouse.pressed;
	}

	static function get_pressedPointer():FlxPointer
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				return touch;

		return (USE_MOUSE && FlxG.mouse.pressed) ? FlxG.mouse : null;
	}

	static function get_justPressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				return true;

		return USE_MOUSE && FlxG.mouse.justPressed;
	}

	static function get_justReleased():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return true;

		return USE_MOUSE && FlxG.mouse.justReleased;
	}

	static function get_tapped():Bool
	{
		refresh();
		return tapPointer != null;
	}

	static function get_swipe():SwipeDirection
	{
		refresh();
		return swipeDir;
	}
}
