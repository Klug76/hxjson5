package;

import js.Lib;

import massive.munit.client.PrintClient;
import massive.munit.client.RichPrintClient;
import massive.munit.client.HTTPClient;
import massive.munit.client.SummaryReportClient;
import massive.munit.TestRunner;


class MainJS
{
	public function new()
	{
		var suites = new Array<Class<massive.munit.TestSuite>>();
		suites.push(TestSuite);

		var client = new RichPrintClient();

		var runner: TestRunner = new TestRunner(client);

		runner.run(suites);
	}


	static function main()
	{
		new MainJS();
	}

}