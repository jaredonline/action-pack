module action_dispatch.route;

import action_dispatch.all;

class ActionRoute {
  protected {
    string           _path;
    string           _controllerName;
    string           _action;
    HTTPMethod       _method;
    ActionController _controller;
  }

  public static {
    enum maxRouteParameters = 64;
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

  string[string] params;
  auto route = new ActionRoute(HTTPMethod.GET, "/", "MainController", "index");

  route.path.assertEqual("/");
  route.controllerName.assertEqual("MainController");
  route.method.assertEqual(HTTPMethod.GET);
  route.action.assertEqual("index");

  route.matches("/", params).assertEqual(true);
  route.matches("/foo", params).assertEqual(false);

  auto dynamic_route = new ActionRoute(HTTPMethod.GET, "/users/:id", "UsersController", "show");
  dynamic_route.matches("/users/1", params).assertEqual(true);
  params["id"].assertEqual("1");

  auto star_route = new ActionRoute(HTTPMethod.GET, "/dog/*", "DogsController", "index");
  star_route.matches("/dog/foo/bar", params).assertEqual(true);
  star_route.matches("/cat/foo/bar", params).assertEqual(false);
}
