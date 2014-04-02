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

### App.d and the router

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
  
  // GET /authors
  @DynamicallyAvailable
  void index() {
    respondTo("html", delegate void() {
      response.render!("authors/index.dt", request);
    });
  }

  // GET /authors/new
  @DynamicallyAvailable
  void init() {
    // render the right view
  }

  // POST /authors
  @DynamicallyAvailable
  void create() {
    // render the right view
  }

  // GET /authors/:id
  @DynamicallyAvailable
  void show() {
    // render the right view
  }

  // GET /authors/:id/edit
  @DynamicallyAvailable
  void edit() {
    // render the right view
  }

  // PUT/PATCH /authors/:id
  @DynamicallyAvailable
  void update() {
    // render the right view
  }

  // DELETE /authors/:id
  @DynamicallyAvailable
  void destroy() {
    // render the right view
  }
}

// /source/core/controllers/books_controller.d

module core.controllers.books;

import action_dispatch.all;

class BooksController : ActionController {
  mixin DynamicClassImplementation!();
  
  // GET /books
  @DynamicallyAvailable
  void index() {
    respondTo("html", delegate void() {
      response.render!("books/index.dt", request);
    });
  }

  // GET /books/new
  @DynamicallyAvailable
  void init() {
    // render the right view
  }

  // POST /books
  @DynamicallyAvailable
  void create() {
    // render the right view
  }

  // GET /books/:id
  @DynamicallyAvailable
  void show() {
    // render the right view
  }

  // GET /books/:id/edit
  @DynamicallyAvailable
  void edit() {
    // render the right view
  }

  // PUT/PATCH /books/:id
  @DynamicallyAvailable
  void update() {
    // render the right view
  }

  // DELETE /books/:id
  @DynamicallyAvailable
  void destroy() {
    // render the right view
  }
}
```

There's a lot going on up there, but it's pretty simple. Basically, for every resource, we have a controller. So for the `books` resource we have the `BooksController` and for the `authors` resource, we have the `AuthorsController`. When a request comes in to `ActionPack` and a match is found, we instantiate a new instance of the controller and call the appropriate method on it. So, if we request `/authors`, internally `ActionPack` is doing something like this:

```d
controller = new AuthorsController(request, response, params);
controller.index();
```

Pretty simple.

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Added some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License

MIT.

