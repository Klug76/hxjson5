package gs.json5mod;

import gs.json5mod.Json5Ast;
using gs.json5mod.Json5PrintFlags;
using gs.json5mod.Json5PrintOptions;

@:enum
private abstract NodeType(Int) from Int to Int
{
	var NODE_OBJ_BEGIN			= 0;
	var NODE_OBJ_KEY			= 1;
	var NODE_COLON				= 2;
	var NODE_DELIMITER			= 3;
	var NODE_VALUE				= 4;
	var NODE_OBJ_END			= 5;
	var NODE_ARRAY_BEGIN		= 6;
	var NODE_ARRAY_ITEM			= 7;
	var NODE_ARRAY_END			= 8;
	var NODE_ML_STRING_BEGIN	= 9;
	var NODE_ML_STRING_END		= 10;
	var NODE_ML_VALUE			= 11;
}

@:enum
private abstract NodeFlags(Int) from Int to Int
{
	var NODE_MASK				= 0x00FF;
	var FLAG_APOS				= 0x0100;
	var FLAG_QUOTE				= 0x0200;
}

@:enum
private abstract InternalFlags(Int) from Int to Int
{
	var FLAG_NOT_EOL	= 0x0001;
	var FLAG_PAD		= 0x0002;
}

private typedef TextNode =
{
	s_: String,
	flags_: Int//NodeType | NodeFlags
}

class Json5Printer
{
	var ident_: String;
	var space_before_colon_: String;
	var space_after_colon_: String;
	var tracer_: Json5PrintCallback;
	var width_limit_: Int;
	//?inline_array_limit
	//?inline_object_limit
	var print_flags_: Json5PrintFlags;
	var flags__: InternalFlags;
	var buf__: Json5Buf;
	var aux_buf_: Json5Buf;
	var row__: Int;
	var ref_: Array<Dynamic>;
	var node_: Array<TextNode>;

	static private var ml_quote_ = "```";

	public function new()
	{}

	public function print(value: Dynamic, ?options: Json5PrintOptions): String
	{
		ident_ =
			space_before_colon_ =
			space_after_colon_ = "";
		tracer_ = null;
		width_limit_ = 128;
		print_flags_ = Compact;
		if (options != null)
		{
			if (options.tracer != null)
				tracer_ = options.tracer;
			if (options.ident != null)
				ident_ = options.ident;
			if (options.space_before_colon != null)
				space_before_colon_ = options.space_before_colon;
			if (options.space_after_colon != null)
				space_after_colon_ = options.space_after_colon;
			if (options.width_limit != null)
				width_limit_ = options.width_limit;
			print_flags_ = options.flags;
		}
		//trace("******flags_ =0x" + StringTools.hex(print_flags_.toInt(), 4));
		flags__ = 0;
		buf__ = new Json5Buf();
		row__ = 0;
		ref_ = [];
		node_ = [];
		//:pre-process
		var type = Type.typeof(value);
		if (is_Printable_Type(type))
		{
			print_Dynamic("", type, value);
		}
		else
		{
			die("unable to encode provided obj");
		}
		//:now print
		build_Text();
		if (tracer_ != null)
		{
			//:flush
			if (buf__.length > 0)
				tracer_(buf__.toString());
			return null;
		}
		else
		{
			return buf__.toString();
		}
	}

	function print_Dynamic(key: String, type: Type.ValueType, v: Dynamic): Void
	{
		switch (type)
		{
		case TObject:
			print_Object(key, v);
		case TClass(c):
			if(c == String)
				print_String(v);
			else
			if ((c == Array) || (c == List))
				print_Iterable(key, v);
			else
			if (c == Json5Ast)
				print_Ast(v);
			//else
			//if (c == haxe.ds.StringMap)
				//print_Map(v);
			else
				print_Class(key, v);
		case TEnum(_):
			print_Enum(v);
		case TInt:
			print_Int(v);
		case TFloat:
			print_Float(v);
		case TBool:
			print_Bool(v);
		case TNull:
			push(NODE_VALUE, "null");
		case TFunction:
			//:nop
		case TUnknown://:var x = null
			//:nop
		}
	}

