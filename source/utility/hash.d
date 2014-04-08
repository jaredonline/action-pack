module utility.hash;

void merge_hash(string[string] hash, string[string] defaults) {
  foreach(string key, string value; defaults) {
    hash[key] = hash.get(key, value);
  }
}

unittest {
  import dunit.toolkit;

  string[string] defaults = [ "foo": "bar", "buzz": "back" ];
  defaults["foo"].assertEqual("bar");

  string[string] options = [ "foo": "bazz" ];
  options["foo"].assertEqual("bazz");

  merge_hash(options, defaults);
  options["buzz"].assertEqual("back");
}
