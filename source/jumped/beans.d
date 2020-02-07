module jumped.beans;

import jumped.introspection;
import jumped.attributes;
import jumped.errors;
import std.traits;
import std.typecons;
import std.meta;
import std.algorithm;

private struct BeanInfo(alias FactoryMethod)
{
	alias Bean = ReturnType!FactoryMethod;
	static immutable string methodName = __traits(identifier, FactoryMethod);
	alias Parent = __traits(parent, FactoryMethod);

	static if (isScalarType!bean)
	{
		alias isAnnotatedWith(Annotation) = Alias!false;
		alias getAnnotations(Annotation) = AliasSeq!();
	}
	else
	{
		alias isAnnotatedWith(Annotation) = hasAnnotation!(bean, Annotation);
		alias getAnnotations(Annotation) = getUDAs!(bean, Annotation);
	}
}

private class Container(T)
{
	alias beans = DiscoverBeans!T;
	alias DiscoverBeans(Type) = AliasSeq!(BeanInfo!createRootBean, AllBeansAccessableBy!(BeanInfo!createRootBean));

	private T createRootBean()
	{
		return new T();
	}

	private template AllBeansAccessableBy(Type...)
	{
		static if (Type.length == 1)
		{
			alias beans = BeansDirectlyAccessableBy!(Type[0].Bean);
			static if (beans.length == 0)
			{
				alias AllBeansAccessableBy = AliasSeq!();
			}
			else
			{
				alias AllBeansAccessableBy = AliasSeq!(
					beans,
					AllBeansAccessableBy!beans
				);
			}
		}
		else
		{
			alias AllBeansAccessableBy = AliasSeq!(
				AllBeansAccessableBy!(Type[0]),
				AllBeansAccessableBy!(Type[1..$])
			);
		}
	}

	private template BeansDirectlyAccessableBy(Type)
	{
		static if (!isScalarType!Type && getMembersByAnnotation!(Type, bean).length > 0)
			alias BeansDirectlyAccessableBy = AliasSeq!(MapReturnTypes!(getMembersByAnnotation!(Type, bean)));
		else
			alias BeansDirectlyAccessableBy = AliasSeq!();
	}

	private template MapReturnTypes(Values...)
	{
		static if (Values.length == 1)
		{
			alias MapReturnTypes = Alias!(BeanInfo!(Values[0]));
		}
		else
		{
			alias MapReturnTypes = AliasSeq!(
				MapReturnTypes!(Values[0]),
				MapReturnTypes!(Values[1..$])
			);
		}
	}

	template FindAnnotatedMembers(Annotation)
	{
		alias FindAnnotatedMembers = FindAnnotatedMembersInBeans!(Annotation, beans);
	}

	private template FindAnnotatedMembersInBeans(Annotation, Beans...)
	{
		static if (Beans.length == 1)
		{
			alias bean = Beans[0].Bean;
			static if (isScalarType!(bean))
				alias FindAnnotatedMembersInBeans = AliasSeq!();
			else
				alias FindAnnotatedMembersInBeans = AliasSeq!(getSymbolsByUDA!(bean, Annotation));
		}
		else static if (Beans.length > 1)
		{
			alias FindAnnotatedMembersInBeans = AliasSeq!(
				FindAnnotatedMembersInBeans!(Annotation, Beans[0]),
				FindAnnotatedMembersInBeans!(Annotation, Beans[1..$])
			);
		}
		else
		{
			alias FindAnnotatedMembersInBeans = AliasSeq!();
		}
	}

	void executeStartups()
	{
		static foreach (member; FindAnnotatedMembers!startup)
		{
			alias Type = __traits(parent, member);
			enum method = __traits(identifier, member);
			pragma(msg, "@startup: " ~ Type.stringof ~ "#" ~ method);
			Type object = resolve!Type;
			execute!method(object);
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
		Tuple!(Parameters!(__traits(getMember, Type, member))) parameters;
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
		return createRootBean();
	}

	/// Resolve a types and returns an instance of that type.
	Type resolve(Type)()
	if (!is(Type == T))
	{
		static foreach (bean; beans)
		{
			static if (is(bean.Bean == Type))
			{
				pragma(msg, "@bean: " ~ bean.Parent.stringof ~ "#" ~ bean.methodName);
				bean.Parent parent = resolve!(bean.Parent);
				return execute!(bean.methodName)(parent);
			}
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
		private void startupMethod()
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
		@bean private Value getBean(int num, StructValue value)
		{
			return new Value(num, value);
		}

		@bean private int getNum()
		{
			return 5;
		}

		@bean private StructValue getStructValue()
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
	static struct TargetValue
	{
		int value;
	}

	static class ClassC
	{
		@bean private TargetValue getTargetValue()
		{
			return TargetValue(4);
		}
	}

	static class ClassB
	{
		@bean private ClassC getTargetValue()
		{
			return new ClassC;
		}
	}

	static class ClassA
	{
		@bean private ClassB getChild()
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
		@annotation private int getValue()
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
		private int getValue()
		{
			return 5;
		}
	}

	auto container = new Container!Class;
	const value = container.resolve!int;
	assert(value == 5);
}