	function print_Ast(node: Json5Ast): Void
	{
		switch (node.value_)
		{
			case JNull:
				push(NODE_VALUE, "null");
			case JString(s):
				print_String(s);
			case JBool(bool):
				print_Bool(bool);
			case JNumber(s):
				push(NODE_VALUE, s);
			case JHex(u):
				print_UInt(u);
			case JIntRange(s):
				push(NODE_VALUE, s);
			case JObject(fields, _):
				print_Ast_Fields(fields);
			case JArray(values):
				print_Ast_Array(values);
		}
	}

	function is_Printable_Type(type: Type.ValueType): Bool
	{
		switch (type)
		{
		case TFunction, TUnknown:
			return false;
		default:
			return true;
		}
	}

	function get_Object_Fields(v: Dynamic): Array<String>
	{
		//TODO how to filter? rtti is sux
		return Reflect.fields(v);
	}

	function print_Object(key: String, v: Dynamic) : Void
	{
		var field: Array<String> = get_Object_Fields(v);
		print_Fields(key, v, field);
	}

	function get_Class_Fields(v: Dynamic): Array<String>
	{
		//TODO how to filter? rtti is sux
		return Type.getInstanceFields(Type.getClass(v));
	}

	function print_Class(key: String, v: Dynamic) : Void
	{
		var field: Array<String> = get_Class_Fields(v);
		print_Fields(key, v, field);
	}

	function print_Fields(name: String, v: Dynamic, field: Array<String>) : Void
	{
		//:prepare
		if (ref_.indexOf(v) >= 0)
		{
#if debug
			trace("WARNING: circular reference detected in '" + name + "'");
#end
			return;
		}
		ref_.push(v);
		var len: Int = field.length;
		if ((len > 1) && print_flags_.has(SortFields))
		{
			field.sort(sort_Ascending);
			//trace(field.join(":"));
		}
		//:print
		push(NODE_OBJ_BEGIN);
		var k: Int = 0;
		for (i in 0...len)
		{
			var key: String = field[i];
			var value: Dynamic = Reflect.field(v, key);
			var type = Type.typeof(value);
			if (!is_Printable_Type(type))
				continue;
			if (k++ > 0)
			{
				push(NODE_DELIMITER);
			}
			print_Key(key);
			push(NODE_COLON);
			print_Dynamic(key, type, value);
		}
		push(NODE_OBJ_END);
		ref_.pop();
	}

	function print_Ast_Fields(field: Array<Json5Field>) : Void
	{
		//:prepare
		var len: Int = field.length;
		if ((len > 1) && print_flags_.has(SortFields))
		{
			field = field.copy();
			field.sort(sort_Ast_Ascending);
			//trace(field.join(":"));
		}
		//:print
		push(NODE_OBJ_BEGIN);
		for (i in 0...len)
		{
			var f: Json5Field = field[i];
			if (i > 0)
			{
				push(NODE_DELIMITER);
			}
			print_Key(f.name_);
			push(NODE_COLON);
			print_Ast(f.value_);
		}
		push(NODE_OBJ_END);
	}

	function print_Iterable(name: String, arr: Iterable<Dynamic>): Void
	{
#if debug
		name += "[]";
#end
		var it = arr.iterator();
		push(NODE_ARRAY_BEGIN);
		var k: Int = 0;
		for (value in it)
		{
			var type = Type.typeof(value);
			if (!is_Printable_Type(type))
				continue;
			if (k++ > 0)
			{
				push(NODE_DELIMITER);
			}
			push(NODE_ARRAY_ITEM);
			print_Dynamic(name, type, value);
		}
		push(NODE_ARRAY_END);
	}

	function print_Ast_Array(arr: Array<Json5Ast>): Void
	{
		push(NODE_ARRAY_BEGIN);
		var k: Int = 0;
		for (value in arr)
		{
			if (k++ > 0)
			{
				push(NODE_DELIMITER);
			}
			push(NODE_ARRAY_ITEM);
			print_Ast(value);
		}
		push(NODE_ARRAY_END);
	}

	inline function print_Int(v: Int): Void
	{
		push(NODE_VALUE, Std.string(v));
	}

