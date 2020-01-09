module jumped.introspection;

import std.traits;
import std.algorithm.searching;
import std.meta;

/// Checks if a symbol has a specified attribute.
/// If the attribute cannot be found, it checks for attributes
/// on the original attribute type itself. It will keep doing this
/// until it cannot found anymore attributes.
template hasAnnotation(alias uda, alias symbol)
{
	static if (hasUDA!(symbol, uda))
	{
		alias hasAnnotation = Alias!true;
	}
	else
	{
		alias hasAnnotation = hasAnnotation!(uda, __traits(getAttributes, symbol));
	}
}

private template hasAnnotation(alias UDA)
{
	alias hasAnnotation = Alias!false;
}

@("hasAnnotation finds all base annotation")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationA
	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasAnnotation!(annotationB, Hello) == true);
}

@("hasAnnotation finds all indirect annotation")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationA
	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasAnnotation!(annotationA, Hello) == true);
}


@("hasAnnotation is false when the annotation cannot be found")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasAnnotation!(annotationA, Hello) == false);
}

/// Finds all members of a symbol that have a specific annotation, directly or
/// indirectly. It returns a tuple of the name of each each member that has them
/// annotation.
template getMembersByAnnotation(alias symbol, alias uda)
{
	alias getMembersByAnnotation = filterSymbolsByAnnotation!(uda, symbol, [__traits(allMembers, symbol)]);
}

private template filterSymbolsByAnnotation(alias uda, alias symbol, alias members)
if (members.length > 1)
{
	alias filterSymbolsByAnnotation = AliasSeq!(
		filterSymbolsByAnnotation!(uda, symbol, [members[0]]),
		filterSymbolsByAnnotation!(uda, symbol, members[1..$])
	);
}

private template filterSymbolsByAnnotation(alias uda, alias symbol, alias members)
if (members.length == 1)
{
	alias member = __traits(getMember, symbol, members[0]);
	static if (hasAnnotation!(uda, member))
	{
		alias filterSymbolsByAnnotation = Alias!(member);
	}
	else
	{
		alias filterSymbolsByAnnotation = AliasSeq!();
	}
}

@("getSymbolsByAnnotation can find symbols with direct annotation")
unittest
{
	struct annotation; // @suppress(dscanner.style.phobos_naming_convention)

	static class MyClass
	{
		@annotation public void someMethod() {}

		public void otherMethod() {}
	}

	alias annotations = getMembersByAnnotation!(MyClass, annotation);
	static assert(annotations.length == 1);
	static assert(__traits(identifier, annotations[0]) == "someMethod");
}

@("getSymbolsByAnnotation can find symbols with indirect annotation")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationA
	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	static class MyClass
	{
		@annotationB public void someMethod() {}

		public void otherMethod() {}
	}

	alias annotations = getMembersByAnnotation!(MyClass, annotationA);
	static assert(annotations.length == 1);
	static assert(__traits(identifier, annotations[0]) == "someMethod");
}

@("getSymbolsByAnnotation returns empty tuple if none were found")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)
	static class MyClass
	{
		public void otherMethod() {}
	}

	alias annotations = getMembersByAnnotation!(MyClass, annotationA);
	static assert(annotations.length == 0);
}
