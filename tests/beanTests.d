import jumped;

@("@bean method creates instance")
unittest
{
	static class Value
	{
		int value;

		this(int value)
		{
			this.value = value;
		}
	}

	static class TestClass
	{
		@bean Value createBean()
		{
			return new Value(5);
		}
	}

	auto container = new Container!TestClass;
	const value = container.resolve!Value;
	assert(value.value == 5);
}

@("@component class is automatically instantiated")
unittest
{
	@component
	static class ValueA
	{
		this() {}
	}

	@component
	static class ValueB {}

	static class TestClass {}

	auto container = new Container!TestClass;
	assert(container.resolve!ValueA !is null);
	assert(container.resolve!ValueB !is null);
}

@("@component class can have constructor parameters resolved")
unittest
{
	@component
	static class ValueA {}

	@component
	static class ValueB
	{
		this(ValueA valueA) {}
	}

	static class TestClass {}

	auto container = new Container!TestClass;
	assert(container.resolve!ValueA !is null);
	assert(container.resolve!ValueB !is null);
}

@("@bean method can get injected parameters")
unittest
{
	import std.conv : to;
	static struct StructValue
	{
		string text;
	}

	static class Value
	{
		int value;
		string text;

		this(int value, StructValue structValue)
		{
			this.value = value;
			this.text = structValue.text;
		}
	}

	static class TestClass
	{
		@bean Value getBean(int num, StructValue value)
		{
			return new Value(num, value);
		}

		@bean int getNum()
		{
			return 5;
		}

		@bean StructValue getStructValue()
		{
			return StructValue("some text");
		}
	}

	auto container = new Container!TestClass;
	const value = container.resolve!Value;
	assert(value.value == 5, "Expected a value of 5, but got " ~ value.value.to!string);
	assert(value.text == "some text", "Expected ths string \"some text\", but got " ~ value.text.to!string);
}

@("@startup method can have a parameter")
unittest
{
	import std.conv : to;
	static int calledWithValue;

	static class TestClass
	{
		@startup void onStart(int value)
		{
			calledWithValue = value;
		}

		@bean int getNum()
		{
			return 5;
		}
	}

	jumpStart!TestClass;
	assert(calledWithValue == 5, "Expected a value of 5, but got " ~ calledWithValue.to!string);
}

@("@bean methods can be found from child beans")
unittest
{
	static struct TargetValue
	{
		int value;
	}

	static class ClassC
	{
		@bean TargetValue getTargetValue()
		{
			return TargetValue(4);
		}
	}

	static class ClassB
	{
		@bean ClassC getTargetValue()
		{
			return new ClassC;
		}
	}

	static class ClassA
	{
		@bean ClassB getChild()
		{
			return new ClassB;
		}
	}

	auto container = new Container!ClassA;
	const value = container.resolve!TargetValue;
	assert(value.value == 4);
}

@("@bean methods can be indirectly annotated")
unittest
{
	@bean
	struct annotation;

	static class Class
	{
		@annotation int getValue()
		{
			return 5;
		}
	}

	auto container = new Container!Class;
	const value = container.resolve!int;
	assert(value == 5);
}

@("methods can have multiple annotations")
unittest
{
	@bean
	struct annotationA;

	struct annotationB;

	static class Class
	{
		@annotationA
		@annotationB
		int getValue()
		{
			return 5;
		}
	}

	auto container = new Container!Class;
	const value = container.resolve!int;
	assert(value == 5);
}

@("Startup class should be a singleton")
unittest
{
	static class Class
	{
		static int constructed = 0;

		this()
		{
			constructed++;
		}

		@bean
		int getInt()
		{
			return 0;
		}

		@bean
		float getFloat()
		{
			return 0.0f;
		}

		@bean
		double add(int a, float b)
		{
			return a + b;
		}
	}

	auto container = new Container!Class;
	container.resolve!double;
	assert(Class.constructed == 1, "Class was instantiated multiple times");
}
