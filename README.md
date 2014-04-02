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
|------|-----------|-----|----|
|GET|/|BooksController|#ndex|
|GET|/books|BooksController|#index|
|GET|/books/new|BooksController|#init|
|POST|/books|BooksController|#create|
|GET|/books/:id|BooksController|#show|
|GET|/books/:id/edit|BooksController|#edit|
|PUT|/books/:id|BooksController|#update|
|PATCH|/books/:id|BooksController|#update|
|DELETE|/books/:id|BooksController|#destroy|


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

There's a lot going on up there. 
