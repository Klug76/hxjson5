package;

import haxe.Json;

class Util
{

	public static function equal_Dynamics<A, B>(a: A, b: B): Bool
	{
		var ta = Type.typeof(a);
		var tb = Type.typeof(a);
		switch(ta)
		{
		case TObject:
			if (ta != tb)
				return false;
			return equal_Objects(a, b);
		case TClass(ca):
			if(ca == String)
			{
				switch(tb)
				{
				case TClass(cb):
					if (cb == String)
						return (cast a: String) == (cast b: String);
				default:
				}
			}
			else
			if (ca == Array)
			{
				switch(tb)
				{
				case TClass(cb):
					if (cb == Array)
						return equal_Arrays((cast a: Array<Dynamic>), (cast b: Array<Dynamic>));
				default:
				}
			}
		case TEnum(_):
			return false;//:assume no enums here
		case TFloat:
			if (ta != tb)
				return false;
			return equal_Floats((cast a: Float), (cast b: Float));
		default:
			if (ta != tb)
				return false;
			return untyped a == b;
		}
		return false;
	}

	public static function equal_Objects(a: Dynamic, b: Dynamic) : Bool
	{
		var fa = Reflect.fields(a);
		var fb = Reflect.fields(b);
		if (fa.length != fb.length)
			return false;
		for (key in fa)
		{
			fb.remove(key);
			if (!Reflect.hasField(b, key))
				return false;
			var va = Reflect.field(a, key);
			var vb = Reflect.field(b, key);
			if(!equal_Dynamics(va, vb))
				return false;
		}
		return fb.length == 0;
	}

	public static function equal_Floats(a: Float, b: Float) : Bool
	{
		var epsilon: Float = 0.000001;
		return Math.abs(a - b) < epsilon;
	}

	public static function equal_Arrays(a: Array<Dynamic>, b: Array<Dynamic>) : Bool
	{
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
		{
			if (!equal_Dynamics(a[i], b[i]))
				return false;
		}
		return true;
	}


	public static function dump_Strings_Diff(expected: String, actual: String)
	{
		if (expected == actual)
			return;
		trace("!=");
		var len1 = actual.length;
		var len2 = expected.length;
		trace("len1="+len1);
		trace("len2="+len2);
		var min = if (len1 < len2) len1 else len2;
		for (i in 0...min)
		{
			if (expected.charCodeAt(i) != actual.charCodeAt(i))
			{
				trace("i=" + i);
				var j = i - 10;
				if (j < 0)
					j = 0;
				trace(Json.stringify(expected.substr(j, 20)));
				trace(Json.stringify(actual.substr(j, 20)));
				break;
			}
		}
	}

}