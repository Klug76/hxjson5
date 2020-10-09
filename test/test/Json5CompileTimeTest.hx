package;

import gs.json5mod.Json5FileUtil;
import haxe.Json;
import massive.munit.Assert;

@:keep
class Json5CompileTimeTest
{
	public function new()
	{}

	/**/
	@Test
	public function test_Parse()
	{
#if (!display)
#if flashdevelop
		var a = Json5FileUtil.load_At_Compile_Time("../assets/pass01_complex.json");
		//var b = Json5FileUtil.load_At_Compile_Time("../assets/fail01_falsefalse.json");
		//var b = Json5FileUtil.load_At_Compile_Time("../assets/fail21_dup.json");
		//var b = Json5FileUtil.load_At_Compile_Time("../assets/fail22_badbegin.json");
#else
		var a = Json5FileUtil.load_At_Compile_Time("assets/pass01_complex.json");
		//var a = Json5FileUtil.load_At_Compile_Time("assets/pass04_compact.json");
		//var b = Json5FileUtil.load_At_Compile_Time("assets/fail01_falsefalse.json");
#end
#end
		Assert.isTrue(true);
	}

}