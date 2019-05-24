package gs.util;

@:enum abstract SignalState(Int) from Int to Int
{
	public var INACTIVE : Int = 0;
	public var ACTIVE : Int = 1;
	public var FIRE : Int = 2;

	public inline function has(v: Int): Bool			{ return (this & v) != 0; }
	public inline function set(v: Int): SignalState		{ return this |= v; }
	public inline function unset(v: Int): SignalState	{ return this &= ~v; }
}
