package gs.json5mod;

//TODO use haxe.Utf8

#if !flash

abstract Json5Buf(StringBuf)
{
	public var length(get, never): Int;

	public inline function new()
	{
		this = new StringBuf();
	}

	private inline function get_length(): Int
	{
		return this.length;
	}

	public inline function clear()
	{
		this = new StringBuf();// :(
	}

	public inline function add_Str(s: String)
	{
		this.add(s);
	}

	public inline function add_Sub(s: String, pos : Int, ?len : Int)
	{
		this.addSub(s, pos, len);
	}

	public inline function add_Chr(cc: Int)
	{
		this.addChar(cc);
	}

	public inline function add_Chr_Utf8(uc: UInt): Void
	{
		//:slightly modified code from haxe.format.JsonParser:
#if (neko || php || (cpp && !hxcpp_smart_strings) || lua || eval)
		if ( uc <= 0x7F )
		{
			this.addChar(uc);
		}
		else if ( uc <= 0x7FF )
		{
			this.addChar(0xC0 | (uc >> 6));
			this.addChar(0x80 | (uc & 63));
		}
		else if ( uc <= 0xFFFF )
		{
			this.addChar(0xE0 | (uc >> 12));
			this.addChar(0x80 | ((uc >> 6) & 63));
			this.addChar(0x80 | (uc & 63));
		}
		else
		{
			this.addChar(0xF0 | (uc >> 18));
			this.addChar(0x80 | ((uc >> 12) & 63));
			this.addChar(0x80 | ((uc >> 6) & 63));
			this.addChar(0x80 | (uc & 63));
		}
#else
		this.addChar(uc);
#end
		//:why this code is not moved to StringBuf::addChar | String::fromCharCode? who knows...
	}

	public inline function toString(): String
	{
		return this.toString();
	}
}

#else

abstract Json5Buf(flash.utils.ByteArray)
{
	public var length(get, never): Int;

	public inline function new()
	{
		this = new flash.utils.ByteArray();
		//?this.endian = flash.utils.Endian.BIG_ENDIAN;//:default value is BIG_ENDIAN.
	}

	private inline function get_length(): Int
	{
		return cast this.length;
	}

	public inline function clear()
	{
		this.clear();
	}

	public inline function add_Str(s: String)
	{
		this.writeUTFBytes(s);
	}

	public inline function add_Sub(s: String, pos : Int, ?len : Int)
	{
		this.writeUTFBytes(if (len != null) s.substr(pos, len) else s.substr(pos));
	}

	public inline function add_Chr(cc: Int)
	{
		this.writeByte(cc);
	}

	public inline function add_Chr_Utf8(uc: UInt): Void
	{
		if (uc > 0x7F)
			this.writeUTFBytes(String.fromCharCode(uc));
		else
			this.writeByte(uc);
	}

	public inline function toString(): String
	{
		return this.toString();
	}
}

#end