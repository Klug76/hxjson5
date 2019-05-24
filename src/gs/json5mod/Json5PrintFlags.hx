package gs.json5mod;

//import haxe.EnumFlags;//:they sux

@:enum
abstract Json5PrintFlags(Int) from Int to Int
{
	var Compact					= 0x0001;
	var Pretty					= 0x0002;//:TODO allow combine Pretty|Compact => short objects/arrays inlining
	var SortFields				= 0x0004;
	var OpenBraceSameLine		= 0x0008;
	var AllowMultilineStrings	= 0x0010;//:side effect: rtrim; \n as eol
	var EscapeTab				= 0x0020;
	var ModeTraceCompatible		= 0x0040;//:omit last \n for each trace()

	public inline function has(v: Int): Bool			{ return (this & v) != 0; }
	public inline function set(v: Int): Json5PrintFlags		{ return this |= v; }
	public inline function unset(v: Int): Json5PrintFlags	{ return this &= ~v; }//TODO review: why EnumFlags uses 0xFFffFFff-v? bug in haxe bitwise negation?
}
