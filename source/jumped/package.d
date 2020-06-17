/**
Jumped is a dependency-injection framework for D.

It will call startup and shutdown methods automatically, while also resolving
any required parameters automatically. Jumped is able to resolve dependencies
completely at compile-time, throwing compile errors if any dependencies cannot
be resolved.

Jumped is driven mostly by simple annotations, which can be found in the module
`jumped.attributes`.
*/
module jumped;

public
{
    import jumped.beans;
    import jumped.attributes;
}
