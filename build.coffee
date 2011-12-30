{Monkey} = require './src/monkey'

CoffeeScript = require 'coffee-script'
fs = require 'fs'
path = require 'path'

header = """
  /**
   * Monkey.js JavaScript Framework v#{Monkey.VERSION}
   * http://github.com/elabs/monkey.js
   *
   * Copyright 2011, Jonas Nicklas
   * Released under the MIT License
   */
"""

exports.Build =
  files: ->
    files = fs.readdirSync 'src'
    for file in files when file.match(/\.coffee$/)
      unless file is 'parser.coffee'
        path = 'src/' + file
        newPath = 'lib/' + file.replace(/\.coffee$/, '.js')
        fs.writeFileSync newPath, CoffeeScript.compile(fs.readFileSync(path).toString(), bare: false)
  parser: ->
    {Parser} = require('./lib/grammar')
    fs.writeFileSync 'lib/parser.js', Parser.generate()
  browser: ->
    requires = ''
    for name in ['monkey', 'events', 'lexer', 'nodes', 'parser', 'properties', 'model', 'collection', 'view']
      requires += """
        require['./#{name}'] = new function() {
          var exports = this;
          #{fs.readFileSync "lib/#{name}.js"}
        };
      """
    code = """
      (function(root) {
        var Monkey = function() {
          function require(path){ return require[path]; }
          #{requires}
          return require['./monkey'].Monkey
        }();

        if(typeof define === 'function' && define.amd) {
          define(function() { return Monkey });
        } else { root.Monkey = Monkey }
      }(this));
    """
    if process.env.MINIFY is 'true'
      {parser, uglify} = require 'uglify-js'
      code = uglify.gen_code uglify.ast_squeeze uglify.ast_mangle parser.parse code
    fs.writeFileSync 'extras/monkey.js', header + '\n' + code