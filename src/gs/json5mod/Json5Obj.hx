package gs.json5mod;

import gs.json5mod.Json5Ast;

abstract Json5Obj(Json5Ast) to Json5Ast
{
	inline public function new()
	{
		this = JObject([], new Map<String, Json5Ast>());
	}

	inline public function add(key: String, val: Json5Ast): Void
	{
		switch (this)
		{
		case JObject(arr, map):
			var fi = JObjectField(key, val);
			arr.push(fi);
			map.set(key, fi);
		default:
		}
	}
}
