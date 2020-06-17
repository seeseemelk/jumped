import jumped;

@("@shutdown method is executed on shutdown")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@shutdown
		void shutdownMethod()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

@("@shutdownOnSuccess method is executed on success")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		void setUp() {}

		@shutdownOnSuccess
		void tearDown()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

@("@shutdownOnSuccess method is not executed on failure")
unittest
{
	static class TestClass
	{
		@startup
		void setUp()
		{
			throw new Exception("Test exception");
		}

		@shutdownOnSuccess
		void tearDown()
		{
			assert(0, "Should not be executed");
		}
	}

	try
	{
		jumpStart!TestClass();
	}
	catch (Exception e) {}
}

@("@shutdownOnFailure method is not executed on success")
unittest
{
	static class TestClass
	{
		@startup
		void setUp() {}

		@shutdownOnFailure
		void tearDown()
		{
			assert(0, "Should not be executed");
		}
	}

	jumpStart!TestClass();
}

@("@shutdownOnFailure method is executed on failure")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		void setUp()
		{
			throw new Exception("Test exception");
		}

		@shutdownOnFailure
		void tearDown()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

@("@shutdown method is executed on success")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		void setUp() {}

		@shutdown
		void tearDown()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

@("@shutdown method is executed on failure")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		void setUp()
		{
			throw new Exception("Test exception");
		}

		@shutdown
		void tearDown()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}
