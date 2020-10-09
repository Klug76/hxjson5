package gs.json5mod;

#if (haxe_ver < 4)
typedef Json5PrintCallback = String->Void;
#else
typedef Json5PrintCallback = (lines: String)->Void;
#end

typedef Json5PrintOptions =
{
	?tracer: Json5PrintCallback,
	?ident: String,
	?space_before_colon: String,
	?space_after_colon: String,
	?float_suffix: String,
	?width_limit: Int,//:broken yet
	flags: Json5PrintFlags
}
