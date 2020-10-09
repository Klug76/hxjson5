package gs.json5mod;

class Json5Util
{
	public static function is_Valid_Key_Char(cc: Int, first: Bool): Bool
	{
		//:new way
		switch(cc)
		{
		case ':'.code,
			 ','.code,
			 '['.code,
			 ']'.code,
			 '{'.code,
			 '}'.code,
			 '"'.code,
			 '\\'.code,
			 0xA0:
			return false;
		default:
			//TODO review: unicode ws
			if (cc <= ' '.code)
				return false;
			return true;
		}
	}

	public static inline function in_Closed_Interval(cc: Int, begin: Int, end: Int) : Bool
	{
		return (cc >= begin) && (cc <= end);
	}

	public static function Array2String(arr: Array<Int>): String
	{
		var sb = new Json5Buf();
		for (a in arr)
		{
			sb.add_Chr(a);
		}
		return sb.toString();
	}

	public static function get_String_LSpace(s: String) : Int
	{
		var len = s.length;
		for (i in 0...len)
		{
			var cc: Int = StringTools.fastCodeAt(s, i);
			switch(cc)
			{
			case ' '.code, '\t'.code, 0xA0/*Non-breaking space*/:
				//:nop
			default:
				return i;
			}
		}
		return len;
	}

	public static function trim_WS(text: Array<String>)
	{
		var len = text.length;
		if (len <= 0)
			return;
		if (1 == len)
		{
			text[0] = StringTools.trim(text[0]);
			return;
		}
		//:detect common whitespace
		var s = text[0];
		var common_ws_len = Json5Util.get_String_LSpace(s);
		if (common_ws_len > 0)
		{
			var ws_sample: String = s.substr(0, common_ws_len);
			for (i in 1...len)
			{
				s = text[i];
				var k = s.length;
				if (common_ws_len > k)
					common_ws_len = k;
				if (common_ws_len <= 0)
					break;
				for (j in 0...common_ws_len)
				{
					if (s.charCodeAt(j) != ws_sample.charCodeAt(j))//:avoid deal with unknown tab size
					{
						common_ws_len = j;
						break;
					}
				}
			}
		}
		//:trim it now, trim trailing whitespace too
		for (i in 0...len)
		{
			s = text[i];
			if (common_ws_len > 0)
				s = s.substr(common_ws_len);
			var rt = StringTools.rtrim(s);
			if (rt.length > 0)
			{
				s = rt;
			}
			else if (i == len - 1)
			{//:kill last empty line
				text.pop();
				break;
			}
			text[i] = s;
		}
	}
}
