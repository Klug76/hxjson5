package;

import haxe.crypto.Base64;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

class AssetsMacro
{

	macro static public function embed(path: String): Array<Field>
	{
		path = Context.resolvePath(path);
		var map : Array<Expr> = [];
#if !display
		for (f in FileSystem.readDirectory(path))
		{
			var file = path + "/" + f;
			if (FileSystem.isDirectory(file))
				continue;

			var ext = f.substring(f.lastIndexOf(".") + 1).toLowerCase();
			if (ext != "json")
				continue;

			var fname = f.substring(0, f.lastIndexOf("."));

			//var data: String = File.getContent(file);//:BUG: it may be broken in js target
			//var data: String = File.getBytes(file).toHex();//:ofHex required haxe 4.preview5
			var data: String = Base64.encode(File.getBytes(file));
			map.push(macro $v{fname} => $v{data});
		}
#end
		var result = Context.getBuildFields();
		result.push(
		{
			name	: "map",
			access	: [APublic, AStatic],
			doc		: null,
			meta	: null,
			kind	: FVar(macro : Map<String, String>, macro $a{map}),
			pos		: Context.currentPos(),
		});
		return result;
	}
}