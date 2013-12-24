module action_dispatch.router;

public import std.variant;
public import std.conv;
public import std.traits;
public import std.typecons;

import vibe.d;
import std.stdio;

import action_dispatch.all;

class ActionRouter : HTTPServerRequestHandler {

  private {
    ActionRoute[][HTTPMethod.max + 1] _routes;
  }

  void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
    auto method = req.method;
    auto route  = route(method, req.path, req.params);

    if (!(route is null)) {
      route.controller.handleRequest(req, res, route.action);
    }
  }

  ActionRoute route(HTTPMethod method, string path, ref string[string] params) {
    string format = fetchFormat(path, params);

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

  ActionRouter assets(string route) {
    match(HTTPMethod.GET, route, "ActionController", "assets");
    return this;
  }

  ActionRouter match(HTTPMethod method, string path, string controller, string action) {
    assert(count(path, ':') <= ActionRoute.maxRouteParameters, "Too many route parameters");
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

  private {
    string fetchFormat(ref string path, ref string[string] params) {
      string format;
      ptrdiff_t index = lastIndexOf(path, '.');
      if (index > -1) {
        format = path[index + 1..path.length];
        path   = path[0..index];
      } else {
        format = "html";
      }

      params["format"] = format;
      return format;
    }
  }
}

unittest {
  import dunit.toolkit;

  string[string] params;
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

  params["blogger_id"].assertEqual("1");
  params["blog_id"].assertEqual("2");
  params["comment_id"].assertEqual("3");

  router.route(HTTPMethod.GET, "/bloggers.json", params).assertInstanceOf!(ActionRoute)();
  params["format"].assertEqual("json");

  router.assets("*");
  auto r = router.route(HTTPMethod.GET, "/js/all.js", params);
  r.assertInstanceOf!(ActionRoute)();
  r.controllerName.assertEqual("ActionController");
  r.action.assertEqual("assets");
}
