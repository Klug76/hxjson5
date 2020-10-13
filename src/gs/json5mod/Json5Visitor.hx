package gs.json5mod;

import gs.json5mod.Json5Ast;
import gs.json5mod.Json5Obj;

#if (haxe_ver < 4)
typedef Json5VisitCallback = String->Json5Ast->Json5Ast;
#else
typedef Json5VisitCallback = (key: String, ast: Json5Ast)->Json5Ast;
#end

class Json5Visitor
{
	var callback_: Json5VisitCallback;

	public function new(f: Json5VisitCallback)
	{
		callback_ = f;
	}

	public function visit(ast: Json5Ast): Json5Ast
	{
		return process("", ast);
	}

	function process(key: String, ast: Json5Ast): Json5Ast
	{
		var result = callback_(key, ast);
		if (result == ast)
		{//:do default recursive processing
			switch(ast)
			{
			case JArray(arr):
				var values = new Array<Json5Ast>();
				for (val in arr)
				{
					values.push(process('$key[]', val));
				}
				result = JArray(values);
			case JObject(arr, _):
				var obj = new Json5Obj();
				for (fi in arr)
				{
					switch (fi)
					{
					case JObjectField(key, val):
						obj.add(key, process(key, val));
					default:
						//:NOP
					}
				}
				result = obj;
			default:
			}
		}
		return result;
	}
}

