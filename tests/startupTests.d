import jumped;

@("@startup method is executed on startup")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		void startupMethod()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

@("@startup can be used multiple times")
unittest
{
	static bool calledA = false;
	static bool calledB = false;

	static class TestClass
	{
		@startup
		void startupA()
		{
			calledA = true;
		}

		@startup
		void startupB()
		{
			calledB = true;
		}
	}

	jumpStart!TestClass();
	assert(calledA == true);
	assert(calledB == true);
}
