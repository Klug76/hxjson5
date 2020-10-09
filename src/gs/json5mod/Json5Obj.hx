package gs.json5mod;

import gs.json5mod.Json5Ast;
import gs.json5mod.Json5Ast.*;

abstract Json5Obj(Json5Value) to Json5Value
{
	inline public function new()
	{
		this = JObject([], new Map<String, Json5Field>());
	}

	inline public function add_Field(fi: Json5Field): Void
	{
		switch (this)
		{
		case JObject(arr, map):
			arr.push(fi);
			map.set(fi.name_, fi);
		default:
		}
	}

	inline public function add(key: String, val: Json5Value): Void
	{
		var fi: Json5Field =
		{
			name: key,
			value: { value: val }
		}
		add_Field(fi);
	}
}
