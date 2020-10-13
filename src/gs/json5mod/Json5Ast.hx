package gs.json5mod;

//:based on https://github.com/nadako/hxjsonast

enum Json5Ast
{
	JString(s: String);
	JHex(u: UInt);
	JNumber(s: String);
	JIntRange(s: String);//:json5 mod
	//? JObject(fields: Array<Json5Ast>, map: haxe.Constraints.IMap<String, Json5Ast>);
	JObject(fields: Array<Json5Ast>, map: Map<String, Json5Ast>);
	JObjectField(key: String, value: Json5Ast);
	JArray(values: Array<Json5Ast>);
	JBool(b: Bool);
	JNull;
}
