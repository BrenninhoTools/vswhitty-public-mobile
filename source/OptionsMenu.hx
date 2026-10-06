package;

import openfl.Lib;
import Options;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;

	var options:Array<OptionCatagory> = [
		new OptionCatagory("Gameplay", [
			new DFJKOption(controls),
			new DownscrollOption("Change the layout of the strumline."),
			new GhostTapOption("Ghost Tapping is when you tap a direction and it doesn't give you a miss."),
			new Judgement("Customize your Hit Timings (LEFT or RIGHT)"),
			#if desktop
			new FPSCapOption("Cap your FPS (Left for -10, Right for +10. SHIFT to go faster)"),
			#end
			new ScrollSpeedOption("Change your scroll speed (Left for -0.1, right for +0.1. If it's at 1, it will be chart dependent)"),
			new AccuracyDOption("Change how accuracy is calculated. (Accurate = Simple, Complex = Milisecond Based)"),
			// new OffsetMenu("Get a note offset based off of your inputs!"),
			new CustomizeGameplay("Drag'n'Drop Gameplay Modules around to your preference")
		]),
		new OptionCatagory("Appearance", [
			#if desktop
			new DistractionsAndEffectsOption("Toggle stage distractions that can hinder your gameplay."),
			new RainbowFPSOption("Make the FPS Counter Rainbow (Only works with the FPS Counter toggled on and Flashing Lights toggled off)"),
			new AccuracyOption("Display accuracy information."),
			new NPSDisplayOption("Shows your current Notes Per Second."),
			new SongPositionOption("Show the songs current position (as a bar)"),
			#else
			new DistractionsAndEffectsOption("Toggle stage distractions that can hinder your gameplay."),
			#end
			#if (mobile || MOBILE_UI)
			new HitboxOpacityOption("How visible the touch controls are (Left for -10%, Right for +10%). At 0% they are invisible but still work."),
			#end
		]),
		
		new OptionCatagory("Misc", [
			#if desktop
			new FPSOption("Toggle the FPS Counter"),
			new ReplayOption("View replays"),
			#end
			new FlashingLightsOption("Toggle flashing lights that can cause epileptic seizures and strain."),
			new WatermarkOption("Turn off all watermarks from the engine."),
			new BotPlay("Showcase your charts and mods with autoplay.")
		])
		
	];

	private var currentDescription:String = "";
	private var grpControls:FlxTypedGroup<Alphabet>;
	public static var versionShit:FlxText;

	var currentSelectedCat:OptionCatagory;

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menuDesat"));

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...options.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i].getName(), true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		currentDescription = "none";

		versionShit = new FlxText(5, FlxG.height - 18, 0, "Offset (Left, Right): " + FlxG.save.data.offset + " - Description - " + currentDescription, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		addTouchBack();

		if (TouchUtil.MOBILE)
		{
			// stand-ins for the LEFT / RIGHT keys, used to change the value of the selected option
			touchLeft = new TouchButton(FlxG.width / 2 - 110, FlxG.height - 70, 100, 60, FlxColor.BLACK, "<");
			touchRight = new TouchButton(FlxG.width / 2 + 10, FlxG.height - 70, 100, 60, FlxColor.BLACK, ">");
			add(touchLeft);
			add(touchRight);
		}

		super.create();
	}

	var touchLeft:TouchButton;
	var touchRight:TouchButton;

	var isCat:Bool = false;
	

	override function update(elapsed:Float)
	{
		super.update(elapsed);

			// arrow keys, or the on-screen arrows on touch builds
			var rightP:Bool = FlxG.keys.justPressed.RIGHT;
			var leftP:Bool = FlxG.keys.justPressed.LEFT;
			var rightHeld:Bool = FlxG.keys.pressed.RIGHT;
			var leftHeld:Bool = FlxG.keys.pressed.LEFT;
			var accepted:Bool = controls.ACCEPT;

			if (touchLeft != null)
			{
				rightP = rightP || touchRight.justPressed;
				leftP = leftP || touchLeft.justPressed;
				rightHeld = rightHeld || touchRight.pressed;
				leftHeld = leftHeld || touchLeft.pressed;

				// tapping an option selects it, tapping the selected one presses it
				var tapped = TouchUtil.tappedNearest(grpControls.members);
				if (tapped == curSelected)
					accepted = true;
				else if (tapped >= 0)
					changeSelection(tapped - curSelected);

				var drag = TouchUtil.dragSteps(TouchUtil.DRAG_STEP);
				if (drag != 0)
					changeSelection(drag);
			}

			var backed:Bool = controls.BACK || touchBackTapped;

			if (backed && !isCat)
				FlxG.switchState(new MainMenuState());
			else if (backed)
			{
				isCat = false;
				grpControls.clear();
				for (i in 0...options.length)
					{
						var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i].getName(), true, false);
						controlLabel.isMenuItem = true;
						controlLabel.targetY = i;
						grpControls.add(controlLabel);
						// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
					}
				curSelected = 0;
			}
			if (controls.UP_P)
				changeSelection(-1);
			if (controls.DOWN_P)
				changeSelection(1);
			
			if (isCat)
			{
				if (currentSelectedCat.getOptions()[curSelected].getAccept())
				{
					if (FlxG.keys.pressed.SHIFT)
						{
							if (rightHeld)
								currentSelectedCat.getOptions()[curSelected].right();
							if (leftHeld)
								currentSelectedCat.getOptions()[curSelected].left();
						}
					else
					{
						if (rightP)
							currentSelectedCat.getOptions()[curSelected].right();
						if (leftP)
							currentSelectedCat.getOptions()[curSelected].left();
					}
				}
				else
				{

					if (FlxG.keys.pressed.SHIFT)
					{
						if (rightP)
							FlxG.save.data.offset += 0.1;
						else if (leftP)
							FlxG.save.data.offset -= 0.1;
					}
					else if (rightHeld)
						FlxG.save.data.offset += 0.1;
					else if (leftHeld)
						FlxG.save.data.offset -= 0.1;
					
					versionShit.text = "Offset (Left, Right, Shift for slow): " + HelperFunctions.truncateFloat(FlxG.save.data.offset,2) + " - Description - " + currentDescription;
				}
			}
			else
			{
				if (FlxG.keys.pressed.SHIFT)
					{
						if (rightP)
							FlxG.save.data.offset += 0.1;
						else if (leftP)
							FlxG.save.data.offset -= 0.1;
					}
					else if (rightHeld)
						FlxG.save.data.offset += 0.1;
					else if (leftHeld)
						FlxG.save.data.offset -= 0.1;
				
				versionShit.text = "Offset (Left, Right, Shift for slow): " + HelperFunctions.truncateFloat(FlxG.save.data.offset,2) + " - Description - " + currentDescription;
			}
		

			if (controls.RESET)
					FlxG.save.data.offset = 0;

			if (accepted)
			{
				if (isCat)
				{
					if (currentSelectedCat.getOptions()[curSelected].press()) {
						grpControls.remove(grpControls.members[curSelected]);
						var ctrl:Alphabet = new Alphabet(0, (70 * curSelected) + 30, currentSelectedCat.getOptions()[curSelected].getDisplay(), true, false);
						ctrl.isMenuItem = true;
						grpControls.add(ctrl);
					}
				}
				else
				{
					currentSelectedCat = options[curSelected];
					isCat = true;
					grpControls.clear();
					for (i in 0...currentSelectedCat.getOptions().length)
						{
							var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, currentSelectedCat.getOptions()[i].getDisplay(), true, false);
							controlLabel.isMenuItem = true;
							controlLabel.targetY = i;
							grpControls.add(controlLabel);
							// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
						}
					curSelected = 0;
				}
			}
		FlxG.save.flush();
	}

	var isSettingControl:Bool = false;

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent("Fresh");
		#end
		
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		if (isCat)
			currentDescription = currentSelectedCat.getOptions()[curSelected].getDescription();
		else
			currentDescription = "Please select a category";
		versionShit.text = "Offset (Left, Right, Shift for slow): " + HelperFunctions.truncateFloat(FlxG.save.data.offset,2) + " - Description - " + currentDescription;

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}