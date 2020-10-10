package;

import gs.json5mod.Json5;
import gs.json5mod.Json5Error;
import gs.json5mod.Json5Buf;
import gs.json5mod.Json5Util;
import gs.json5mod.Json5PrintOptions;
import gs.json5mod.Json5PrintFlags;
import haxe.EnumFlags;
import haxe.Json;
import haxe.crypto.Base64;
import massive.munit.Assert;

@:keep
class Json5ParseTest
{
	public function new()
	{}

	/**/
	@Test
	public function test_UTF8()
	{
		//:var utf8String = "\u4f60\u597d\uff0c\u4e16\u754c\uff01";// "你好，世界！" //:chin:Hello world!	//:utf8 literal may be broken in html with wrong charset
		var js = '"\\u4f60\\u597d\\uff0c\\u4e16\\u754c\\uff01"';
		var utf8String = Json.parse(js);
		Assert.areEqual(utf8String, Json5.parse(Json5.stringify(utf8String)).to_Any());
		Assert.areEqual(utf8String, Json5.parse(js).to_Any());

		var sb = new Json5Buf();
		sb.add_Chr_Utf8(0x4f60);
		sb.add_Chr_Utf8(0x597d);
		sb.add_Chr_Utf8(0xff0c);
		sb.add_Chr_Utf8(0x4e16);
		sb.add_Chr_Utf8(0x754c);
		sb.add_Chr_Utf8(0xff01);
		Assert.areEqual(utf8String, sb.toString());
	}

	@Test
	public function test_Float()
	{
		var s: String			=
'[ 123, -600, +5, 1.2, 1.2e3, 7.2e-3,  .5, 2.,  .5e2, 2.E-1,  -.4,  -.4e-2, 0, 1, -2, +3, 0e4, 0e-5, 6.7, .8, 9., .10e0, 11.12e+1, 13e0, 0.1e14, 0.0e15 ]';
		var a: Array<Dynamic>	=
 [ 123, -600,  5, 1.2, 1.2e3, 7.2e-3, 0.5,  2, 0.5e2,  2e-1, -0.4, -0.4e-2, 0, 1, -2,  3,   0,    0, 6.7, .8, 9.,    .1,    111.2,   13, 0.1e14,      0 ];
		var b: Array<Dynamic> = Json5.parse(s).to_Any();
		Assert.areEqual(a.length, b.length);
		for (i in 0...a.length)
		{
			Assert.areEqual(a[i], b[i]);
		}
	}

	@Test
	public function test_Bad_Float()
	{
		var arr: Array<String> =
		[
			"+", "-", ".", ".e1", "e1", "+-1", "-.+1", "..", "2-2", "1eE2", "001", "02.", ".5.5", "1e2e3",
			"1e-2e+3", "1e0.", "0e0-", "1e2.3", ".+2", "1.e", "1.e-", "1e", "1e-", "1e-3-1e-2", "1..", "1.e.e",
			"1e.", "1.e.1"
		];
		for (i in 0...arr.length)
		{
			var s: String = arr[i];
			var bad: Bool = true;
			try
			{
				var y = Json5.parse(s).to_Any();
				bad = false;
				//trace("ERROR: bad parse of '" + s + "'=" + y);
			}
			catch (err: Json5Error)
			{
			}
			Assert.isTrue(bad, s);
		}
	}

	@Test
	function test_Hex()
	{
		//:0xDEadBEaf cause error in cs target: Value was either too large or too small for an Int32.
		var s: String			=
//'[ 0x10, 0x0, 0x1FffFFff, 0xDEadBEaf, 0xc0c0, 0x304050 ]';
'[ 0x10, 0x0, 0x1FffFFff, 0x1EadBEaf, 0xc0c0, 0x304050 ]';
		var a: Array<UInt>	=
//[ 0x10, 0x0, 0x1FffFFff, 0xDEadBEaf, 0xc0c0, 0x304050 ];
 [ 0x10, 0x0, 0x1FffFFff, 0x1EadBEaf, 0xc0c0, 0x304050 ];
		var y: Array<Dynamic> = Json5.parse(s).to_Any();
		Assert.areEqual(a.length, y.length);
		for (i in 0...a.length)
		{
			var u: UInt = a[i] | 0;
			var v: UInt = y[i] | 0;
			Assert.areEqual(u, v);
		}
		//var t = Json5.parse("0xDEadBEaf").to_Any();
		//Assert.areEqual(0xDEadBEaf, t);
	}
	/**/

