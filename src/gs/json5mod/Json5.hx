package gs.json5mod;

class Json5
{
	public static function parse(js5: String): Json5Ast
	{
		return parser_Factory().parse(js5);
	}

	public static function stringify(obj: Dynamic, ?options: Json5PrintOptions): String
	{
#if debug
		if ((options != null) && (options.tracer != null))
			throw "ERROR: Json5::stringify: unexpected 'option.tracer'";
#end
		return printer_Factory().print(obj, options);
	}

	public static function print(obj: Dynamic, ?options: Json5PrintOptions): Void
	{
#if debug
		if ((options != null) && (options.tracer == null))
			throw "ERROR: Json5::stringify: expected 'option.tracer'";
#end
		printer_Factory().print(obj, options);
	}

	public static function parser_Factory(): Json5Parser
	{
		return new Json5Parser();
	}

	public static function printer_Factory(): Json5Printer
	{
		return new Json5Printer();
	}
}