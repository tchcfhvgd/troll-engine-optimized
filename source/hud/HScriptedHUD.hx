package hud;

import playfields.PlayField;
import JudgmentManager.JudgmentData;
import scripts.FunkinHScript;

class HScriptedHUD extends BaseHUD {
	private var script:FunkinHScript;
	override public function new(iP1:String, iP2:String, songName:String, stats:Stats, script:FunkinHScript)
	{
		super(iP1, iP2, songName, stats);
		this.script = script;
		script.set("this", this);

		script.call("createHUD", [iP1, iP2, songName]);
	}

	override public function songStarted()
	{
		script.call("songStarted");
	}

	override public function songEnding()
	{
		script.call("songEnding");
	}

	override function changedOptions(changed:Array<String>)
	{
		super.changedOptions(changed);
		script.call("changedOptions", [changed]);
	}

	override function update(elapsed:Float)
	{
		script.call("update", [elapsed]);
		super.update(elapsed);
		script.call("postUpdate", [elapsed]);
	}

	override public function beatHit(beat:Int)
	{
		super.beatHit(beat);
		script.call("beatHit", [beat]);
	}

	override public function stepHit(step:Int)
	{
		super.stepHit(step);
		script.call("stepHit", [step]);
	}

	override public function recalculateRating()
		script.call("recalculateRating", []);

	// TODO :make this use stats

	override public function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField)
	{
		super.noteJudged(judge, note, field);
		script.call("noteJudged", [judge, note, field]);
	}

	// easier constructors

	public static function fromString(iP1:String, iP2:String, songName:String, stats:Stats, scriptSource:String):HScriptedHUD
	{
		return new HScriptedHUD(iP1, iP2, songName, stats, FunkinHScript.fromString(scriptSource, "HScriptedHUD"));
	}

	public static function fromFile(iP1:String, iP2:String, songName:String, stats:Stats, fileName:String):Null<HScriptedHUD>
	{
		var fileName:String = '$fileName.hscript';
		for (file in [#if MODS_ALLOWED Paths.modFolders(fileName), #end Paths.getPreloadPath(fileName)])
		{
			if (!Paths.exists(file))
				continue;

			return new HScriptedHUD(iP1, iP2, songName, stats, FunkinHScript.fromFile(file));
		}

		trace('HUD script: $fileName not found!');
		return null;
	}

	public static function fromName(iP1:String, iP2:String, songName:String, stats:Stats, scriptName:String):Null<HScriptedHUD>
	{
		var fileName:String = 'scripts/$scriptName.hscript';
		for (file in [#if MODS_ALLOWED Paths.modFolders(fileName), #end Paths.getPreloadPath(fileName)])
		{
			if (!Paths.exists(file))
				continue;

			return new HScriptedHUD(
				iP1, 
				iP2, 
				songName, 
				stats,
				FunkinHScript.fromFile(file)
			);
		}

		trace('HUD script: $scriptName not found!');
		return null;
	}
}
