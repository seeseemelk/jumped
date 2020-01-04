module jumped.beans;

import jumped.introspection;
import jumped.attributes;
import jumped.errors;
import std.traits;
import std.typecons;

private class Container(T)
{
	void executeStartups()
	{
		static foreach (member; getMembers!T)
		{
			static if (hasUDA!(T, member, startup))
			{
				execute!(member)(resolve!T);
			}
		}
	}

	/// Executes a method, automatically resolving any required parameters.
	/// Params:
	///   member = The name of the member to execute.
	///   type = The object to call the method on.
	auto execute(string member, Type)(Type type)
	if (Parameters!(__traits(getMember, Type, member)).length == 0)
	{
		cast(void) type;
		return __traits(getMember, type, member)();
	}

	/// Executes a method, automatically resolving any required parameters.
	/// Params:
	///   member = The name of the member to execute.
	///   type = The object to call the method on.
	auto execute(string member, Type)(Type type)
	if (Parameters!(__traits(getMember, Type, member)).length > 0)
	{
		cast(void) type;
		Tuple!(int) parameters;
		static foreach (i, parameter; Parameters!(__traits(getMember, Type, member)))
		{
			parameters[i] = resolve!parameter;
		}
		return __traits(getMember, type, member)(parameters.expand);
	}

	/// Resolve a types and returns an instance of that type.
	Type resolve(Type)()
	if (is(Type == T))
	{
		return new T();
	}

	/// Resolve a types and returns an instance of that type.
	Type resolve(Type)()
	if (!is(Type == T) && HasBeanFor!(T, Type))
	{
		return resolve!(T, Type);
	}

	/// Resolve a types and returns an instance of that type.
	Type resolve(Factory, Type)()
	{
		static foreach (member; getFunctionMembers!(Factory))
		{
			static if (hasUDA!(Factory, member, bean)
					&& is(ReturnType!(__traits(getMember, Factory, member)) == Type))
			{
				return execute!(member)(resolve!Factory);
			}
		}
	}

	private template HasBeanFor(Type)
	{
		alias HasBeanFor = HasBeanFor!(T, Type);
	}

	private template HasBeanFor(Factory, Type)
	{
		static if (HasBeanFromMembers!(Factory, Type, getFunctionMembers!(Factory)) == true)
		{
			alias HasBeanFor = HasBeanFromMembers!(Factory, Type, getFunctionMembers!(Factory));
		}
		else static if (is(Type == class))
		{
			static immutable HasBeanFor = true;
		}
		else
		{
			static assert(0, PrintCompileError!("Could not resolve bean " ~ Type.stringof));
		}
	}

	private template HasBeanFromMembers(Factory, Type, string[] members)
	{
		static if (members.length == 0)
		{
			static immutable HasBeanFromMembers = false;
		}
		else static if (hasUDA!(Factory, members[0], bean)
			&& is(ReturnType!(__traits(getMember, Factory, members[0])) == Type))
		{
			static if (HasBeanFromMembers!(Factory, Type, members[1 .. $]) == true)
			{
				static immutable message = "Found multiple beans for " ~ Type.stringof;
				static assert(0, PrintCompileError!(message));
			}
			else
			{
				static immutable HasBeanFromMembers = true;
			}
		}
		else
		{
			alias HasBeanFromMembers = HasBeanFromMembers!(Factory, Type, members[1 .. $]);
		}
	}
}

/// Starts the application.
/// Params:
///   T = The startup class
void jumpStart(T)()
{
	auto container = new Container!T;
	container.executeStartups();
}

@("@startup method is executed on startup")
unittest
{
	static bool called = false;

	static class TestClass
	{
		@startup
		private void func()
		{
			called = true;
		}
	}

	jumpStart!TestClass();
	assert(called == true);
}

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
		@bean private Value createBean()
		{
			return new Value(5);
		}
	}

	auto container = new Container!TestClass;
	const value = container.resolve!Value;
	assert(value.value == 5);
}

@("@bean method can get inversion of control parameters")
unittest
{
	import std.conv : to;
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
		@bean private Value getBean(int num)
		{
			return new Value(num);
		}

		@bean private int getNum()
		{
			return 5;
		}
	}

	auto container = new Container!TestClass;
	const value = container.resolve!Value;
	assert(value.value == 5, "Expected a value of 5, but got " ~ value.value.to!string);
}

@("@startup method can have parameters")
unittest
{
	import std.conv : to;
	static int calledWithValue;

	static class TestClass
	{
		@startup private void onStart(int value)
		{
			calledWithValue = value;
		}

		@bean private int getNum()
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
	import std.conv : to;
	static int calledWithValue;

	static struct TargetValue
	{
		int value;
	}

	static class ChildClass
	{
		@bean private TargetValue getTargetValue()
		{
			return TargetValue(4);
		}
	}

	static class TestClass
	{
		@bean private ChildClass getChild()
		{
			return new ChildClass;
		}
	}

	auto container = new Container!TestClass;
	const value = container.resolve!TargetValue;
	assert(value.value == 4);
}
