package;

import gs.util.FsWatcher;
import gs.json5mod.Json5;
import gs.json5mod.Json5Printer;
import gs.json5mod.Json5PrintOptions;
import gs.json5mod.Json5PrintFlags;
import openfl.Assets;
import openfl.display.Sprite;

@:json5("json/user.json")
typedef User =
{
	@:def(0)
	var uid: UInt;
	@:def("n/a")
	var name: String;
	@:def(5)
	var money: Int;
}

@:json5("json/ui.json")
class SpriteDescriptor
{
	@:def(100)
	public var x: Float;
	@:def(100)
	public var y: Float;
}

class Main extends Sprite
{
#if (air3 || sys)//#if live_reload!?
	var mon_: FsWatcher = new FsWatcher();
	var hot_: LiveJson = new LiveJson();
#end

	//var user_: User = new User();
	var user_: User = {uid: 0, name: "", money: 0};
	var circle_: Sprite = new Sprite();
	var triangle_: Sprite = new Sprite();

	public function new()
	{
		super();

		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");

		circle_.graphics.beginFill(0x7986cb);
		circle_.graphics.drawCircle(50, 50, 50);
		//child_.x = 20;
		//child_.y = 20;
		addChild(circle_);

		triangle_.graphics.beginFill(0x26418f);
		triangle_.graphics.moveTo(0, 100);
		triangle_.graphics.lineTo(50, 0);
		triangle_.graphics.lineTo(100, 100);
		triangle_.graphics.lineTo(0, 100);
		addChild(triangle_);

		init();

		init_Live_Reload();

		short_Example();
	}


	function init()
	{
		trace("user=" + Json5.stringify(user_));
		CompileTimeJson.assign(user_, User, "root");
		trace("user=" + Json5.stringify(user_));

		CompileTimeJson.assign(circle_, SpriteDescriptor, "circle");
		CompileTimeJson.assign(triangle_, SpriteDescriptor, "triangle");
	}

	function init_Live_Reload()
	{
		/*:may be just
		hot_.set_Base_Dir("../../../");
		hot_.add_Object(user_, User);
		hot_.add_Object(sprite_, SpriteDescriptor);
		hot_.add_Object(triangle_);
		*/
#if (air3 || sys)//TODO && debug? (&& live_reload?)
		mon_.set_Base_Dir("../../../");//:lime/bin/%target%/bin/ => lime/
		mon_.signal_changed_.add(on_Json_Changed);

		mon_.add_File("user", LiveJson.get_Json_Name(User));
		mon_.add_File("ui", LiveJson.get_Json_Name(SpriteDescriptor));

		//mon_.trigger();//:may be used instead of init();

		mon_.watch();
#else
		//:init() may be here
#end
	}

#if (air3 || sys)
	//:can be moved into LiveJson
	function on_Json_Changed(key: String, fpath: String)
	{
		trace("json5 '" + key + "' changed!");
		hot_.refresh(fpath);
		switch(key)
		{
		case "user":
			hot_.assign(user_, User, "root");
			trace("user=" + Json5.stringify(user_));
		case "ui":
			hot_.assign(circle_, SpriteDescriptor, "circle");
			hot_.assign(triangle_, SpriteDescriptor, "triangle");
		}
	}
#end

	function short_Example()
	{
		var s: String = Assets.getText("json/short.json5.txt");
		var j = Json5.parse(s);
		var opt: Json5PrintOptions =
		{
			flags: Pretty | ModeTraceCompatible | AllowMultilineStrings,
			ident: '\t',
			tracer: my_Trace
		};
		Json5.printer_Factory().print(j, opt);
	}

	function my_Trace(lines: String)
	{//:avoid line numbers
#if sys
		Sys.println(lines);
#elseif flash
		flash.Lib.trace(lines);
#elseif js
		js.Browser.window.console.log(lines);
#else
		trace(lines);
#end
	}
}
