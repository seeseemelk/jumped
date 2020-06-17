/+ dub.sdl:
     dependency "jumped" path=".."
+/
import jumped;
import std.stdio;

private class MyClass
{
    @startup void setUp()
    {
        writeln("Hello, world!");
    }

    @shutdown void tearDown()
    {
        writeln("Goodbye!");
    }
}

void main()
{
    jumpStart!MyClass;
}
