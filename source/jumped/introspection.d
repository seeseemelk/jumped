module jumped.introspection;

import std.traits;
import std.traits : hasUDATrait = hasUDA;
import std.algorithm.searching;

/// Gets a list of all members of a type.
string[] getMembers(T)() pure
{
	static immutable members = [__traits(allMembers, T)];
	static immutable objectMembers = [__traits(allMembers, Object)];
	string[] typeMembers;
	static foreach (member; members)
	{
		static if (member != "this" && !objectMembers.findAmong(member))
		{
			typeMembers ~= member;
		}
	}
	return typeMembers;
}

@("getMembers returns a list of all members except members from Object")
unittest
{
	class TestClass
	{
		private int memberA;
		void memberB() {}
	}

	static immutable members = getMembers!TestClass;
	static assert(members.length == 2);
	static assert(members[0] == "memberA");
	static assert(members[1] == "memberB");
}

/// Gets a list of all members that are functions of a type.
string[] getFunctionMembers(T)() pure
{
	string[] functions;
	static foreach (member; getMembers!T)
	{
		static if (isFunction!(__traits(getMember, T, member)))
		{
			functions ~= member;
		}
	}
	return functions;
}

@("getFunctionMembers returns a list of all members that are functions")
unittest
{
	class TestClass
	{
		int memberA;
		void memberB() {}
	}

	static immutable members = getFunctionMembers!TestClass;
	static assert(members.length == 1);
	static assert(members[0] == "memberB");
}

/// Checks wether a type has a given UDA.
template hasUDA(T, string member, UDA)
{
	alias hasUDA = hasUDATrait!(__traits(getMember, T, member), UDA);
}

@("hasUDA should return true if a member has the UDA")
unittest
{
	struct uda1; // @suppress(dscanner.style.phobos_naming_convention)
	class TestClass
	{
		@uda1 int a;
	}
	enum uda = hasUDA!(TestClass, "a", uda1);
	static assert(uda == true);
}
