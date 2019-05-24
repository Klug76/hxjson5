package gs.json5mod;

import haxe.ds.StringMap;
import gs.json5mod.Json5Ast;

@:enum private abstract StateFlags(Int)
{
	var STATE_PARSE_VALUE				= 0;
	var STATE_PARSE_ARRAY				= 1;
	var STATE_PARSE_ARRAY_END			= 2;
	var STATE_PARSE_ARRAY_DELIMITER		= 3;//:space, comma, comment, or even nothing in some cases e.g. [{}{}]
	var STATE_PARSE_OBJ_DELIMITER		= 4;
	var STATE_PARSE_OBJ					= 5;
	var STATE_PARSE_KEY					= 6;
	var STATE_PARSE_COLON				= 7;
	var STATE_PARSE_OBJ_END				= 8;
	var STATE_PARSE_TAIL				= 9;
}

class Json5Parser
{
	var js_: String;
	var pos_: Int;
	var row_: Int;
	var col_: Int;
	var flags_: Int;
	var state_: StateFlags = STATE_PARSE_VALUE;
	//var state_(default, set): StateFlags = STATE_PARSE_VALUE;

	static inline var FLAG_SPACE = 0x0001;
	static inline var FLAG_COMMA = 0x0002;

	public function new() {}

	public function parse(js: String) : Json5Ast
	{
		if (null == js)
			js = "";
		js_ = js;
		pos_ = 0;
		row_ = 0;
		col_ = 0;
		flags_ = 0;
		state_ = STATE_PARSE_VALUE;
		//trace("'{.code'==0x" + StringTools.hex('{'.code, 2));
		//trace("js[0]='" + js.substr(0, 1) + "', code==0x" + StringTools.hex(cur_Char_Code(), 2));
		var result = do_Parse(Json5Ast.NULL_NODE);
		state_ = STATE_PARSE_TAIL;
		do_Parse(Json5Ast.NULL_NODE);//:eat trailing whitespace, comments, commas
		return result;
	}

/**/
#if debug
	function set_state_(value: StateFlags) : StateFlags
	{
		trace("set state from " + dump_State(state_) + " to " + dump_State(value));
		state_ = value;
		return value;
	}

	function dump_State(value: StateFlags) : String
	{
		switch(value)
		{
		case STATE_PARSE_VALUE:				return "STATE_PARSE_VALUE";
		case STATE_PARSE_ARRAY:				return "STATE_PARSE_ARRAY";
		case STATE_PARSE_ARRAY_END:			return "STATE_PARSE_ARRAY_END";
		case STATE_PARSE_ARRAY_DELIMITER:	return "STATE_PARSE_ARRAY_DELIMITER";
		case STATE_PARSE_OBJ_DELIMITER:		return "STATE_PARSE_OBJ_DELIMITER";
		case STATE_PARSE_OBJ:				return "STATE_PARSE_OBJ";
		case STATE_PARSE_KEY:				return "STATE_PARSE_KEY";
		case STATE_PARSE_COLON:				return "STATE_PARSE_COLON";
		case STATE_PARSE_OBJ_END:			return "STATE_PARSE_OBJ_END";
		case STATE_PARSE_TAIL:				return "STATE_PARSE_TAIL";
		}
	}
#end
/**/

	inline function read_Char_Code(): Int
	{
		++col_;
		return StringTools.fastCodeAt(js_, pos_++);
	}

	inline function peek_Char_Code(): Int
	{
		return StringTools.fastCodeAt(js_, pos_);
	}

	inline static function is_Eof(cc: Int): Bool
	{
		return StringTools.isEof(cc);
	}

	inline function go_Back()
	{
		--pos_;
		--col_;
	}

