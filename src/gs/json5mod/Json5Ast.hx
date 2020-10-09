package gs.json5mod;

//:based on https://github.com/nadako/hxjsonast

/*
	fancy @:structInit syntax instead of classic `new` operator:
	var ast: Json5Ast =
	{
		value: JString("foo"),
	}
*/

@:structInit
class Json5Ast
{
	public var value_: Json5Value;

	public static var NULL_NODE = new Json5Ast(JNull);

	public inline function new(value: Json5Value)
	{
		value_ = value;
	}

	public function to_String(): String
	{
		return switch (value_)
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
		return switch (value_)
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
		case JObject(fields, _):
			var result = {};
			for (field in fields)
				Reflect.setField(result, field.name_, field.value_.to_Any());
			result;
		case JArray(values):
			[for (it in values) it.to_Any()];
		}
	}

	public inline function get_Field(name: String): Json5Ast
	{
		switch(value_)
		{
		case JObject(_, names):
			var fi = names.get(name);
			if (null == fi)
				return NULL_NODE;
			return fi.value_;
		default:
			return NULL_NODE;
		}
	}

	public function get_String(name: String, def: String): String
	{
		var node = get_Field(name);
		switch (node.value_)
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
		switch (node.value_)
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
		switch (node.value_)
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
		switch (node.value_)
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
		switch (node.value_)
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

	public function get_Array(name: String): Array<Json5Ast>
	{
		var node = get_Field(name);
		switch (node.value_)
		{
		case JNull:
			return null;
		case JArray(values):
			return values;
		default:
#if debug
			trace('WARNING: bad Array "$name"');
#end
			return null;
		}
	}

	public function get_Object(name: String): Array<Json5Field>
	{
		var node = get_Field(name);
		switch (node.value_)
		{
		case JNull:
			return null;
		case JObject(fields, _):
			return fields;
		default:
#if debug
			trace('WARNING: bad Object "$name"');
#end
			return null;
		}
	}
}

enum Json5Value
{
	JString(s: String);
	JHex(u: UInt);
	JNumber(s: String);
	JIntRange(s: String);//:json5 mod
	JObject(fields: Array<Json5Field>, names: Map<String, Json5Field>);
	JArray(values: Array<Json5Ast>);
	JBool(b: Bool);
	JNull;
}

@:structInit
class Json5Field
{
	public var name_: String;
	public var value_: Json5Ast;

	public inline function new(name: String, value: Json5Ast)
	{
		name_ = name;
		value_ = value;
	}
}
