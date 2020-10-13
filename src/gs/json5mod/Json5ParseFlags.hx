package gs.json5mod;

@:enum
abstract Json5ParseFlags(Int) from Int to Int
{
	var Default				= 0x0000;
	var AllowEmptyKeys		= 0x0001;//:e.g. {"":123}
	var AllowDuplicateKeys	= 0x0002;//:e.g. {a:123 a:345}

	public inline function has(v: Int): Bool				{ return (this & v) != 0; }
	public inline function set(v: Int): Json5ParseFlags		{ return this |= v; }
	public inline function unset(v: Int): Json5ParseFlags	{ return this &= ~v; }
}
