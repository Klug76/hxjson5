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
			switch(ast.value_)
			{
			case JArray(v):
				var values = new Array<Json5Ast>();
				for (val in v)
				{
					values.push(process('$key[]', val));
				}
				result = new Json5Ast(JArray(values));
			case JObject(f, n):
				var obj = new Json5Obj();
				for (field in f)
				{
					obj.add_Field(new Json5Field(field.name_, process(field.name_, field.value_)));
				}
				result = new Json5Ast(obj);
			default:
			}
		}
		return result;
	}
}

