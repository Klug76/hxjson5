package;

import gs.json5mod.Json5;
import gs.json5mod.Json5Error;
import gs.json5mod.Json5PrintOptions;
import gs.json5mod.Json5PrintFlags;
import haxe.Json;
import massive.munit.Assert;

class Json5PrintTest
{
	public function new()
	{}

	/**/
	@Test
	public function test_Nested_Call()
	{

		var foo: Dynamic =
		{
			a: 1,
			b: {a: 1, b: 2, c: 3, d: 4}
		};
		var opt: Json5PrintOptions =
		{
			flags: SortFields | Pretty,
		};

		//trace("root");
		var s: String = Json5.stringify(foo, opt);
		//trace(s);
		//Util.dump_Strings_Diff("", s);
		Assert.areEqual("{\na:1\nb:\n{\na:1\nb:2\nc:3\nd:4\n}\n}", s);
		var bar: Dynamic = Json5.parse(s).to_Any();
		Assert.isTrue(Util.equal_Dynamics(foo, bar));
	}


	/**/
	@Test
	public function test_Options()
	{
		var foo: Dynamic =
		{
			a: ["1\n\t2"],
		};
		var opt: Json5PrintOptions =
		{
			flags: EscapeTab,
		};
		var s1: String = Json5.stringify(foo, opt);
		Assert.areEqual('{a:["1\\n\\t2"]}', s1);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s1).to_Any()));

		opt.flags.set(Pretty | OpenBraceSameLine);
		opt.ident = "\t\t";
		opt.space_before_colon = " ";
		opt.space_after_colon = " ";
		var s2: String = Json5.stringify(foo, opt);
		Assert.areEqual('{\n\t\ta : [\n\t\t\t\t\"1\\n\\t2"\n\t\t]\n}', s2);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s2).to_Any()));

		opt.flags.unset(OpenBraceSameLine);
		opt.ident = " ";
		opt.space_before_colon = null;
		var s3: String = Json5.stringify(foo, opt);
		Assert.areEqual('{\n a:\n [\n  "1\\n\\t2"\n ]\n}', s3);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s3).to_Any()));

		opt.flags.unset(EscapeTab);
		opt.flags.set(AllowMultilineStrings);
		var s4: String = Json5.stringify(foo, opt);
		Assert.areEqual('{\n a:\n [\n  ```\n  1\n  \t2\n  ```\n ]\n}', s4);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s4).to_Any()));

		opt.flags.unset(Pretty);
		opt.space_after_colon = null;
		var s4: String = Json5.stringify(foo, opt);
		Assert.areEqual('{a:[\n```\n1\n\t2\n```\n]}', s4);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s4).to_Any()));
	}
	/**/

	/**/
	@Test
	public function test_Options2()
	{
		var foo: Dynamic =
		{
			a: { s: "1\n2" }
		};
		var opt: Json5PrintOptions =
		{
			flags: Pretty | AllowMultilineStrings,
			ident: " ",
		};
		var s1: String = Json5.stringify(foo, opt);
		Assert.areEqual('{\n a:\n {\n  s:\n  ```\n  1\n  2\n  ```\n }\n}', s1);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s1).to_Any()));

		opt.flags.set(OpenBraceSameLine);
		var s2: String = Json5.stringify(foo, opt);
		//Util.dump_Strings_Diff('{\n a:{\n  s:\n  ```\n  1\n  2\n  ```\n }\n}', s2);
		Assert.areEqual('{\n a:{\n  s:\n  ```\n  1\n  2\n  ```\n }\n}', s2);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s2).to_Any()));

		opt.ident = null;
		opt.flags.unset(Pretty);
		var s3: String = Json5.stringify(foo, opt);
		Assert.areEqual('{a:{s:\n```\n1\n2\n```\n}}', s3);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s3).to_Any()));
	}
	/**/

	/**/
	@Test
	public function test_ML_String()
	{
		var foo: Dynamic =
		{
			str1: "\t1\n2",
			str2: "\t1\n\t2",
			str3: "\n",
			str4: "\t\n\t",
			str5_arr://:cs target push str_arr on top
			[
				"0", "1\n2",
				"3\n4", "5",
			],
			'z```1': '```',
		};
		var s1: String = Json5.stringify(foo, { flags: SortFields | AllowMultilineStrings });
		var expected = '{str1:\n```\n\t1\n2\n```\nstr2:\n```\n\t1\n\t2\n```\nstr3:\n```\n\n\n```\nstr4:\n```\n\t\n\t\n```\nstr5_arr:["0"\n```\n1\n2\n```\n```\n3\n4\n```\n"5"]z```1:"```"}';
		//Util.dump_Strings_Diff(expected, s1);
		Assert.areEqual(expected, s1);
		Assert.isTrue(Util.equal_Dynamics(foo, Json5.parse(s1).to_Any()));
	}
	/**/
}