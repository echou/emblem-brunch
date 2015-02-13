sysPath = require 'path'
fs      = require 'fs'
jsdom   = require 'jsdom-nogyp'
vm      = require 'vm'

module.exports = class EmblemCompiler
  brunchPlugin: yes
  type:         'template'
  extension:    'emblem'
  pattern:      /\.(emblem|hbs|handlebars)$/
  nameCleaner:  (path)->path

  templateFunc:  "Ember.Handlebars.template"
  customWrapper: false

  htmlbars: null

  runScript: (ctx, file)->
    vm.runInContext fs.readFileSync(file, 'utf8'), ctx, file

  setup: (@config) ->
    @window = vm.createContext(jsdom.jsdom().createWindow())
    @window['navigator'] = {userAgent: 'NodeJS Jsdom'}
    paths = @config.files.templates.paths

    @runScript @window, paths.jquery
    @runScript @window, paths.ember

    if paths.ember_template_compiler
      @runScript @window, paths.ember_template_compiler
      @window.Ember.__loader.require("ember-template-compiler")

    if paths.emblem
      @runScript @window, paths.emblem
      @pattern = /\.(emblem|hbs|handlebars)$/
    else
      @pattern = /\.(hbs|handlebars)$/

    es6wrapper = @config.plugins?.es6ModuleTranspiler?.wrapper || 'amd'
    @customWrapper = false
    if not @config.modules?.wrapper and es6wrapper is 'amd'
      @customWrapper = 'amd'

    if @window.Ember.HTMLBars
      @templateFunc = "Ember.HTMLBars.template"
      if not @window.Ember.HTMLBars.AST
        ast = @window.Ember.__loader.require("htmlbars-syntax/handlebars/compiler/ast");
        @window.Ember.HTMLBars.AST = ast['default']
      @htmlbars = @window.Ember.HTMLBars
    else
      @templateFunc = "Ember.Handlebars.template"
      @htmlbars = @window.Ember.Handlebars

    @nameCleaner = @config.modules?.nameCleaner || @config.plugins?.es6ModuleTranspiler?.moduleName || ((path)->path)

  constructor: (@config) ->
    if @config.files.templates?.paths?
      @setup(@config)
    null

  compile: (data, path, callback) ->
    if not @window?
      return callback "files.templates.paths must be set in your config", {}

    ext  = sysPath.extname(path)
    name = sysPath.join(sysPath.dirname(path), sysPath.basename(path, ext)).replace(/[\\]/g, '/')
    name = @nameCleaner(name)
    try
      # use nameCleaner to preprocess path

      templateName = @config?.plugins?.emblem?.templateNameMapper?(name) || name

      if ext is '.emblem'
        content = @window.Emblem.precompile @htmlbars, data
      else
        content = @htmlbars.precompile data

      if @customWrapper is 'amd'
        result = """

define("#{name}", ["exports"], function(__exports__) {
  "use strict";
  __exports__["default"] = #{@templateFunc}(#{content});
});

"""
      else
        result = """

Ember.TEMPLATES["#{templateName}"] = #{@templateFunc}(#{content});
if (module && module.exports) {
  module.exports = "#{templateName}";
}

"""
    catch err
      error = err + " (#{path}"
    finally
      callback error, result
