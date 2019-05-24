package;

import flash.Lib;
import flash.display.Sprite;

import massive.munit.client.PrintClient;
import massive.munit.client.PrintClientBase;
import massive.munit.client.HTTPClient;
import massive.munit.client.SummaryReportClient;
import massive.munit.TestRunner;


class Main extends Sprite
{
	public function new()
	{
		super();

		var suites = new Array<Class<massive.munit.TestSuite>>();
		suites.push(TestSuite);

		var client = new FDPrintClient();

		var runner:TestRunner = new TestRunner(client);

		runner.run(suites);
	}


	static function main()
	{
		Lib.current.addChild(new Main());
	}

}