gulp = require 'gulp'

GulpEste = require 'gulp-este'
runSequence = require 'run-sequence'
yargs = require 'yargs'

args = yargs
  .alias 'p', 'production'
  .argv

este = new GulpEste __dirname, args.production, '../../../..'

paths =
  stylus: [
    'app/client/css/app.styl'
  ]
  coffee: [
    'bower_components/este-library/este/**/*.coffee'
    'app/**/*.coffee'
  ]
  js: [
    'bower_components/closure-library/**/*.js'
    'bower_components/este-library/este/**/*.js'
    'app/**/*.js'
    'tmp/**/*.js'
    '!**/build/**'
  ]
  unittest: [
    'app/**/*_test.js'
    # Useful for in app library development together with 'bower link'.
    'bower_components/este-library/este/**/*_test.js'
  ]
  compiler: 'bower_components/closure-compiler/compiler.jar'
  externs: [
    'bower_components/react-externs/externs.js'
  ]
  thirdParty:
    development: [
      'bower_components/pointerevents-polyfill/pointerevents.dev.js'
      'bower_components/react/react-with-addons.js'
    ]
    production: [
      'bower_components/pointerevents-polyfill/pointerevents.min.js'
      'bower_components/react/react-with-addons.min.js'
    ]

dirs =
  googBaseJs: 'bower_components/closure-library/closure/goog'
  nodeJsExterns: 'bower_components/closure-compiler-externs'
  watch: ['app', 'bower_components/este-library/este']

gulp.task 'stylus', ->
  este.stylus paths.stylus

gulp.task 'coffee', ->
  este.coffee paths.coffee

gulp.task 'transpile', (done) ->
  runSequence 'stylus', 'coffee', done

gulp.task 'deps', ->
  este.deps paths.js

gulp.task 'unittest', ->
  este.unitTest dirs.googBaseJs, paths.unittest

gulp.task 'dicontainer', ->
  este.diContainer dirs.googBaseJs, [
    name: 'app.DiContainer'
    resolve: ['App']
  ,
    name: 'server.DiContainer'
    resolve: ['server.App']
  ]

gulp.task 'concat-deps', ->
  este.concatDeps()

gulp.task 'compile-clientapp', ->
  este.compile paths.js, 'app/client/build',
    compilerPath: paths.compiler
    compilerFlags:
      closure_entry_point: 'app.main'
      externs: paths.externs

gulp.task 'compile-serverapp', ->
  este.compile paths.js, 'app/server/build',
    compilerPath: paths.compiler
    compilerFlags:
      closure_entry_point: 'server.main'
      externs: paths.externs
        .concat este.getExterns dirs.nodeJsExterns
      # To have compiled code readable, so we can trace errors.
      debug: true
      formatting: 'PRETTY_PRINT'

gulp.task 'concat-all', ->
  este.concatAll
    'app/client/build/app.js': paths.thirdParty

gulp.task 'livereload-notify', ->
  este.liveReloadNotify()

gulp.task 'js', (done) ->
  runSequence [
    'deps' if este.shouldCreateDeps()
    'unittest'
    'dicontainer'
    'concat-deps'
    [
      'compile-clientapp'
      'compile-serverapp'
    ] if args.production
    'concat-all'
    'livereload-notify' if este.shouldNotify()
    done
  ].filter((task) -> task)...

gulp.task 'build', (done) ->
  runSequence 'transpile', 'js', done

gulp.task 'env', ->
  este.setNodeEnv()

gulp.task 'livereload-server', ->
  este.liveReloadServer()

gulp.task 'watch', ->
  este.watch dirs.watch,
    coffee: 'coffee'
    css: 'livereload-notify'
    js: 'js'
    styl: 'stylus'
  , (task) -> gulp.start task

gulp.task 'server', este.bg 'node', ['app/server']

gulp.task 'run', (done) ->
  runSequence [
    'env'
    'livereload-server' if !args.production
    'watch'
    'server'
    done
  ].filter((task) -> task)...

gulp.task 'default', (done) ->
  runSequence 'build', 'run', done

gulp.task 'bump', (done) ->
  este.bump './*.json', yargs, done