/+ dub.sdl:
     dependency "jumped" version="~0.1.0"
+/
import jumped;
import std.stdio;

private class MyClass
{
    @startup void startup()
    {
        writeln("Hello, world!");
    }
}

void main()
{
    jumpStart!MyClass;
}
