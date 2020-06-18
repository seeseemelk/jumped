/**
This module contains the core of the Jumped framework.

It contains all the required internal functionality in order to detect and
resolve any dependencies.

For public usage, the main function is `jumpStart`, which will instantiate a
class, resolve dependencies, and executed `@startup` methods.
*/
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

/**
A container is a class that can perform dependency resolution at compile-time,
finding any dependencies through the template parameter.
*/
class Container(T)
{
	private alias beans = DiscoverBeans!T;
	private alias DiscoverBeans(Type) = AliasSeq!(BeanInfo!createRootBean, AllBeansAccessableBy!(BeanInfo!createRootBean));
	private T _rootBean = null;

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

	private template FindAnnotatedMembers(Annotation)
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

	/**
	Executes all methods with a specific annotation.
	Params:
		Annotation = The annotation to filter by.
	*/
	void executeAll(Annotation)()
	{
		static foreach (member; FindAnnotatedMembers!Annotation)
		{
			execute!(__traits(identifier, member))(resolve!(__traits(parent, member)));
		}
	}

	/*void executeAll(Annotation)()
	{
		executeAll!(Annotation, Alias!true)();
	}*/

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

	/**
	Resolve a types and returns an instance of that type.

	This version will detect the root bean, and use special instantiation for
	this specific bean.
	*/
	Type resolve(Type)()
	if (is(Type == T))
	{
		if (_rootBean is null)
			_rootBean = createRootBean();
		return _rootBean;
	}

	/**
	Resolve a types and returns an instance of that type.

	Resolves a bean that has an instantiator (a method annotated with `@bean`).
	*/
	Type resolve(Type)()
	if (!is(Type == T) && hasBeanInstantiator!Type)
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

	/**
	Resolve a types and returns an instance of that type.

	Resolves a bean that does not have an instantiator, but is annotated with
	`@component`.
	*/
	Type resolve(Type)()
	if (!is(Type == T) && !hasBeanInstantiator!Type && hasAnnotation!(component, Type))
	{
		pragma(msg, "@component: " ~ Type.stringof);
		static if (__traits(hasMember, Type, "__ctor"))
		{
			Tuple!(Parameters!(__traits(getMember, Type, "__ctor"))) parameters;
			static foreach (i, parameter; Parameters!(__traits(getMember, Type, "__ctor")))
			{
				parameters[i] = resolve!parameter;
			}
			return new Type(parameters.expand);
		}
		else
		{
			return new Type();
		}
	}

	/**
	Resolve a types and returns an instance of that type.

	Catch-all if the bean cannot be found. Will simply cause a compile error.
	*/
	template resolve(Type)
	if (!is(Type == T) && !hasBeanInstantiator!Type && !hasAnnotation!(component, Type))
	{
		static assert(0, "Could not resolve bean '" ~ Type.stringof ~ "'");
	}

	/**
	Checks if there is a `@bean` instantiator for the given `Type`.
	*/
	private template hasBeanInstantiator(Type)
	{
		private template isBean(Type, alias bean)
		{
			enum isBean = is(bean.Bean == Type);
		}

		enum hasBeanInstantiator = anySatisfy!(ApplyLeft!(isBean, Type), beans);
	}
}

/**
Starts the application.

It will first create an instance of the application. After the application is
instantiated, it will resolve any dependencies required to execute all methods
annotated with `@startup`. Once all `@startup`-methods have finished execution,
it will execute all `@shutdown`-methods.
Params:
	T = The startup class
*/
void jumpStart(T)()
{
	auto container = new Container!T;

	try
	{
		container.executeAll!startup();
		container.executeAll!(shutdownOnSuccess);
	}
	catch (Exception e)
	{
		container.executeAll!(shutdownOnFailure);
	}
	finally
	{
		container.executeAll!(shutdown);
	}
}
