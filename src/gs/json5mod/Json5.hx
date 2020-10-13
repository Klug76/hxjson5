package gs.json5mod;

class Json5
{
	public inline static function parse(js5: String): Json5Access
	{
		return parser_Factory().parse(js5);
	}

	public inline static function stringify(obj: Dynamic, ?options: Json5PrintOptions): String
	{
#if debug
		if ((options != null) && (options.tracer != null))
			throw "ERROR: Json5::stringify: unexpected 'option.tracer'";
#end
		return printer_Factory().print(obj, options);
	}

	public inline static function print(obj: Dynamic, ?options: Json5PrintOptions): Void
	{
#if debug
		if ((options != null) && (options.tracer == null))
			throw "ERROR: Json5::print: expected 'option.tracer'";
#end
		printer_Factory().print(obj, options);
	}

	public inline static function parser_Factory(flags: Json5ParseFlags = Json5ParseFlags.Default): Json5Parser
	{
		return new Json5Parser(flags);
	}

	public inline static function printer_Factory(): Json5Printer
	{
		return new Json5Printer();
	}
}