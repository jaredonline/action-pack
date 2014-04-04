module action_dispatch.format;

class Format {
  protected {
    string _format;
  }

  this(string format) {
    _format = format;
  }

  @property string format() {
    return _format;
  }

  void html(void delegate() yield) {
    yield_for_format("html", yield);
  }

  void json(void delegate() yield) {
    yield_for_format("json", yield);
  }

  void xml(void delegate() yield) {
    yield_for_format("xml", yield);
  }

  protected {
    void yield_for_format(string format, void delegate() yield) {
      if (_format == format) {
        yield();
      }
    }
  }
}

unittest {
  import dunit.toolkit;

  struct Foo { int a; }

  Foo html_foo = { a: 0 };
  html_foo.a.assertEqual(0);
  auto html_f = new Format("html");
  html_f.format.assertEqual("html");
  html_f.html(delegate void() { html_foo.a = 2; });
  html_foo.a.assertEqual(2);
  html_f.xml(delegate void() { html_foo.a = 3; });
  html_foo.a.assertEqual(2);

  Foo json_foo = { a: 1 };
  auto json_f = new Format("json");
  json_f.format.assertEqual("json");
  json_f.json(delegate void() { json_foo.a = 3; });
  json_foo.a.assertEqual(3);
  json_f.html(delegate void() { json_foo.a = 0; });
  json_foo.a.assertEqual(3);

  Foo xml_foo = { a: 5 };
  auto xml_f = new Format("xml");
  xml_f.format.assertEqual("xml");
  xml_f.xml(delegate void() { xml_foo.a = 4; });
  xml_foo.a.assertEqual(4);
  xml_f.json(delegate void() { xml_foo.a = 6; });
  xml_foo.a.assertEqual(4);
}