	inline function print_UInt(u: UInt): Void
	{
		push(NODE_VALUE, "0x" + StringTools.hex(u));
	}

	inline function print_Float(v: Float): Void
	{
		push(NODE_VALUE, if (Math.isFinite(v)) Std.string(v) else "null");
	}

	inline function print_Bool(v: Bool): Void
	{
		push(NODE_VALUE, v ? "true" : "false");
	}

	function print_Enum(v: Dynamic): Void
	{
		//:NOTE: enum args lost
		print_Int(Type.enumIndex(v));//:TODO option: useEnumIndex like in haxe.Serializer?
	}

	static private inline var STRING_NEED_ESCAPE	= 0x0001;
	static private inline var STRING_HAS_CR			= 0x0002;
	static private inline var STRING_HAS_LF			= 0x0004;
	static private inline var STRING_HAS_APOS		= 0x0008;
	static private inline var STRING_HAS_QUOTE		= 0x0010;
	static private inline var STRING_HAS_TAB		= 0x0020;
	static private inline var STRING_HAS_BS			= 0x0040;
	static private inline var STRING_HAS_3_ACCENT	= 0x0080;

	static function analyze_String(v: String): Int
	{
		var result = 0;
		var len = v.length;
		var accent = 0;
		for (i in 0...len)
		{
			var cc: Int = StringTools.fastCodeAt(v, i);
			switch(cc)
			{
			case '`'.code:
				if (++accent == 3)
					result |= STRING_HAS_3_ACCENT;
			default:
				accent = 0;
			}
			switch(cc)
			{
			case '\t'.code:
				result |= STRING_HAS_TAB;
			case '\r'.code:
				result |= STRING_HAS_CR;
			case '\n'.code:
				result |= STRING_HAS_LF;
			case '\\'.code:
				result |= STRING_HAS_BS;
			case "'".code:
				result |= STRING_HAS_APOS;
			case '"'.code:
				result |= STRING_HAS_QUOTE;
			default:
				//TODO review: unicode ws
				if (cc < ' '.code)
					result |= STRING_NEED_ESCAPE;
			}
		}
		return result;
	}

	function escape_String(v: String, exclude: Array<Int>) : String
	{
		var buf: Json5Buf = get_Aux_Buf();
		var len = v.length;
		var begin = 0;
		for (i in 0...len)
		{
			var cc: Int = StringTools.fastCodeAt(v, i);
			if (exclude.indexOf(cc) >= 0)
				continue;
			inline function add(s: String)
			{
				buf.add_Sub(v, begin, i - begin);
				buf.add_Str(s);
				begin = i + 1;
			}
			switch(cc)
			{
			case '\t'.code:
				add("\\t");
			case '\r'.code:
				add("\\r");
			case '\n'.code:
				add("\\n");
			case '\\'.code:
				add("\\\\");
			case "'".code:
				add("\\'");
			case '"'.code:
				add('\\"');
			default:
				if (cc < ' '.code)
				{
					add("\\u" + StringTools.hex(cc, 4));
				}
			}
		}
		buf.add_Sub(v, begin, len - begin);
		return buf.toString();
	}

	function get_Aux_Buf() : Json5Buf
	{
		if (null == aux_buf_)
			aux_buf_ = new Json5Buf();
		else
			aux_buf_.clear();
		return aux_buf_;
	}

	function print_String(v: String): Void
	{
		var sflags = analyze_String(v);
		if (print_flags_.has(AllowMultilineStrings) && ((sflags & (STRING_HAS_CR | STRING_HAS_LF)) != 0) &&
			((sflags & (STRING_HAS_3_ACCENT | STRING_NEED_ESCAPE)) == 0))
		{
			if ((sflags & STRING_HAS_CR) != 0)
			{
				v = StringTools.replace(v, "\r\n", "\n");
				v = StringTools.replace(v, "\r", "\n");
			}
			var arr: Array<String> = v.split('\n');
			print_ML_String(arr, sflags);
			return;
		}
		print_Quoted_String(v, sflags);
	}

