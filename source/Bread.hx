package;

class Bread extends openfl.display.Bitmap {
	public function new() {
		super();

		onGameResize(FlxG.width, FlxG.height);
		FlxG.signals.gameResized.add(onGameResize);
	}

	private function onGameResize(stageWidth, stageHeight){
		var scaleFactor = stageHeight / FlxG.initialHeight;

		scaleX = scaleFactor;
		scaleY = scaleFactor;

		x = (stageWidth - width) / 2;
		y = (stageHeight - height) / 2;
	}
}
