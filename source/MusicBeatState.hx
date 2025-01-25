package;

import haxe.io.Path;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import openfl.media.Sound;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import scripts.FunkinHScript;
import mobile.MobileData;
import mobile.IMobileControls;
import mobile.Hitbox;
import mobile.TouchPad;
import flixel.util.FlxDestroyUtil;


#if SCRIPTABLE_STATES
@:autoBuild(scripts.Macro.addScriptingCallbacks([
	"create",
	"update",
	"destroy",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit",
	"sectionHit"
]))
#end
class MusicBeatState extends FlxUIState
{
    public var script:FunkinHScript;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

    public var canBeScripted(get, default):Bool = false;
    function get_canBeScripted() return canBeScripted;
    public function new(canBeScripted:Bool = true){
        super();
        this.canBeScripted = canBeScripted;
    }

	override public function destroy(){
		removeTouchPad();
		removeMobileControls();
		
		if (script != null) script.stop();
		return super.destroy();
	}

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if(touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.extraButtons);

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: // LEFT_FULL
				mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: // CUSTOM
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: // HITBOX
				mobileControls = new Hitbox(extraMode);
		}

		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

		mobileControls.instance.cameras = [mobileControlsCam];
		mobileControls.instance.visible = false;
		add(mobileControls.instance);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}
	
	override function create() {
		camBeat = FlxG.camera;
		
		FlxG.autoPause = true;
		
		super.create();
	}

	override public function onFocus():Void
	{
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}

    // mainly moved it away so if a scripted state returns FUNCTION_STOP they can still make the music stuff update
    public function updateSteps(){
        var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}
    }

	override function update(elapsed:Float)
	{
		//everyStep();
        updateSteps();

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
    
	override function startOutro(fuck:() -> Void)
	{
		return super.startOutro(() ->
		{
			scripts.Globals.variables.clear();
			return fuck();
		});
	}


	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		FlxG.mouse.visible = false;
		Mouse.cursor = MouseCursor.AUTO;
		FlxG.autoPause = false;
		FlxG.switchState(nextState); // just because im too lazy to goto every instance of switchState and change it to a FlxG call
	}

	public static function resetState(?skipTrans:Bool = false) {
		if(skipTrans){
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		FlxG.resetState();
	}

	public static function getState():MusicBeatState
	{
		return cast FlxG.state;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	// tgt
	public static var menuMusic:Sound; // main menu loop
	public static var menuVox:FlxSound; // jukebox

	public static var menuLoopFunc = function(){
		trace("menu song ended, looping");

		FlxG.sound.playMusic(menuMusic != null ? menuMusic : Paths.music('freakyMenu'), FlxG.sound.music.volume, true);

		Conductor.changeBPM(180);
	}; 

	public static function stopMenuMusic(){
		if (FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		if (MusicBeatState.menuVox != null)
		{
			MusicBeatState.menuVox.stop();
			MusicBeatState.menuVox.destroy();
			MusicBeatState.menuVox = null;
		}
	}

	// TODO: check the jukebox selection n shit and play THAT instead? idk lol
	public static function playMenuMusic(?volume:Float=1, ?force:Bool = false){	        	
		if(FlxG.sound.music == null || !FlxG.sound.music.playing || force){
			MusicBeatState.stopMenuMusic();
			#if tgt
			tgt.gallery.JukeboxState.playIdx = 0;
			#end

			#if MODS_ALLOWED
			// i NEED to rewrite the paths shit for real 
			function returnSound(path:String, key:String, ?library:String){
				var filePath = Path.join([path, key]);

				if (!Paths.currentTrackedSounds.exists(filePath))
					Paths.currentTrackedSounds.set(filePath, openfl.media.Sound.fromFile(filePath));
				
				Paths.localTrackedAssets.push(key);

				return Paths.currentTrackedSounds.get(filePath);
			}

            var fuck = [Paths.mods(Paths.currentModDirectory), Paths.mods("global"), "assets"];
			#if MODS_ALLOWED
			for (mod in Paths.getGlobalContent())
				fuck.insert(0, Paths.mods(mod));
			for (mod in Paths.preLoadContent)
				fuck.push(Paths.mods(mod));
			for (mod in Paths.postLoadContent)
				fuck.insert(0, Paths.mods(mod));
			#end
			for (folder in fuck){
				var daPath = Path.join([folder, "music"]);
				
				var menuFilePath = daPath+"/freakyMenu.ogg";
				if (Paths.exists(menuFilePath)){
					if (Paths.exists(daPath+"/freakyIntro.ogg")){
						menuMusic = returnSound(daPath, "freakyMenu.ogg");

						FlxG.sound.playMusic(returnSound(daPath, "freakyIntro.ogg"), volume, false);
						FlxG.sound.music.onComplete = menuLoopFunc;
					}else{
						FlxG.sound.playMusic(returnSound(daPath, "freakyMenu.ogg"), volume, true);
					}	

					break;
				}
			}
			#else
			menuMusic = Paths.music('freakyMenu');
			FlxG.sound.playMusic(Paths.music('freakyIntro'), volume, false);
			FlxG.sound.music.onComplete = menuLoopFunc;
			#end
			
			//// TODO: find a way to soft code this!!! (psych engine already has one so maybe we could just use that and add custom intro text to it :-)
			#if tgt
			Conductor.changeBPM(180);
			#else
			Conductor.changeBPM(102);
			#end
			Conductor.songPosition = 0;
		}
	}
	//
}
