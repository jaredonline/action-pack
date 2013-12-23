module action_pack.router;

public import std.variant;
public import std.conv;
public import std.traits;
public import std.typecons;

import vibe.d;
import std.stdio;

import action_pack.controller;

class ActionRouter : HTTPServerRequestHandler {

  void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
    auto method = req.method;
    auto route  = route(method, req.path, req.params);

    if (!(route is null)) {
      route.controller.handleRequest(req, res, route.action);
    }
  }

  ActionRoute route(HTTPMethod method, string path, ref string[string] params) {
    while (true) {
      if (auto pr = &_routes[method]) {
        foreach( ref r; *pr ) {
          if (r.matches(path, params)) {
            return r;
          }
        }
      }
      if (method == HTTPMethod.HEAD) method = HTTPMethod.GET;
      else break;
    }
    return null;
  }

  private {
    ActionRoute[][HTTPMethod.max + 1] _routes;
  }

  ActionRouter resources(string resources, string prefix = "") {
    string controller = controllerizeString(resources);

    if (prefix.length > 0)
      prefix = "/" ~ prefix;

    // this is our routing table for a resource
    get(   prefix ~ "/" ~ resources,               controller, "index");
    get(   prefix ~ "/" ~ resources ~ "/new",      controller, "init");
    post(  prefix ~ "/" ~ resources,               controller, "create");
    get(   prefix ~ "/" ~ resources ~ "/:id",      controller, "show");
    get(   prefix ~ "/" ~ resources ~ "/:id/edit", controller, "edit");
    patch( prefix ~ "/" ~ resources ~ "/:id",      controller, "update");
    put(   prefix ~ "/" ~ resources ~ "/:id",      controller, "update");
    del(   prefix ~ "/" ~ resources ~ "/:id",      controller, "destroy");
    return this;
  }

  ActionRouter resources(string resource, void delegate(ActionNamespace namespace) yield) {
    resources(resource);

    auto namespace = new ActionNamespace(this, resource);
    yield(namespace);
    return this;
  }

  ActionRouter get(string route, string controller, string action) {
    match(HTTPMethod.GET, route, controller, action);
    return this;
  }

  ActionRouter put(string route, string controller, string action) {
    match(HTTPMethod.PUT, route, controller, action);
    return this;
  }

  ActionRouter patch(string route, string controller, string action) {
    match(HTTPMethod.PATCH, route, controller, action);
    return this;
  }

  ActionRouter post(string route, string controller, string action) {
    match(HTTPMethod.POST, route, controller, action);
    return this;
  }

  ActionRouter del(string route, string controller, string action) {
    match(HTTPMethod.DELETE, route, controller, action);
    return this;
  }

  ActionRouter match(HTTPMethod method, string path, string controller, string action) {
    assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
    auto route = new ActionRoute(method, path, controller, action);
    _routes[method] ~= route;
    return this;
  }

  @property typeof(_routes) routes() {
    return _routes;
  }

  string controllerizeString(string resource) {
    string retValue = "";

    foreach(str; split(resource, "_")) {
      retValue ~= str.capitalize;
    }
    return retValue ~ "Controller";
  }
}

class ActionNamespace {
  private {
    ActionRouter _router;
    string[]     _namespaces;
    string[]     _variables;
  }

  this(ActionRouter router, string namespace) {
    this(router, [namespace]);
  }

  this(ActionRouter router, string[] namespaces) {
    _router     = router;
    foreach(ns; namespaces) {
      _namespaces ~= ns;
      _variables  ~= ":" ~ singularize(ns) ~ "_id";
    }
  }

  string joinPrefix() {
    string[] prefix;
    for (int i = 0; i < _namespaces.length; i++) {
      prefix ~= _namespaces[i];
      prefix ~= _variables[i];
    }

    return join(prefix, "/");
  }

  ActionRouter resources(string resource) {
    _router.resources(resource, joinPrefix());
    return _router;
  }

  ActionRouter resources(string resource, void delegate(ActionNamespace namespace) yield) {
    resources(resource);

    auto namespace = new ActionNamespace(_router, _namespaces ~ resource);
    yield(namespace);
    return _router;
  }

  private {
    string singularize(string input) {
      // classes case
      if (input[input.length - 3..input.length - 1] == "ses")
        return input[0..input.length - 3];
      // books case
      else if (input[input.length - 1] == 's')
        return input[0..input.length - 1];

      return input;
    }
  }
}

private enum maxRouteParameters = 64;

class ActionRoute {
  protected {
    string           _path;
    string           _controllerName;
    string           _action;
    HTTPMethod       _method;
    ActionController _controller;
  }

  this(HTTPMethod method, string path, string controllerName, string action) {
    _controllerName = controllerName;
    _method         = method;
    _path           = path;
    _action         = action;
  }

  @property string controllerName() {
    return _controllerName;
  }

  @property string path() {
    return _path;
  }

  @property HTTPMethod method() {
    return _method;
  }

  @property string action() {
    return _action;
  }

  @property ActionController controller() {
    if (_controller is null) {
      _controller = ActionController.loadController(_controllerName);
    }

    return _controller;
  }

