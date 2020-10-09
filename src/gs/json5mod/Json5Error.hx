package gs.json5mod;

class Json5Error
#if js
#if haxe4
	extends js.lib.Error
#else
	extends js.Error
#end
#elseif flash
	extends flash.errors.Error
#end
{
	public var msg: String;
	public var offset: Int;
	public var row: Int;
	public var col: Int;

	public function new(msg: String, offset: Int, row: Int, col: Int)
	{
#if (js || flash)
		super(msg);
#end
		this.msg = msg;
		this.offset = offset;
		this.row = row;
		this.col = col;
	}

	public function toString(): String
	{
		return msg;
	}

}