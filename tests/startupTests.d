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
