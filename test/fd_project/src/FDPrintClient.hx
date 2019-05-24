package;

import flash.errors.Error;
import massive.haxe.util.ReflectUtil;
import massive.munit.client.PrintClientBase;

class FDPrintClient extends PrintClientBase
{

	/**
	 * Default id of this client.
	 */
	public static inline var DEFAULT_ID:String = "FD print";

	#if flash
	var textField:flash.text.TextField;
	#end

	public function new(?includeIgnoredReport:Bool = true)
	{
		super(includeIgnoredReport);
		id = DEFAULT_ID;
	}

	override function init():Void
	{
		super.init();

		#if flash
			initFlash();
		#else
			throw new Error("This client for FlashDevelop::flash debugger only");
		#end

		originalTrace = haxe.Log.trace;
		haxe.Log.trace = customTrace;
	}

	#if flash
	function initFlash()
	{
		textField = new flash.text.TextField();
		textField.selectable = true;
		textField.width = flash.Lib.current.stage.stageWidth;
		textField.height = flash.Lib.current.stage.stageHeight;
		flash.Lib.current.addChild(textField);

		if(!flash.system.Capabilities.isDebugger)
		{
			printLine("WARNING: Flash Debug Player not installed. May cause unexpected behaviour in MUnit when handling thrown exceptions.");
		}
	}
	#end

	override function printOverallResult(result:Bool)
	{
		super.printOverallResult(result);
	}

	function customTrace(value, ?info:haxe.PosInfos)
	{
		addTrace(value, info);
	}

	override public function print(value:Dynamic)
	{
		super.print(value);

		#if flash
		flash.Lib.trace(value);
		textField.appendText(value);
		textField.scrollV = textField.maxScrollV;
		#end
		//originalTrace(value);
	}
}