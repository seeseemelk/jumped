module jumped.attributes;

/// An annotation that specifies that the given function can be instantiated as
// a bean.
struct bean; // @suppress(dscanner.style.phobos_naming_convention)

/// An annotation that specifies that the given function should be executed when
/// the program is started.
struct startup; // @suppress(dscanner.style.phobos_naming_convention)

/// An annotation that specifies that the given function should be executed when
/// the program is stopped.
struct shutdown; // @suppress(dscanner.style.phobos_naming_convention)