	function print_ML_String(arr: Array<String>, sflags: Int): Void
	{
		push(NODE_ML_STRING_BEGIN);
		var len: Int = arr.length;
		for (i in 0...len)
		{
			var s = arr[i];
			var rt = StringTools.rtrim(s);
			if (rt.length > 0)
				s = rt;
			//trace("push '" + s + "'");
			push(NODE_ML_VALUE, s);
		}
		push(NODE_ML_STRING_END);
	}

	function print_Quoted_String(s: String, sflags: Int): Void
	{
		//trace("print_Quoted_String(" + s + ", 0x" + StringTools.hex(sflags, 4));
		var q = FLAG_QUOTE;
		var e = "'".code;
		var tf = sflags & (STRING_HAS_APOS | STRING_HAS_QUOTE);
		if (tf == STRING_HAS_QUOTE)
		{
			q = FLAG_APOS;
			e = '"'.code;
		}
		else if (tf == (STRING_HAS_APOS | STRING_HAS_QUOTE))
		{
			sflags |= STRING_NEED_ESCAPE;
		}
		if (print_flags_.has(EscapeTab) && ((sflags & STRING_HAS_TAB) != 0))
			sflags |= STRING_NEED_ESCAPE;
		if ((sflags & (STRING_NEED_ESCAPE | STRING_HAS_CR | STRING_HAS_LF | STRING_HAS_BS)) != 0)
		{
			var exclude_char = [e];
			if (!print_flags_.has(EscapeTab))
				exclude_char.push('\t'.code);
			var es = escape_String(s, exclude_char);
			//trace("push escaped '" + es + "'");
			push(NODE_VALUE | q, es);
		}
		else
		{
			//trace("push '" + s + "'");
			push(NODE_VALUE | q, s);
		}
	}

	function need_Quoted_Key(v: String) : Bool
	{
		var len: Int = v.length;
		for (i in 0...len)
		{
			var cc: Int = StringTools.fastCodeAt(v, i);
			if (!Json5Util.is_Valid_Key_Char(cc, i == 0))
				return true;
		}
		return false;
	}

	inline function print_Key(v: String): Void
	{
		push(NODE_OBJ_KEY);
		if (need_Quoted_Key(v))
		{
			var sflags = analyze_String(v);
			print_Quoted_String(v, sflags);
		}
		else
		{
			push(NODE_VALUE, v);
		}
	}

	function push(node: Int, s: String = null): Void
	{
		//trace({var log = node_.length + "\tput " + node_type; if (s != null) log += ", '" + s + "'"; log;});
		var t: TextNode = { s_: s, flags_: node };
		node_.push(t);
	}

	function build_Text()
	{
		var level: Int = 0;
		var prev_type: Int = -1;
		var len = node_.length;
		for(i in 0...len)
		{
			var it: TextNode = node_[i];
			var type: NodeType = it.flags_ & NODE_MASK;
			switch(type)
			{
			case NODE_OBJ_BEGIN:
				add_Code('{'.code);
				++level;
			case NODE_OBJ_END:
				--level;
				if (print_flags_.has(Pretty) && (prev_type != NODE_OBJ_BEGIN))
				{
					add_Eol();
					pad(level);
				}
				add_Code('}'.code);
			case NODE_OBJ_KEY:
				if (print_flags_.has(Pretty))
				{
					add_Eol();
					pad(level);
				}
			case NODE_COLON:
				add_Str(space_before_colon_);
				add_Code(':'.code);
				if (eol_After_Colon(i + 1))
				{
					add_Eol();
					if (print_flags_.has(Pretty))
						pad(level);
				}
				else
				{
					add_Str(space_after_colon_);
				}
			case NODE_ARRAY_BEGIN:
				add_Code('['.code);
				++level;
			case NODE_ARRAY_END:
				--level;
				if (print_flags_.has(Pretty) && (prev_type != NODE_ARRAY_BEGIN))
				{
					add_Eol();
					pad(level);
				}
				add_Code(']'.code);
			case NODE_ARRAY_ITEM:
				if (print_flags_.has(Pretty))
				{
					add_Eol();
					pad(level);
				}
			case NODE_DELIMITER:
				add_Delimiter(prev_type, i + 1);
			case NODE_VALUE:
				add_Quote(it.flags_);
				add_Value(it);
				add_Quote(it.flags_);
//`````````````````````````````````````````````````````````````
			case NODE_ML_STRING_BEGIN:
				add_Eol();
				if (print_flags_.has(Pretty))
					pad(level);
				add_Str(ml_quote_);
				add_Eol();
			case NODE_ML_VALUE:
				if (print_flags_.has(Pretty))
					pad(level);
				add_Value(it);
				add_Eol();
			case NODE_ML_STRING_END:
				if (print_flags_.has(Pretty))
					pad(level);
				add_Str(ml_quote_);
				if (!print_flags_.has(Pretty))
					add_Eol();
//`````````````````````````````````````````````````````````````
			}
			prev_type = type;
		}
	}