  override string toString() {
    string method;
    if (_method == HTTPMethod.GET)
      method = "GET";
    else if (_method == HTTPMethod.PUT)
      method = "PUT";
    else if (_method == HTTPMethod.POST)
      method = "POST";
    else if (_method == HTTPMethod.PATCH)
      method = "PATCH";
    else if (_method == HTTPMethod.DELETE)
      method = "DELETE";

    return "#" ~ method ~ "\t\t" ~ _path ~ "\t\t" ~ _controllerName ~ "\t\t#" ~ _action;
  }

  bool matches(string url, ref string[string] params) const {
    size_t i, j;

    Tuple!(string, string)[maxRouteParameters] tmpparams;
    size_t tmpparams_length = 0;

    // if the url matches the path totally, just return true;
    // that means there are no variables in the url
    if (url == _path)
      return true;

    // if there's not a direct match, loop through looking
    // for a wildcard or variable declaration
    for (i = 0, j = 0; i < url.length && j < _path.length;) {

      // if we hit a wildcard add any accumulated tmpparams
      // to the params dictionary
      if (_path[j] == '*') {
        foreach (t; tmpparams[0..tmpparams_length])
          params[t[0]] = t[1];
        return true;
      }

      // if the current index in the url and the _path match
      // continue to the next index for each
      if (url[i] == _path[j]) {
        i++;
        j++;
      }
      // if we encounter a variable we need to find out what it
      // is called, and what the value is. We store it in the tmp
      // params dictionary until we verify the full match
      else if (_path[j] == ':') {
        j++;
        string name =  skipPathNode(_path, j);
        string match = skipPathNode(url, i);
        assert(tmpparams_length < maxRouteParameters, "Maximum number of route parameters exceeded.");
        tmpparams[tmpparams_length++] = tuple(name, urlDecode(match));
      }
      // if we get this far we don't have a match so we exit
      else return false;
    }

    // if we exit the for loop and get here we just need to move the
    // tmp params to the actual params dictionary and return true
    if ((j < _path.length && _path[j] == '*') || (i == url.length && j == _path.length)) {
      foreach (t; tmpparams[0..tmpparams_length])
          params[t[0]] = t[1];
      return true;
    }

    // falling all the way through gives us a false hit on the match
    return false;
  }
}

// helper method to just jump forward a variable name
// or a value name
private string skipPathNode(string str, ref size_t idx) {
  size_t start = idx;
  while ( idx < str.length && str[idx] != '/' ) idx++;
  return str[start .. idx];
}

unittest {
  import dunit.toolkit;

  class MainController : ActionController {
    mixin DynamicClassImplementation!();
  }

  string[string] params;
  auto route = new ActionRoute(HTTPMethod.GET, "/", "MainController", "index");
  route.path.assertEqual("/");
  route.controllerName.assertEqual("MainController");
  route.method.assertEqual(HTTPMethod.GET);
  route.action.assertEqual("index");
  //to!string(route.controller).assertEqual("core.controllers.main.MainController");

  route.matches("/", params).assertEqual(true);
  route.matches("/foo", params).assertEqual(false);

  auto dynamic_route = new ActionRoute(HTTPMethod.GET, "/users/:id", "UsersController", "show");
  dynamic_route.matches("/users/1", params).assertEqual(true);
  params["id"].assertEqual("1");

  auto star_route = new ActionRoute(HTTPMethod.GET, "/dog/*", "DogsController", "index");
  star_route.matches("/dog/foo/bar", params).assertEqual(true);
  star_route.matches("/cat/foo/bar", params).assertEqual(false);

  auto router = new ActionRouter;
  router.get("/", "MainController", "index");

  router.controllerizeString("foos").assertEqual("FoosController");
  router.controllerizeString("classes").assertEqual("ClassesController");
  router.controllerizeString("toes").assertEqual("ToesController");
  router.controllerizeString("foo_bars").assertEqual("FooBarsController");

  router.resources("foos");
  router.route(HTTPMethod.GET, "/foos", params).assertInstanceOf!(ActionRoute)();
  router.route(HTTPMethod.GET, "/foos/1", params).assertInstanceOf!(ActionRoute)();
  router.resources("spreads");

  router.resources("authors", delegate void (ActionNamespace authors) {
    authors.resources("books");
  });

  router.route(HTTPMethod.GET, "/authors/1/books/12", params).assertInstanceOf!(ActionRoute)();
  params["author_id"].assertEqual("1");

  router.resources("bloggers", delegate void (ActionNamespace bloggers) {
    bloggers.resources("blogs", delegate void (ActionNamespace blogs) {
      blogs.resources("comments", delegate void(ActionNamespace comments) {
        comments.resources("responses");
      });
    });
  });

  router.route(HTTPMethod.GET, "/bloggers/1/blogs/2/comments/3", params).assertInstanceOf!(ActionRoute)();
  router.route(HTTPMethod.GET, "/bloggers/1/blogs/2/comments/3/responses", params).assertInstanceOf!(ActionRoute)();
}