	/**/
	@Test
	public function test_Assets()
	{
		var map: Map<String, String> = Assets.map;
		var arr: Array<String> = [];
		for (key in map.keys())
		{
			if ((key.indexOf(".std") >= 0) || (key.indexOf(".print") >= 0))
				continue;
			arr.push(key);
		}
		arr.sort(sort_Ascending);
		var opt: Json5PrintOptions =
		{
			ident: '\t',
			space_after_colon: ' ',
			flags: Pretty | SortFields,
		};
		for (key in arr)
		{
			//if ("pass7" != key)
				//continue;
			trace("load asset: " + key + ".json");
			var should_fail = key.indexOf("fail") >= 0;
			var test: String = load_Text(map, key);
			if (should_fail)
			{
				var bad = true;
				try
				{
					Json5.parse(test);
					bad = false;
				}
				catch (err: Json5Error)
				{
					//trace(err.msg);
				}
				Assert.isTrue(bad, key);
				continue;
			}
			var obj = Json5.parse(test).to_Any();
			//if ("pass09_utf8_2" == key)
				//print(obj, opt);
			var js5 = Json5.stringify(obj, opt);
			var json_key = key + ".std";
			if (map.exists(json_key))
			{
				var json_std = load_Text(map, json_key);//:can not compare json_of_obj vs json_std because of platform-depended floats
				var obj_expected = Json.parse(json_std);
				var json_expected = Json.stringify(obj_expected, null, "  ");
				var json_of_obj = Json.stringify(obj, null, "  ");
				Util.dump_Strings_Diff(json_expected, json_of_obj);
				Assert.areEqual(json_expected, json_of_obj, "bad parse(1)");
				Assert.isTrue(Util.equal_Dynamics(obj_expected, obj), "bad parse(2)");

				var js5_of_std = Json5.stringify(obj_expected, opt);
				Assert.areEqual(js5_of_std, js5, "bad parse|stringify");
			}

			var print_key = key + ".print";
			if (map.exists(print_key))
			{
				var print_expected = load_Text(map, print_key);
				Util.dump_Strings_Diff(print_expected, js5);
				Assert.areEqual(print_expected, js5, "bad stringify");
			}
		}
	}

	function print(obj: Dynamic, opt: Json5PrintOptions)
	{
		var js5 = Json5.stringify(obj, opt);
		trace("\n=8<=====\n" + js5 + "\n=>8=====");
	}

	/**/
	static function sort_Ascending(a: String, b: String): Int
	{//:assume a != b
		if (a.toLowerCase() < b.toLowerCase())
			return -1;
		else
			return 1;
	}

	function load_Text(map: Map<String, String>, key: String): String
	{
		var hex: String = map[key];
		//trace("map[" + key + "] = " + hex);
		//:var text = Bytes.ofHex(hex).toString();//required haxe 4.preview5
		var text = Base64.decode(hex).toString();
		if (key.indexOf(".print") > 0)
		{
			text = StringTools.replace(text, "\r\n", "\n");
			text = StringTools.replace(text, "\r", "\n");
			text = reprint_Float(text);
			//trace("print:");
			//trace(text);
			//trace("_____");
		}
		//trace("DECODE map[" + key + "] = " + text);
		return decode_BOM(text);
	}

	function reprint_Float(s: String) : String
	{//:adopt float to this platform
		var r = ~/\$<float>(.+)<\/float>\$/g;
		return r.map(s, function(e)
		{
			return Std.string(Std.parseFloat(r.matched(1)));
		});
	}

	function decode_BOM(s: String): String
	{
		var cc = StringTools.fastCodeAt(s, 0);
		switch(cc)
		{
		case 0xfeFF:
			return s.substr(1);
		case 0xef:
			cc = StringTools.fastCodeAt(s, 1);
			switch(cc)
			{
			case 0xbb:
				cc = StringTools.fastCodeAt(s, 2);
				switch(cc)
				{
				case 0xbf:
					//TODO fix me
					//??return haxe.Utf8.decode(s);
					return s.substr(3);
				}
			}
		}
		return s;
	}
	/**/

}