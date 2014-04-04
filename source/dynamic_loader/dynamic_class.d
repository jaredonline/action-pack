module dynamic_loader.dynamic_class;

public import std.variant;
public import std.conv;
public import std.traits;
public import std.typecons;

enum  DynamicallyAvailable;
alias Helper(alias T) = T;

interface DynamicClass {
  // Variant is a weird type that says, "This can return
  // variable types". Weird.
  Variant __send__(string method, string[] arguments);
  Variant __send__(string method);
}

bool isDynamicallyAvailable(alias member)() {
  foreach(annotation; __traits(getAttributes, member))
    static if(is(annotation == DynamicallyAvailable))
      return true;

  return false;
}

// TODO: Figure out a way to store the method here so that we can call it
//       again later without having to look it up again.
mixin template DynamicClassImplementation() {
  override Variant __send__(string method, string[] arguments) {
    // Get all the members for the current type
    foreach(memberName; __traits(allMembers, typeof(this))) {

      // if the member name is not a match, skip to the next
      if (memberName != method)
        continue;

      // I don't know why, but you have to check the compiles trait before you
      // can get the member
      static if (__traits(compiles, __traits(getMember, this, memberName))) {

        // setup shorthand for the getMember call
        alias member = Helper!(__traits(getMember, this, memberName));

        // make sure this member is dynamicall callable and is a function
        static if (is(typeof(member) == function) && isDynamicallyAvailable!member) {

          // I honestly don't really understand how this argument stuff works
					ParameterTypeTuple!member functionArguments;

          foreach(index, ref arg; functionArguments) {
            if (index >= arguments.length)
              throw new Exception("Not enough arguments to call " ~ method);

            arg = to!(typeof(arg))(arguments[index]);
          }

          Variant returnValue;

          // setup the return value
          static if (is(ReturnType!member == void))
						member(functionArguments);
					else
						returnValue = member(functionArguments);

					return returnValue;
        }
      }
    }
    throw new Exception("No such method " ~ method);
  }

  override Variant __send__(string method) {
    return __send__(method, []);
  }
}

string[] getAllDynamicClasses() {
	string[] list;

	// ModuleInfo is a class defined in the globally-available object.d
	// that gives info about all the modules. It can be looped over and inspected.
	foreach(mod; ModuleInfo) {
		classList: foreach(classInfo; mod.localClasses) {
			// this is info about all the top-level classes in the program
			if(doesClassMatch(classInfo))
				list ~= classInfo.name;
		}
	}

	return list;
}

// this is runtime info, so we can't use the compile time __traits
// reflection on it, but there's some info available through its methods.
bool doesClassMatch(ClassInfo classInfo) {
	foreach(iface; classInfo.interfaces) {
		// the name is the fully-qualified name, so it includes the module name too
		if(iface.classinfo.name == "dynamic_loader.dynamic_class.DynamicClass") {
			return true;
		}
	}

	// if we haven't found it yet, the interface might still be implemented,
	// just on the base class instead. Redo the check on the base class, if there
	// is one.
	if(classInfo.base !is null)
		return doesClassMatch(classInfo.base);
	return false;
}

unittest {
  import dunit.toolkit;

  class Foo : DynamicClass {
    mixin DynamicClassImplementation!();

    @DynamicallyAvailable {
      string bar() {
        return "Bar";
      }

      string fizzbuzzer(int num) {
        if (num % 15 == 0) {
          return "fizzbuzz";
        } else if (num % 5 == 0) {
          return "buzz";
        } else if (num % 3 == 0) {
          return "fizz";
        } else {
          return to!string(num);
        }
      }
    }
  }

  auto foo = new Foo;
  foo.__send__("bar").assertEqual("Bar");
  foo.__send__("fizzbuzzer", ["1"]).assertEqual("1");
  foo.__send__("fizzbuzzer", ["15"]).assertEqual("fizzbuzz");
}