	function do_Parse(parent: Json5Ast): Json5Ast
	{
		while (true)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
				return Json5Ast.NULL_NODE;
			//trace("do_Parse, cc='" + String.fromCharCode(cc) + "'==0x" + StringTools.hex(cc));
			switch(cc)
			{
			case ' '.code, '\t'.code, 0xA0/*Non-breaking space*/:
				//TODO may be if \t col_ += TAB_SIZE - 1?
				flags_ |= FLAG_SPACE;
			case '\r'.code, '\n'.code:
				parse_Eol(cc);
				flags_ |= FLAG_SPACE;
			case '{'.code:
				switch(state_)
				{
				case STATE_PARSE_VALUE, STATE_PARSE_ARRAY:
					//:we need to go deeper
					return parse_Object();//:----------------------------
				case STATE_PARSE_ARRAY_DELIMITER:
					state_ = STATE_PARSE_ARRAY;//:allow [{}{}]
					return parse_Object();//:----------------------------
				default:
					die(cc);
				}
			case '}'.code:
				switch(state_)
				{
				case STATE_PARSE_OBJ, STATE_PARSE_OBJ_DELIMITER:
					state_ = STATE_PARSE_OBJ_END;
				default:
					die(cc);
				}
				return Json5Ast.NULL_NODE;//:----------------------------
			case '['.code:
				switch(state_)
				{
				case STATE_PARSE_VALUE, STATE_PARSE_ARRAY:
					return parse_Array();//:----------------------------
				case STATE_PARSE_ARRAY_DELIMITER:
					state_ = STATE_PARSE_ARRAY;//:allow [[][]]
					return parse_Array();//:----------------------------
				default:
					die(cc);
				}
			case ']'.code:
				switch(state_)
				{
				case STATE_PARSE_ARRAY, STATE_PARSE_ARRAY_DELIMITER:
					state_ = STATE_PARSE_ARRAY_END;
				default:
					die(cc);
				}
				return Json5Ast.NULL_NODE;//:----------------------------
			case ':'.code:
				if (STATE_PARSE_COLON != state_)
					die(cc);
				return Json5Ast.NULL_NODE;//:----------------------------
			case ','.code:
				if ((flags_ & FLAG_COMMA) != 0)
					die(cc);
				switch(state_)
				{
				case STATE_PARSE_OBJ_DELIMITER:
					state_ = STATE_PARSE_OBJ;
				case STATE_PARSE_ARRAY_DELIMITER:
					state_ = STATE_PARSE_ARRAY;
				case STATE_PARSE_TAIL:
					//:nop
				default:
					die(cc);
				}
				flags_ |= FLAG_COMMA;
			case '#'.code:
				parse_Line_Comment();
			case '/'.code:
				cc = read_Char_Code();
				switch(cc)
				{
				case '/'.code:
					parse_Line_Comment();
				case '*'.code:
					parse_Block_Comment();
				default:
					die(cc);
				}
			//case '~'.code:
				//TODO parse regexp
			case '`'.code:
				switch(state_)
				{
				case STATE_PARSE_VALUE, STATE_PARSE_ARRAY:
					return new Json5Ast(JString(parse_ML_String()));//:----------------------------
				case STATE_PARSE_ARRAY_DELIMITER if (flags_ != 0):
					state_ = STATE_PARSE_ARRAY;
					return new Json5Ast(JString(parse_ML_String()));//:----------------------------
				default:
					die(cc);
				}
			case '"'.code, "'".code:
				switch(state_)
				{
				case STATE_PARSE_OBJ, STATE_PARSE_OBJ_DELIMITER:
					var key = parse_String(cc);//:sort of parse_Key()
					parse_Value(key, parent);
				case STATE_PARSE_VALUE, STATE_PARSE_ARRAY:
					return new Json5Ast(JString(parse_String(cc)));//:----------------------------
				case STATE_PARSE_ARRAY_DELIMITER if (flags_ != 0):
					state_ = STATE_PARSE_ARRAY;
					return new Json5Ast(JString(parse_String(cc)));//:----------------------------
				default:
					die(cc);
				}
			default:
				switch(state_)
				{
				case STATE_PARSE_OBJ, STATE_PARSE_OBJ_DELIMITER:
					var key = parse_Key(cc);
					parse_Value(key, parent);
				case STATE_PARSE_VALUE, STATE_PARSE_ARRAY, STATE_PARSE_ARRAY_DELIMITER:
					if (STATE_PARSE_ARRAY_DELIMITER == state_)
					{
						if (flags_ != 0)
							state_ = STATE_PARSE_ARRAY;
						else
							die(cc);
					}
					switch(cc)
					{
					case 'n'.code:
						parse_String_Literal(['n'.code, 'u'.code, 'l'.code, 'l'.code]);
						return Json5Ast.NULL_NODE;//:----------------------------
					case 'N'.code:
						parse_String_Literal(['N'.code, 'a'.code, 'N'.code]);
						//:explicit NaN not exist in some targets
						return Json5Ast.NULL_NODE;//:----------------------------
					case 'f'.code:
						parse_String_Literal(['f'.code, 'a'.code, 'l'.code, 's'.code, 'e'.code]);
						return new Json5Ast(JBool(false));//:----------------------------
					case 't'.code:
						parse_String_Literal(['t'.code, 'r'.code, 'u'.code, 'e'.code]);
						return new Json5Ast(JBool(true));//:----------------------------
					}
					go_Back();
					return parse_Number();//:----------------------------
				default:
					die(cc);
				}
			}
		}
	}

	function parse_Eol(cc: Int)
	{
		if ('\r'.code == cc)
		{
			cc = peek_Char_Code();
			if ('\n'.code == cc)//:eat usual '\r\n'
				++pos_;
		}
		++row_;
		col_ = 0;
	}

	function parse_Line_Comment()
	{
		flags_ |= FLAG_SPACE;
		while (true)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
				break;
			switch(cc)
			{
			case '\r'.code, '\n'.code:
				parse_Eol(cc);
				return;
			default:
				//:nop
			}
		}
	}

	function parse_Block_Comment()
	{
		flags_ |= FLAG_SPACE;
		while (true)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
				break;
			switch(cc)
			{
			case '\r'.code, '\n'.code:
				parse_Eol(cc);
			case '*'.code:
				cc = read_Char_Code();
				if (cc == '/'.code)
					return;
			default:
				//:nop
			}
		}
		//?throw_Error_Ex
	}

	function parse_String_Literal(arr: Array<Int>)
	{
		for (i in 1...arr.length)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
				die_With_Msg("expected '" + Json5Util.Array2String(arr) + "'");
			if (cc != arr[i])
				die(cc);
		}
		//trace("parse literal " + MacroUtil.Code2String(arr) + ", cc='" + String.fromCharCode(peek_Char_Code()) + "'==0x" + StringTools.hex(peek_Char_Code()));
	}

	function parse_Key(cc: Int) : String
	{
		if (!Json5Util.is_Valid_Key_Char(cc, true))
			die(cc);
		state_ = STATE_PARSE_KEY;
		var begin = pos_ - 1;//:eat cc too
		while (true)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
			{
				die_With_Msg("expected field name");
			}
			if (!Json5Util.is_Valid_Key_Char(cc, false))
			{
				go_Back();
				return js_.substring(begin, pos_);
			}
		}
	}

	function parse_Value(key: String, parent: Json5Ast): Void
	{
		state_ = STATE_PARSE_COLON;
		do_Parse(Json5Ast.NULL_NODE);
		state_ = STATE_PARSE_VALUE;
		var value: Json5Ast = do_Parse(Json5Ast.NULL_NODE);
		switch (parent.value_)
		{
			case JObject(fields, names):
				if (names.exists(key))
					die_With_Msg("duplicate key '" + key + "'");
				var fi = new Json5Field(key, value);
				fields.push(fi);
				names.set(key, fi);
			default:
				die_With_Msg("bad parent node");
		}
		state_ = STATE_PARSE_OBJ_DELIMITER;
		flags_ = 0;
	}

	function parse_Object(): Json5Ast
	{
		//trace("ENTER parse obj");
		var old = state_;
		state_ = STATE_PARSE_OBJ;
		var fields = new Array<Json5Field>();
		var names = new StringMap<Json5Field>();
		var result = new Json5Ast(JObject(fields, names));
		do_Parse(result);
		if (state_ != STATE_PARSE_OBJ_END)
			die_With_Msg("expected '}'");
		state_ = old;
		//trace("LEAVE parse obj");
		return result;//:----------------------------
	}

	function parse_Array(): Json5Ast
	{
		var old = state_;
		state_ = STATE_PARSE_ARRAY;
		var arr = [];
		//trace("ENTER parse array");
		var result = new Json5Ast(JArray(arr));
		while (true)
		{
			var value = do_Parse(result);
			if (state_ != STATE_PARSE_ARRAY)
				break;
			//trace("	push " + Std.string(result));
			arr.push(value);
			state_ = STATE_PARSE_ARRAY_DELIMITER;
			flags_ = 0;
		}
		if (state_ != STATE_PARSE_ARRAY_END)
			die_With_Msg("expected ']'");
		state_ = old;
		//trace("LEAVE parse array");
		return result;
	}

	//static var reg_num = ~/^[-+]?(?:\d*[.]\d+|\d+[.]?\d*)(?:[eE][-+]?\d+)?/;
	//TODO use new EnumFlags?
	static private inline var SIGN		= 0x0001;
	static private inline var LEAD0		= 0x0002;
	static private inline var I_DIGIT	= 0x0004;
	static private inline var DOT		= 0x0008;
	static private inline var F_DIGIT	= 0x0010;
	static private inline var eE		= 0x0020;

	function parse_Number(): Json5Ast
	{
		var flags = 0;
		var begin = pos_;
		while (true)
		{
			var cc = read_Char_Code();
			if (is_Eof(cc))
				break;
			if (Json5Util.in_Closed_Interval(cc, '0'.code, '9'.code))
			{
				if ((flags & (LEAD0 | DOT | F_DIGIT)) == LEAD0)
					die(cc);
				if ((flags & DOT) != 0)
				{
					flags |= F_DIGIT;
					continue;
				}
				if (cc == '0'.code)
				{
					if ((flags & I_DIGIT) == 0)
						flags |= LEAD0 | I_DIGIT;
				}
				else
				{
					flags |= I_DIGIT;
				}
				continue;
			}
			switch(cc)
			{
			case '+'.code, '-'.code:
				if (flags != 0)
					die(cc);
				flags = SIGN;
			case '.'.code:
				if ((flags & DOT) != 0)
				{
					if ((flags & (I_DIGIT | F_DIGIT)) == I_DIGIT)
					{//:json5+ extension: Int range [a..b]
						return new Json5Ast(JIntRange(parse_Range(begin)));
					}
					die(cc);
				}
				flags |= DOT;
			case 'e'.code, 'E'.code:
				if ((flags & (I_DIGIT | F_DIGIT)) == 0)
					die(cc);
				parse_Int(true);
				flags |= eE;
				break;//:while
			case 'x'.code, 'X'.code:
				if ((flags & (SIGN | LEAD0 | DOT | F_DIGIT)) == LEAD0)
					return new Json5Ast(JHex(parse_Hex(0)));
				die(cc);
			default:
				go_Back();
				break;//:while
			}
		}
		if ((flags & (I_DIGIT | F_DIGIT)) == 0)
			die_With_Msg("expected number");
		var sub: String = js_.substring(begin, pos_);
		return new Json5Ast(JNumber(sub));
	}

	function parse_Int(parse_exponent: Bool): Void
	{
		//:NOTE:exponent may look like an octal literal but will always be interpreted using radix 10
		var begin = pos_;
		var flags = 0;
		while (true)
		{
			var cc = read_Char_Code();
			if (is_Eof(cc))
				break;
			if (Json5Util.in_Closed_Interval(cc, '0'.code, '9'.code))
			{
				if (!parse_exponent && ((flags & LEAD0) != 0))
					die(cc);
				if (cc == '0'.code)
				{
					if ((flags & I_DIGIT) == 0)
						flags |= LEAD0 | I_DIGIT;
				}
				else
				{
					flags |= I_DIGIT;
				}
				continue;
			}
			switch(cc)
			{
			case '+'.code, '-'.code:
				if (flags != 0)
					die(cc);
				flags |= SIGN;
			case 'x'.code, 'X'.code:
				if (!parse_exponent && ((flags & (SIGN | LEAD0)) == LEAD0))
				{
					parse_Hex(0);
					return;
				}
				die(cc);
			default:
				go_Back();
				break;//:while
			}
		}
		if ((flags & I_DIGIT) == 0)
			die_With_Msg(if (parse_exponent) "expected exponent value" else "expected int");
	}

	function parse_Hex(exact_limit: Int): UInt
	{//:eat positive hex only (yet)
		var begin = pos_ - 2;
		var result: UInt = 0;
		for (i in 0...8)
		{
			if ((exact_limit != 0) && (i == exact_limit))
				break;
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
			{
				if (exact_limit != 0)
					die_With_Msg("expected hex");
				else
					break;
			}

			var add: Int;
			if (Json5Util.in_Closed_Interval(cc, '0'.code, '9'.code))
				add = cc - '0'.code;
			else
			if (Json5Util.in_Closed_Interval(cc, 'a'.code, 'f'.code))
				add = cc - 'a'.code + 10;
			else
			if (Json5Util.in_Closed_Interval(cc, 'A'.code, 'F'.code))
				add = cc - 'A'.code + 10;
			else
			{
				if (exact_limit != 0)
					die_With_Msg("expected hex");
				go_Back();
				break;//:for
			}
			result <<= 4;
			result += add | 0;
		}
		//??result >>>= 0;
		result |= 0;//TODO fix me: how to make it really UInt?
		return result;
	}

	//:json5+ extension
	inline function parse_Range(begin: Int): String
	{
		parse_Int(false);
		return js_.substring(begin, pos_);
	}

	function parse_Escape_Sequence(cc: Int, buf: Json5Buf)
	{
		switch(cc)
		{
		case 't'.code:
			buf.add_Chr("\t".code);
		//:case 'b'.code:
			//:buf.add_Chr(8);
		//:case 'f'.code:
			//:buf.add_Chr(12);//:VT100-compatible terminal? are u serious?
		case 'r'.code:
			buf.add_Chr("\r".code);
		case 'n'.code:
			buf.add_Chr("\n".code);
		case '/'.code, '\\'.code, '"'.code, "'".code, '`'.code:
			buf.add_Chr(cc);
		case 'x'.code:
			var xc: UInt = parse_Hex(2);
			if (0 == xc)
				die_With_Msg("bad \\x value");
			buf.add_Chr_Utf8(xc);
		case 'u'.code:
			var uc: UInt = parse_Hex(4);
			if (0 == uc)
				die_With_Msg("bad \\u value");
			buf.add_Chr_Utf8(uc);
		case '\r'.code, '\n'.code:
			parse_Eol(cc);
		default:
			die_With_Msg("bad escape sequence '\\" + String.fromCharCode(cc) + "'");
		}
	}

	function parse_String(quote: Int): String
	{
		var begin = pos_;
		var buf: Json5Buf = null;
		while (true)
		{
			var cc: Int = read_Char_Code();
			if (is_Eof(cc))
				die_With_Msg("expected '" + quote + "'");
			if (cc == quote)
			{
				if (null == buf)
					return js_.substring(begin, pos_ - 1);
				buf.add_Sub(js_, begin, pos_ - begin - 1);
				return buf.toString();
			}
			switch(cc)
			{
			case '\\'.code:
				if (null == buf)
					buf = new Json5Buf();
				buf.add_Sub(js_, begin, pos_ - begin - 1);
				cc = read_Char_Code();
				parse_Escape_Sequence(cc, buf);
				begin = pos_;
			case '\r'.code, '\n'.code:
				die(cc);
			default:
				//:nop
			}
		}
	}