	function eol_After_Colon(i: Int): Bool
	{
		if (!print_flags_.has(Pretty))
			return false;
		if (print_flags_.has(OpenBraceSameLine))
			return false;
		var it: TextNode = node_[i];
		var type: NodeType = it.flags_ & NODE_MASK;
		switch(type)
		{
		case NODE_OBJ_BEGIN:
			if (get_Node_Type(i + 1) == NODE_OBJ_END)
				return false;//:empty
			return true;
		case NODE_ARRAY_BEGIN:
			if (get_Node_Type(i + 1) == NODE_ARRAY_END)
				return false;//:empty
			return true;
		default:
		}
		return false;
	}

	inline function add_Delimiter(prev: NodeType, i: Int): Void
	{
		if (print_flags_.has(Pretty))
			return;
		switch(prev)
		{
		case NODE_VALUE:
			switch(get_Node_Type(i))
			{
			case NODE_OBJ_KEY:
				add_Code(' '.code);
			case NODE_ARRAY_ITEM:
				switch(get_Node_Type(i + 1))
				{
				case NODE_VALUE:
					add_Code(' '.code);
				default:
				}
			default:
			}
		default:
		}
	}

	inline function get_Node_Type(i: Int): NodeType
	{
		var it: TextNode = node_[i];
		return it.flags_ & NODE_MASK;
	}

	inline function add_Quote(flags: Int): Void
	{
		if ((flags & FLAG_APOS) != 0)
			buf__.add_Chr("'".code);
		else if ((flags & FLAG_QUOTE) != 0)
			buf__.add_Chr('"'.code);
	}

	inline function add_Code(cc: Int): Void
	{
		buf__.add_Chr(cc);
		flags__ |= FLAG_NOT_EOL;
	}

	inline function add_Str(v: String): Void
	{
		buf__.add_Str(v);
		flags__ |= FLAG_NOT_EOL;
	}

	inline function add_Value(it: TextNode): Void
	{
		buf__.add_Str(it.s_);
		flags__ |= FLAG_NOT_EOL;
	}

	function add_Eol(): Void
	{
		if ((flags__ & FLAG_NOT_EOL) == 0)
			return;
		++row__;
		flags__ = 0;
		if (tracer_ != null)
		{
			if (row__ % 16 == 0)//:avoid FD trace overflow
			{
				if (!print_flags_.has(ModeTraceCompatible))//:NOTE: haxe::trace|Sys.println will add \n
					buf__.add_Chr('\n'.code);
				tracer_(buf__.toString());
				buf__.clear();
				return;
			}
		}
		buf__.add_Chr('\n'.code);
	}

	inline function pad(level: Int): Void
	{
		if ((flags__ & FLAG_PAD) != 0)
			return;
		flags__ |= FLAG_PAD;
		var count = level * ident_.length;
		if (count > 0)
		{
			buf__.add_Str(StringTools.lpad('', ident_, count));
		}
	}

	function die(msg: String)
	{
		throw new Json5Error("ERROR: " + msg, 0, 0, 0);
	}

	static function sort_Ascending(a: String, b: String): Int
	{//:assume a != b
		if (a.toLowerCase() < b.toLowerCase())
			return -1;
		else
			return 1;
	}

	static function sort_Ast_Ascending(a: Json5Field, b: Json5Field): Int
	{//:assume a != b
		if (a.name_.toLowerCase() < b.name_.toLowerCase())
			return -1;
		else
			return 1;
	}

}