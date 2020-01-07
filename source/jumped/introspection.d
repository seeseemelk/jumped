module jumped.introspection;

import std.traits;
import std.algorithm.searching;
import std.meta;

/// Checks if a symbol has a specified attribute.
/// If the attribute cannot be found, it checks for attributes
/// on the original attribute type itself. It will keep doing this
/// until it cannot found anymore attributes.
template hasRecursiveUDA(alias UDA, alias symbol)
{
	static if (hasUDA!(symbol, UDA))
	{
		alias hasRecursiveUDA = Alias!true;
	}
	else
	{
		alias hasRecursiveUDA = hasRecursiveUDA!(UDA, __traits(getAttributes, symbol));
	}
}

private template hasRecursiveUDA(alias UDA)
{
	alias hasRecursiveUDA = Alias!false;
}

@("HasRecursiveUDA finds all base annotation")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationA
	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasRecursiveUDA!(annotationB, Hello) == true);
}

@("HasRecursiveUDA finds all indirect annotation")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationA
	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasRecursiveUDA!(annotationA, Hello) == true);
}


@("HasRecursiveUDA is false when the attribute cannot be found")
unittest
{
	struct annotationA; // @suppress(dscanner.style.phobos_naming_convention)

	struct annotationB; // @suppress(dscanner.style.phobos_naming_convention)

	@annotationB
	struct Hello;

	static assert(hasRecursiveUDA!(annotationA, Hello) == false);
}
