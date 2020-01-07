module jumped.introspection;

import std.traits;
import std.algorithm.searching;
import std.meta;

template HasRecursiveUDA(UDA, Symbol)
{
	static if (hasUDA!(Symbol, UDA))
	{
		alias HasRecursiveUDA = Alias!true;
	}
	else
	{
		alias HasRecursiveUDA = HasRecursiveUDA!(UDA, __traits(allMembers, Symbol));
	}
}

template HasRecursiveUDAFrom(UDA, Symbol, Members...)
{
	pragma(msg, Members);
}

unittest
{
	struct Hello
	{
		
	}
}