/*
	Start with ```. The first line feed is ignored.
	Ends with ```.
	Common whitespace is ignored - for better formatting.
	The last line feed is ignored, too.
	All trailing whitespace is ignored, too.
	The output line feed is always '\n'.

	Example:
	```
	First line.
	Second line`.
	  This line is indented by two spaces.
	```

*/

	function parse_ML_String(): String
	{
		var err_msg = 'expected "```"';
		var cc: Int;
		for (i in 0...2)
		{
			cc = read_Char_Code();
			if (cc != '`'.code)
				die(cc);
		}
		//:skip [wspace]eol after ```
		while (true)
		{
			cc = read_Char_Code();
			if (is_Eof(cc))
				die_With_Msg(err_msg);
			switch(cc)
			{
			case ' '.code, '\t'.code, 0xA0/*Non-breaking space*/:
				//:nop
			case '\r'.code, '\n'.code:
				parse_Eol(cc);
				break;//:while
			default:
				die(cc);
			}
		}
		//:parse lines
		var line_begin: Int = pos_;
		var accent_count: Int = 0;
		var text: Array<String> = [];
		while (true)
		{
			cc = read_Char_Code();
			if (is_Eof(cc))
				die_With_Msg(err_msg);
			//trace("read 0x" + StringTools.hex(cc, 2) + ", flags=0x" + StringTools.hex(line_flags));
			switch(cc)
			{
			case '`'.code:
				if (3 == ++accent_count)
				{
					var tail: String = js_.substring(line_begin, pos_ - 3);
					//trace("tail='" + tail + "'");
					text.push(tail);
					Json5Util.trim_WS(text);
					return text.join('\n');
				}
			default:
				accent_count = 0;
			}
			switch(cc)
			{
			case '\r'.code, '\n'.code:
				//trace("eol 0x" + StringTools.hex(cc, 2));
				text.push(js_.substring(line_begin, pos_ - 1));
				parse_Eol(cc);
				line_begin = pos_;
				//trace("line begin, cc='" + String.fromCharCode(peek_Char_Code()) + "'==0x" + StringTools.hex(peek_Char_Code()));
			default:
				//:nop
			}
		}
	}

	function die(cc: Int)
	{
		throw new Json5Error("ERROR: bad char '" + String.fromCharCode(cc) + "'==0x" + StringTools.hex(cc, 2) +
			" at line " + (row_ + 1) + ":" + col_, pos_, row_ + 1, col_);
	}
	function die_With_Msg(msg: String)
	{
		throw new Json5Error("ERROR: " + msg +
			" at line " + (row_ + 1) + ":" + col_, pos_, row_ + 1, col_);
	}

}