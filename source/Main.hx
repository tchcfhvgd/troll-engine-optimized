package;

import Github.RepoInfo;
import Github.Release;
import flixel.FlxG;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.system.Capabilities;
import openfl.events.Event;
import lime.app.Application;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end

#if sys
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
#end

#if sys
import sys.io.File;
#end

#if mobile
import mobile.CopyState;
#end

#if (windows && cpp)
@:cppFileCode('#include <windows.h>')
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = StartupState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static var volumeChangedEvent:lime.app.Event<Float->Void> = new lime.app.Event<Float->Void>();
	public static var engineVersion:String = '0.2.0'; // Used for autoupdating n stuff
	public static var betaVersion(get, default):String = 'rc.1'; // beta version, make blank if not on a beta version, otherwise do it based on semantic versioning (alpha.1, beta.1, rc.1, etc)
	public static var beta:Bool = betaVersion.trim() != '';

	public static var UserAgent:String = 'TrollEngine/${Main.engineVersion}'; // used for http requests. if you end up forking the engine and making your own then make sure to change this!!
	public static var githubRepo:RepoInfo = Github.getCompiledRepoInfo();
	public static var downloadBetas:Bool = beta;
	public static var outOfDate:Bool = false;
	public static var recentRelease:Release;

	public static var showDebugTraces:Bool = #if (SHOW_DEBUG_TRACES || debug) true #else false #end;

	static function get_betaVersion()
		return beta ? betaVersion : "0";

    @:isVar
    public static var semanticVersion(get, null):SemanticVersion = '';
	static function get_semanticVersion()
		return '$engineVersion${beta ? '-$betaVersion' : ""}';

	@:isVar
	public static var displayedVersion(get, null):String = '';
	static function get_displayedVersion()
		return 'v${semanticVersion}';
	    
	////
	public static var fpsVar:FPS;
	
	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		#if windows
		@:functionCode("
		#include <windows.h>
		#include <winuser.h>
		setProcessDPIAware() // allows for more crisp visuals
		DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		")
		#end
		
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	public static function setScaleMode(scale:String){
		switch(scale){
			default:
				Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
			case 'EXACT_FIT':
				Lib.current.stage.scaleMode = StageScaleMode.EXACT_FIT;
			case 'NO_BORDER':
				Lib.current.stage.scaleMode = StageScaleMode.NO_BORDER;
			case 'SHOW_ALL':
				Lib.current.stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
	}

	private function setupGame():Void
	{
		#if(openfl < "9.2.0")
		final screenWidth = Capabilities.screenResolutionX;
		final screenHeight = Capabilities.screenResolutionY;

		//// Readjust the game size for smaller screens
		if (zoom == -1)
		{
			if (!(screenWidth > gameWidth || screenHeight > gameWidth)){
				var ratioX:Float = screenWidth / gameWidth;
				var ratioY:Float = screenHeight / gameHeight;
				
				zoom = Math.min(ratioX, ratioY);
				gameWidth = Math.ceil(screenWidth / zoom);
				gameHeight = Math.ceil(screenHeight / zoom);
			}
		}
		#end
	
		////		
		var troll = false;
		#if sys
		for (arg in Sys.args()){
			switch(arg){
				case "troll":
					troll = true;

				case "songselect":
					StartupState.nextState = SongSelectState;

				case "debug":
					PlayState.chartingMode = true;
				
				case "showdebugtraces":
					Main.showDebugTraces = true;
			}
		}
		#end

		if (troll){
			initialState = SinnerState;
			skipSplash = true;
		}else{
		        @:privateAccess
			FlxG.initSave(); //不要存档了是吧？ --qqqeb
			#if(openfl < "9.2.0")
			

			//// Readjust the window size for larger screens 
			var scaleFactor:Int = Math.ceil((screenWidth > screenHeight) ? (screenHeight / gameHeight) : (screenWidth / gameWidth));
			if (scaleFactor > 1) scaleFactor--;
			
			final windowWidth:Int = scaleFactor * gameWidth;
			final windowHeight:Int = scaleFactor * gameHeight;

			Application.current.window.resize(
				windowWidth, 
				windowHeight
			);
			Application.current.window.move(
				Std.int((screenWidth - windowWidth) / 2),
				Std.int((screenHeight - windowHeight) / 2)
			);

			////
			if (FlxG.save.data != null && FlxG.save.data.fullscreen != null)
				startFullscreen = FlxG.save.data.fullscreen;
			#end
		}
		
		addChild(new FNFGame(gameWidth, gameHeight, #if (mobile && MODS_ALLOWED) !CopyState.checkExistingFiles() ? CopyState : #end initialState, #if(flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen));

		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		#if android
		FlxG.android.preventDefaultKeys = [BACK]; 
		#end

		if (!troll){
			fpsVar = new FPS(10, 3, 0xFFFFFF);
			fpsVar.visible = false;
			#if !mobile
		        addChild(fpsVar);
		        #else
		        FlxG.game.addChild(fpsVar);
		        #end

			bread = new Bread();
			bread.visible = false;
			addChild(bread);
		}
	#if sys
		// Original code was made by sqirra-rng, big props to them!!!
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR, 
			(event:UncaughtErrorEvent)->{
				onCrash(event.error);
			}
		);


		#if cpp
		// Thank you EliteMasterEric, very cool!
		untyped __global__.__hxcpp_set_critical_error_handler(onCrash);
		#end
		#end
	}

	
	#if sys
	function onCrash(errorName:String):Void
	{
		////
		var ogTrace = haxe.Log.trace;
		haxe.Log.trace = (msg, ?pos)->{
			ogTrace(msg, null);
		}

		////
		trace("\nCall stack starts below");

		var callstack:String = "";

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					callstack += '$file:$line\n';
				default:
			}
		}

		callstack += '\n$errorName';

		trace('\n$callstack\n');

		#if (windows && cpp)
		windows_showErrorMsgBox(callstack, errorName);
		#else
		Application.current.window.alert(callstack, errorName);
		#end

		#if discord_rpc
		DiscordClient.shutdown(true);
		#end

		#if sys
		File.saveContent("crash.txt", callstack);
		Sys.exit(1);
		#end
	}

	#if (windows && cpp)
	@:functionCode('MessageBox(NULL, message, title, MB_ICONERROR | MB_OK);')
	function windows_showErrorMsgBox(message:String, title:String){}
	#end

	#end
}
