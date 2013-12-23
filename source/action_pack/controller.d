module action_pack.controller;

import vibe.d;
public import dynamic_loader.dynamic_class;
import std.regex;

class ActionController : DynamicClass {
  mixin DynamicClassImplementation!();

  protected {
    HTTPServerRequest  _request;
    HTTPServerResponse _response;
  }

  @property HTTPServerRequest request() {
    return _request;
  }

  @property HTTPServerResponse response() {
    return _response;
  }

  @property void request(HTTPServerRequest request) {
    _request = request;
  }

  @property void response(HTTPServerResponse response) {
    _response = response;
  }

  void handleRequest(HTTPServerRequest req, HTTPServerResponse res, string action) {
    _request  = req;
    _response = res;
    __send__(action);
  }

  static {
    ActionController loadController(string controllerName, string prefix = "action_pack.controller") {
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
