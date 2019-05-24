package;

import gs.json5mod.Json5;
import gs.json5mod.Json5Ast;

#if macro
import sys.io.File;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

class CompileTimeJson
{
#if macro
	static var cache = new Map<String, Json5Ast>();
#end

	static macro public function assign(targetExpr: Expr, targetDescriptor: Expr, id: String)
	{
#if display
		return macro {};
#else
		function gen_Code(target: Expr, fields: Array<ClassField>, jnode: Json5Ast)
		{
			var code = [];
			inline function assembly(e: Expr)
			{
				code.push(e);
			}
			for (f in fields)
			{
				//trace(f.name);
				switch(f.kind)
				{
				case FMethod(_):
					continue;
				default:
				}
				var field = f.name;
				var meta = f.meta;
				switch(f.type)
				{
				case TInst(c, []):
					switch(c.toString())
					{
					case "String":
						var def: String = MetaMacroTools.find_String(meta.extract(MetaMacroTools.def));
						var val: String = jnode.get_String(field, def);
						assembly(macro { $target.$field = $v{val}; } );
						continue;
					}
				case TAbstract(a, []):
					switch(a.toString())
					{
					case "Int":
						var def: Int = MetaMacroTools.find_Int(meta.extract(MetaMacroTools.def));
						var val: Int = jnode.get_Int(field, def);
						assembly(macro { $target.$field = $v{val}; } );
						continue;
					case "UInt":
						var def: UInt = MetaMacroTools.find_Int(meta.extract(MetaMacroTools.def)) | 0;
						var val: UInt = jnode.get_UInt(field, def);
						assembly(macro { $target.$field = $v{val}; } );
						continue;
					case "Float":
						var def: Float = MetaMacroTools.find_Float(meta.extract(MetaMacroTools.def));
						var val: Float = jnode.get_Float(field, def);
						assembly(macro { $target.$field = $v{val}; } );
						continue;
					//default:
						//trace("********* " + f);
					}
				default:
				}
				trace("WARNING: unsupported field " + f.name + ": " + f.type);
			}
			return code;
		}

		var targetDescriptorType = Context.getType(targetDescriptor.toString());

		var jfile = MetaMacroTools.find_Json_Name(targetDescriptorType);
		if (jfile.length <= 0)
			Context.fatalError("@:json5(file) meta not found", Context.currentPos());
		var fields = MetaMacroTools.find_Fields(targetDescriptorType);
		if (null == fields)
			Context.fatalError("fields not found", Context.currentPos());

		var json_ast: Json5Ast = cache.get(jfile);
		if (null == json_ast)
		{
			var content = File.getContent(jfile);
			json_ast = Json5.parser_Factory().parse(content);
			cache.set(jfile, json_ast);
			//trace("***** json loaded at compile time " + filepath);
		}
		var jnode = json_ast.get_Field(id);

		return macro
		{
			$b{gen_Code(targetExpr, fields, jnode)};
		}
#end
	}
}
