package;

class NumberSequence
{
	var points:Array<NumberSequenceKeypoint> = [];

	inline static function lerp(a:Float, b:Float, c:Float)
		return a + (b - a) * c;


	@:isVar
	public var easeFunc(get, null):Float->Float; // EaseFunction

	function get_easeFunc()
	{
		return function(time:Float)
		{
			return getValue(time);
		}
	}

	public function new(?points:Array<NumberSequenceKeypoint>)
	{
		if (points != null)
			this.points = points;
		else
			this.points = [new NumberSequenceKeypoint(0, 1), new NumberSequenceKeypoint(1, 1)];

		this.points.sort((a, b) -> Std.int(a.time - b.time));
	}

	public function getValue(time:Float)
	{
		var index = getPointIndex(time);
		var nextIndex = index + 1;

		var curPoint = points[index];
		var nexPoint = points[nextIndex];

		if (nexPoint == null)
		{
			return points[points.length - 1].value;
		}
		if (index >= 0)
		{
			var progress = (time - curPoint.time) / (nexPoint.time - curPoint.time);
			return lerp(curPoint.value, nexPoint.value, progress);
		}

		return 0;
	}

	public function getPoint(time:Float)
	{
		return points[getPointIndex(time)];
	}

	public function getPointIndex(time:Float)
	{
		var returnedIdx:Int = 0;
		for (idx in 0...points.length)
		{
			var point = points[idx];
			if (point.time > time)
				break;
			else
				returnedIdx = idx;
		}
		return returnedIdx;
	}
}

class NumberSequenceKeypoint
{
	public var time:Float = 0;
	public var value:Float = 0;

	public function new(t:Float, v:Float)
	{
		if (t < 0)
			t = 0;
		if (t > 1)
			t = 1;
		time = t;
		value = v;
	}
}
