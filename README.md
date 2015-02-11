## emblem-brunch

Adds [Emblem](http://emblemjs.com/) support to [brunch](http://brunch.io).

## Installation

Add `"emblem-brunch": "x.y.z"` to `package.json` of your brunch app.

Pick a plugin version that corresponds to your minor (y) brunch version.

If you want to use git version of plugin, add
`"emblem-brunch": "git+https://github.com/machty/emblem-brunch.git"`.

Download [Emblem](http://emblemjs.com) and [Handlebars](http://handlebarsjs.com).

## Usage

```coffeescript
exports.config =
  files:
    # ...
    templates:
      precompile: true
      root: 'templates'
      defaultExtension: 'emblem'
      joinTo: 'javascripts/app.js'
      paths:
        # If you don't specify jquery and ember there,
        # raw (non-Emberized) Handlebars templates will be compiled.
        jquery: 'bower_components/jquery/jquery.js'
        ember: 'bower_components/ember/ember-debug.js'
        emblem: 'emblem.js'
        
        # for ember version below 1.10.0
        handlebars: 'bower_components/handlebars/handlebars.js'
        
        # for ember version 1.10.0+
        ember_template_compiler: 'bower_components/ember/ember-template-compiler.js'
        
```

### With Ember

Require templates in your main script.

```coffeescript
require 'templates/application'
require 'templates/index'
```

This will configure `Ember.TEMPLATES` automatically.

### Without Ember

Require templates where you need them.

```coffeescript
index_template = require 'templates/index'
```

## Credits

Based on [handlebars-brunch](https://github.com/brunch/handlebars-brunch) and
[ember-precompiler-brunch](https://github.com/chrixian/ember-precompiler-brunch).
