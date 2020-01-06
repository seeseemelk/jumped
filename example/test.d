/+ dub.sdl:
     dependency "jumped" version="~master"
+/
import jumped;
import std.stdio;

private class MyClass
{
    @startup void startup()
    {
        writeln("Hello");
    }
}

void main()
{
    jumpStart!MyClass;
}
