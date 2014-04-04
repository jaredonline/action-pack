D Lang Action Pack
===========

A router for use with [Vibe-D](http://vibed.org/) that mimics the way routers and controllers work in [Rails](http://rubyonrails.org/).

## Installation

Add the following to your `package.json` file:

```json
"dependencies": {
  "action-pack": "~master"
}
```

## Usage

Here's a very quick sample run through of how you can use the `ActionPack` routing.

### `App.d` and the router

First you have to setup your `app.d` file with your router and your list of routes:

```d
// app.d

import vibe.d;
import action_dispatch.all;

shared static this()
{
	auto router = new ActionRouter;
	router.get("/", "BooksController", "index");
	
	router.resources("authors", delegate void (ActionNamespace authors) {
	  authors.resources("books");
	});

	auto settings = new HTTPServerSettings;
	settings.port = 8080;

	listenHTTP(settings, router);
}
```

In the above example we map the default route of `/` to be handled by the `BooksController` action `index`.

Then we define a resource, `authors` and a sub resource for `authors`: `books`. This generates a routing table:


|Method|Route|Controller|Action|
|:------|:-----------|:-----|:----|
|GET|/|BooksController|#ndex|
|GET|/authors/:author_id/books|BooksController|#index|
|GET|/authors/:author_id/books/new|BooksController|#init|
|POST|/authors/:author_id/books|BooksController|#create|
|GET|/authors/:author_id/books/:id|BooksController|#show|
|GET|/authors/:author_id/books/:id/edit|BooksController|#edit|
|PUT|/authors/:author_id/books/:id|BooksController|#update|
|PATCH|/authors/:author_id/books/:id|BooksController|#update|
|DELETE|/authors/:author_id/books/:id|BooksController|#destroy|
|GET|/authors|AuthorsController|#index|
|GET|/authors/new|AuthorsController|#init|
|POST|/authors|AuthorsController|#create|
|GET|/authors/:id|AuthorsController|#show|
|GET|/authors/:id/edit|AuthorsController|#edit|
|PUT|/authors/:id|AuthorsController|#update|
|PATCH|/authors/:id|AuthorsController|#update|
|DELETE|/authors/:id|AuthorsController|#destroy|


From just a few lines of code we get 17 routes! All with automatic params. As you can see, we made a *ton* of assumptinos to get here, but this way favors convention over a bunch of manual configuration.

### Controllers

Next we setup our two controller:

```d
// /source/core/controllers/authors_controller.d

module core.controllers.authors;

import action_dispatch.all;

class AuthorsController : ActionController {
  mixin DynamicClassImplementation!();
  
  @DynamicallyAvailable {
    // GET /authors
    void index() {
      respondTo(delegate void(Format format) {
        format.html(delegate void() {
          response.render!("books/index.dt", request);
        });

        format.json(delegate void() { // render some JSON });
      });
    }

    // GET /authors/new
    void init() {
      // render the right view
    }

    // POST /authors
    void create() {
      // render the right view
    }

    // GET /authors/:id
    void show() {
      // render the right view
    }

    // GET /authors/:id/edit
    void edit() {
      // render the right view
    }

    // PUT/PATCH /authors/:id
    void update() {
      // render the right view
    }

    // DELETE /authors/:id
    void destroy() {
      // render the right view
    }
  }
}

// /source/core/controllers/books_controller.d

module core.controllers.books;

import action_dispatch.all;

class BooksController : ActionController {
  mixin DynamicClassImplementation!();
  
  @DynamicallyAvailable {
    // GET /authors/:authors_id/books
    void index() {
      respondTo(delegate void(Format format) {
        format.html(delegate void() {
          response.render!("books/index.dt", request);
        });

        format.json(delegate void() { // render some JSON });
      });
    }

    // GET /authors/:authors_id/books/new
    void init() {
      // render the right view
    }

    // POST /authors/:authors_id/books
    void create() {
      // render the right view
    }

    // GET /authors/:authors_id/books/:id
    void show() {
      // render the right view
    }

    // GET /authors/:authors_id/books/:id/edit
    void edit() {
      // render the right view
    }

    // PUT/PATCH /authors/:authors_id/books/:id
    void update() {
      // render the right view
    }

    // DELETE /authors/:authors_id/books/:id
    void destroy() {
      // render the right view
    }
  }
}
```

There's a lot going on up there, but it's pretty simple. Basically, for every resource, we have a controller. So for the `books` resource we have the `BooksController` and for the `authors` resource, we have the `AuthorsController`. When a request comes in to `ActionPack` and a match is found, we instantiate a new instance of the controller and call the appropriate method on it. So, if we request `/authors`, internally `ActionPack` is doing something like this:

```d
controller = new AuthorsController(request, response, params);
controller.index();
```

Pretty simple.

# In depth

I'll go over the concepts more in depth here.

## Controllers

Controllers are objects that represent the group of logic around a single resource. They're the "C" in [MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller). In `action-pack` they have play a central role of responding to requests. Every route is defined with a controller and an action. An action is a method on a controller with the signature:

```d
void()
```

which is pretty easy to implement. They don't return anything (because there isn't anything listening for a return value). They just manipulate the `response` object.

