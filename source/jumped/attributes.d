/**
This module contains all attributes that can be used by Jumped.

These attributes are the main way to control the behaviour of a program written
using the Jumped framework.

Each of these attributes can be added to a function, or to other attributes.
They are detected recursively.
*/
module jumped.attributes;

/**
An annotation that specifies that the given function can be instantiated as a bean.

When this annotation is attached to a method, Jumped will call the method in
order to get an instance of the bean.
*/
struct bean; // @suppress(dscanner.style.phobos_naming_convention)

/**
An annotation that specifies that the given function should be executed when the
program is started.

When this annotation is attached to multiple different methods, the order of
execution is unspecified.
*/
struct startup; // @suppress(dscanner.style.phobos_naming_convention)

/**
An annotation that specifies that the given function should be executed when
the program is stopped.

Any functions annotated with this attribute will always be executed when the
program has stopped, regardless whether an uncaught exception was encountered
earlier or not.
*/
struct shutdown; // @suppress(dscanner.style.phobos_naming_convention)

/**
An annotation that specifies that the given function should be executed when
the program is stopped.

Any functions annotated with this attribute will only be executed when the
program has stopped and no uncaught exception has occured.
*/
struct shutdownOnSuccess; // @suppress(dscanner.style.phobos_naming_convention)

/**
An annotation that specifies that the given function should be executed when
the program is stopped.

Any functions annotated with this attribute will only be executed when the
program has stopped and an oncaught exception has occured.
*/
struct shutdownOnFailure; // @suppress(dscanner.style.phobos_naming_convention)
