package gs.json5mod;


#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class Json5FileUtil
{
	public static function load(fpath: String): Json5Ast
	{
		var content = get_Content(fpath);
		return Json5.parser_Factory().parse(content);
	}

	public static function get_Content(path: String): String
	{
#if sys
		if (!sys.FileSystem.exists(path))
			return null;
		var content = sys.io.File.getContent(path);
		return content;
#elseif air3
		var file: flash.filesystem.File = new flash.filesystem.File(path);
		if (!file.exists)
			return null;
		var fs = new flash.filesystem.FileStream();
		fs.open(file, flash.filesystem.FileMode.READ);
		var fsize = fs.bytesAvailable;
		var content = "";
		if (fsize > 0)
			content = fs.readUTFBytes(fsize);
		fs.close();
		return content;
#else
		throw "unsupported target";
#end
	}

	macro public static function load_At_Compile_Time(path: String): Expr
	{
		//:based on https://code.haxe.org/category/macros/validate-json.html
		if (!sys.FileSystem.exists(path))
		{
			Context.warning(path + " does not exist", Context.currentPos());
		}
		var content = sys.io.File.getContent(path);
		try
		{
			var j = Json5.parse(content).to_Any();//:it will throw an error when you made a mistake.

			var e = Context.makeExpr(j, Context.currentPos());//:As such, only basic types and enums are supported
			return check_Type_Of_Arrays(e);
		}
		catch (err: Json5Error)
		{//:create position inside the json, FlashDevelop handles this very nice.
			var position = err.offset;
			if (position > 0)
				--position;
			trace("*** pos=" + position);
			var pos = Context.makePosition(
			{
				min: position,
				max: position + 1,
				file: path
			});
			Context.error(path + " is not valid Json5. " + err.msg, pos);
		}
		return macro null;
	}

#if macro
	static function check_Type_Of_Arrays(e: Expr): Expr
	{//:avoid "Arrays of mixed types are only allowed if the type is forced to Array<Dynamic>"
		return switch (e)
		{
		case  { expr : EArrayDecl(vs), pos : pos }:
			macro ($a{vs.map(check_Type_Of_Arrays)}: Array<Dynamic>);
		case _:
			haxe.macro.ExprTools.map(e, check_Type_Of_Arrays);
		}
	}
#end
}
