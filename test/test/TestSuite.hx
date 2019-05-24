import massive.munit.TestSuite;

import Json5CompileTimeTest;
import Json5ParseTest;
import Json5PrintTest;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */
class TestSuite extends massive.munit.TestSuite
{
	public function new()
	{
		super();

		add(Json5CompileTimeTest);
		add(Json5ParseTest);
		add(Json5PrintTest);
	}
}
