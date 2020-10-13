package;

import gs.json5mod.Json5Ast;
import gs.json5mod.Json5Access;
import gs.json5mod.Json5FileUtil;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

class LiveJson
{
	public var cur_ast_: Json5Access = JNull;

#if !macro

	public function new()
	{}

	public function refresh(fpath: String): Void
	{
		var json_ast: Json5Ast = JNull;
		try
		{
			json_ast = Json5FileUtil.load(fpath);
		}
		catch (err: Dynamic)
		{
			trace(err);
			trace('file: "$fpath"');
		}
		cur_ast_ = json_ast;
	}

#end

	macro public function assign(self: Expr, targetExpr: Expr, targetDescriptor: Expr, id: String)
	{
#if display
		return macro {};
#else
		function gen_Code(target: Expr, fields: Array<ClassField>)
		{
			var code = [];
			inline function assembly(e: Expr)
			{
				code.push(e);
			}
			assembly(macro var jnode = $self.cur_ast_.get_Field($v{id}) );
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
						assembly(macro { $target.$field = jnode.get_String($v{field}, $v{def}); } );
						continue;
					}
				case TAbstract(a, []):
					switch(a.toString())
					{
					case "Int":
						var def: Int = MetaMacroTools.find_Int(meta.extract(MetaMacroTools.def));
						assembly(macro { $target.$field = jnode.get_Int($v{field}, $v{def}); } );
						continue;
					case "UInt":
						var def: UInt = MetaMacroTools.find_Int(meta.extract(MetaMacroTools.def)) | 0;
						assembly(macro { $target.$field = jnode.get_UInt($v{field}, $v{def}); } );
						continue;
					case "Float":
						var def: Float = MetaMacroTools.find_Float(meta.extract(MetaMacroTools.def));
						assembly(macro { $target.$field = jnode.get_Float($v{field}, $v{def}); } );
						continue;
					}
				default:
				}
				trace('WARNING: unsupported field ${f.name}: ${f.type}');
			}
			return code;
		}

		var targetDescriptorType = Context.getType(targetDescriptor.toString());

		var fields = MetaMacroTools.find_Fields(targetDescriptorType);
		if (null == fields)
			Context.fatalError("fields not found", Context.currentPos());

		return macro
		{
			$b{gen_Code(targetExpr, fields)};
		}
#end
	}

	static macro public function get_Json_Name(targetDescriptor: Expr): Expr
	{
		var targetDescriptorType = Context.getType(targetDescriptor.toString());
		var ret: String = MetaMacroTools.find_Json_Name(targetDescriptorType);
		return macro $v{ret};
	}
}