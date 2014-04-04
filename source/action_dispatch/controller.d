module action_dispatch.controller;

import vibe.d;
public import dynamic_loader.dynamic_class;

import std.regex;
import action_dispatch.format;

class ActionController : DynamicClass {
  mixin DynamicClassImplementation!();

  protected {
    HTTPServerRequest  _request;
    HTTPServerResponse _response;
    string             _format;
  }

  @property {
    HTTPServerRequest request() {
      return _request;
    }

    HTTPServerResponse response() {
      return _response;
    }

    void request(HTTPServerRequest request) {
      _request = request;
    }

    void response(HTTPServerResponse response) {
      _response = response;
    }

    void format(string format) {
      _format = format;
    }
  }

  void handleRequest(HTTPServerRequest req, HTTPServerResponse res, string action) {
    try {
      _request  = req;
      _response = res;
      _format   = req.params["format"];
      __send__(action);
    } finally {
      _request  = null;
      _response = null;
      _format   = null;
    }
  }

  @DynamicallyAvailable
  void assets() {
    serveStaticFiles("./public/")(_request, _response);
  }

  protected {
    void respondTo(string format, void delegate() yield) {
      if (_format == format)
        yield();
    }

    void respondTo(void delegate(Format) yield) {
      auto format = new Format(_format);
      yield(format);
    }
  }

  static {
    ActionController loadController(string controllerName, string prefix = "action_dispatch.controller") {
      string[] builder;
      if (prefix.length > 0)
        builder ~= prefix;

      builder ~= controllerName;

      string factory = join(builder, ".");
      auto   controller = cast(ActionController) Object.factory(factory);

      if (controller is null) {
        foreach (string cName; getAllDynamicClasses()) {
          if (match(cName, controllerName)) {
            return loadController(cName, "");
          }
        }
        throw new Exception("Your class " ~ prefix ~ "." ~ controllerName ~ " isn't callable dynamically. Classes are: " ~ to!string(getAllDynamicClasses()));
      }

      return controller;
    }
  }
}

unittest {
  import dunit.toolkit;

  struct F { int a; }

  class FooController : ActionController {
    mixin DynamicClassImplementation!();

    void foo(out F _foo) {
      respondTo(delegate void(Format format) {
        format.html(delegate void() { _foo.a = 3; });
      });
    }
  }

  // This is a super janky test; basically we're testing that the
  // new version of #respondTo works correctly by setting up
  // the FooController which modifies the `f` variable only
  // when the format is "html"
  F f = { a: 0 };
  auto foo = new FooController;
  foo.format = "html";
  foo.foo(f);
  f.a.assertEqual(3);

  // The negative side of the test just makes sure that it doesn't
  // modify the z struct when the format is set to "json"
  F z = { a: 0 };
  foo.format = "json";
  foo.foo(z);
  z.a.assertEqual(0);
}
