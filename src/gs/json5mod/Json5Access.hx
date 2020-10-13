package gs.json5mod;

import gs.json5mod.Json5Ast;

abstract Json5Access(Json5Ast) from Json5Ast to Json5Ast
{
	public inline function new(value: Json5Ast)
	{
		this = value;
	}

	public function to_String(): String
	{
		return switch (this)
		{
		case JString(string):
			string;
		default:
#if debug
			trace('WARNING: bad String');
#end
			null;
		}
	}

	public function to_Any(): Any
	{
		return switch (this)
		{
		case JNull:
			null;
		case JString(string):
			string;
		case JBool(bool):
			bool;
		case JNumber(s):
			Std.parseFloat(s);
		case JHex(u):
			u;
		case JIntRange(string):
			string;
		case JObject(arr, _):
			var result = {};
			for (fi in arr)
			{
				switch (fi)
				{
				case JObjectField(key, value):
					//:assume non-empty key (see Json5Parser::parse_Field)
					Reflect.setField(result, key, new Json5Access(value).to_Any());
				default:
				}
			}
			result;
		case JArray(values):
			[for (it in values) new Json5Access(it).to_Any()];
		case JObjectField(_, _):
			null;//:unexpected
		}
	}

	public inline function get_Field(key: String): Json5Access
	{
		switch (this)
		{
		case JNull:
			return JNull;
		case JObject(_, map):
			var fi = map.get(key);
			if (fi != null)
			{
				switch (fi)
				{
				case JObjectField(_, value):
					return value;
				default://:unexpected
					return JNull;
				}
			}
			return JNull;
		default:
#if debug
			trace('WARNING: bad Object');
#end
			return JNull;
		}
	}

	public function get_String(name: String, def: String): String
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return def;
		case JString(s):
			return s;
		default:
#if debug
			trace('WARNING: bad String "$name"');
#end
			return def;
		}
	}

	public function get_Int(name: String, def: Int): Int
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return def;
		case JNumber(s):
			var f = Std.parseFloat(s);
			var i = Std.parseInt(s);
			if (i == f)
				return Std.int(i);
#if debug
			trace('WARNING: bad Int (got Float) "$name"');
#end

			return def;
		default:
#if debug
			trace('WARNING: bad Int "$name"');
#end
			return def;
		}
	}

	public function get_UInt(name: String, def: UInt): UInt
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return def;
		case JHex(u):
			return u;
		case JNumber(s):
			var f = Std.parseFloat(s);
			var i = Std.parseInt(s);
			if (i == f)
				return Std.int(i);
#if debug
			trace('WARNING: bad UInt (got Float) "$name"');
#end
			return def;
		default:
#if debug
			trace('WARNING: bad UInt "$name"');
#end
			return def;
		}
	}

	public function get_Float(name: String, def: Float): Float
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return def;//TODO review: return NaN?
		case JNumber(s):
			return Std.parseFloat(s);
		default:
#if debug
			trace('WARNING: bad Float "$name"');
#end
			return def;
		}
	}

	public function get_Bool(name: String, def: Bool): Bool
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return def;
		case JBool(b):
			return b;
		default:
#if debug
			trace('WARNING: bad Bool "$name"');
#end
			return def;
		}
	}

	public function get_Array(name: String): Array<Json5Access>
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return null;
		case JArray(values):
			return cast values;
		default:
#if debug
			trace('WARNING: bad Array "$name"');
#end
			return null;
		}
	}

	public function get_Object(name: String): Array<Json5Access>
	{
		var node = get_Field(name);
		switch (node)
		{
		case JNull:
			return null;
		case JObject(fields, _):
			return cast fields;
		default:
#if debug
			trace('WARNING: bad Object "$name"');
#end
			return null;
		}
	}
}