### Actions

Actions can really perform any amount of work required to process a request. They have access to the `request` object and the `response` object as well as the `params`.

### Params

Every action has access to a `@property` called `params`. This has the parsed params from the route with strings as keys. So with the route:

```
/authors/:author_id/books
```

And the URL

```
/authors/1/books
```

The `params` hash will look like this:

```
{
  "params": "1"
}
```

Notice that the `1` is a `string` and not an `integer`.

### respondTo

To make routing more restful, I've added an implementation of Rails `#respondTo` method for `ActionController`. There are two version of the `#respondTo` method.

The first one is:

```d
void respondTo(string format, void delegate() yield)
```

This one takes a `string` as the first argument and a `delegate` method. The string has to be a literal match to the current `format` specified by the controller (based on the extension of the request, for example, `.html`). The delegate is only called if there is a match, otherwise nothing is done.

The second is:

```d
void respondTo(void delegate(Format) yield)
```

This one only takes the `delegate`, but this `delegate` must accept a single argument, which is a `Format` object. The `Format` object is very simple and provides some shortcut methods. This way you can do things like

```d
format.html(delegate void(Format format) { // do stuff here if this an html request });
```

This way, in a single `respondTo` `delegate` method you can address multiple formats.

## Routing

The goal of this is to make routing as dead simple as possible, and to avoid writing a bunch of redundant code. The `vibe.d` example on routing looks like this:

```d
shared static this()
{
  auto router = new URLRouter;
  router.get("/", &index);
}

void index(HTTPServerRequest req, HTTPServerResponse res)
{
	res.render!("index.dt", req);
}
```

For a restful API this would require writing code by hand that looks very similar over and over again:

```d
shared static this()
{
  auto router = new URLRouter;
  router.get("/books");
  router.get("/books/:id");
  router.get("/books/new");

  // etc etc
}
```

And that only gets us through a single resource. Because I come from a Rails background I figured there has to be a way to clean this up.

### Reources

Resources are at the heart of routing in `action-pack`. A resource is defined with just a name, and using that as a default URL root and default controller. Every resource automatically defines several routes. The simples way to define a resource:

```d
auto router = new ActionRouter;
router.resources("books");
```

Because the convention for a resource is well defined, this one line can extrapolate all the routes we intend for this resource and hook them up to the appropriate controller and actions.

#### Nesting

Because resources frequently belong to one another, they can be nested:

```d
auto router = new ActionRouter;
router.resources("authors", delegate void (ActionNamespace authors) {
  authors.resources("books");
});
```

This will generate the `books` routes with a prefix automatically of `authors/:author_id`.

### Custom Routes

Internally when you call `#resources` on `ActionRouter`, it just calls a group of helper methods. All of these methods are publicly accessible, so you can use them to create custom routes.

If you want to have a `GET` request for `/about` (and not an entire resource), you can route it manually:

```d
router.get("/about", "MainController", "about");
```

The first param is the path, the second is the name (as a string) of the controller and the last is the action to call.

### Assets

Assets aren't supported right now, but there's a sort of solution:

```d
router.assets("*");
```

This sets up a globally accepted route, so it should always be defined last. It takes any route and looks in the `./public` folder for a match. Like I said, not that great, but it works.

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Added some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License

MIT.
