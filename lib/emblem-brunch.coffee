sysPath = require 'path'
fs = require 'fs'
jsdom = require 'jsdom-nogyp'
vm = require 'vm'

module.exports = class EmblemCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'emblem'
  pattern: /\.(?:emblem)$/

  setup: (@config) ->
    @window = vm.createContext(jsdom.jsdom().createWindow())
    @window['navigator'] = {userAgent: 'NodeJS Jsdom'}
    paths = @config.files.templates.paths
    if paths.jquery
      vm.runInContext fs.readFileSync(paths.jquery, 'utf8'), @window, paths.jquery
    if paths.handlebars
      vm.runInContext fs.readFileSync(paths.handlebars, 'utf8'), @window, paths.handlebars
    vm.runInContext fs.readFileSync(paths.emblem, 'utf8'), @window, paths.emblem
    if paths.ember
      vm.runInContext fs.readFileSync(paths.ember, 'utf8'), @window, paths.ember
      @ember = true
    else
      @ember = false

  constructor: (@config) ->
    if @config.files.templates?.paths?
      @setup(@config)
    null

  compile: (data, path, callback) ->
    if not @window?
      return callback "files.templates.paths must be set in your config", {}
    try
      # use nameCleaner to preprocess path
      if @config?.modules?.nameCleaner
        path = @config.modules.nameCleaner(path)
      if @ember
        mapper = @config?.plugins?.emblem?.templateNameMapper
        if mapper?
          path = mapper path
        if @window.Ember.HTMLBars?
          if not @window.Ember.Handlebars.AST?
            ast = @window.Ember.__loader.require("htmlbars-syntax/handlebars/compiler/ast");
            @window.Ember.Handlebars.AST = ast['default']
          content = @window.Emblem.precompile @window.Ember.Handlebars, data
          result = "module.exports = Ember.Handlebars.template(#{content});"
        else
          content = @window.Emblem.precompile @window.Ember.Handlebars, data
          path2 = JSON.stringify(path)
          result = "Ember.TEMPLATES[#{path2}] = Ember.Handlebars.template(#{content});module.exports = #{path2};"
      else
        content = @window.Emblem.precompile @window.Handlebars, data
        result = "module.exports = Handlebars.template(#{content});"
    catch err
      error = err
    finally
      callback error, result
