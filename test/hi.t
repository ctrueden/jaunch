Tests for simple Java application
Pre-requisites:
1. run `make clean compile-all` in the root directory
2. Ensure a suitable JVM is installed on the system

Setup:

  $ cd "$TESTDIR/../build"
  $ sh ../test/make-app.sh hi

Test 1: help text
  $ ./hi --help
  Usage: hi [<Runtime options>.. --] [<main arguments>..]
  
  Hi launcher (Jaunch * / * / *) (glob)
  Runtime options are passed to the runtime platform (JVM or Python),
  main arguments to the launched program (Hi).
  
  In addition, the following options are supported:
  --java-home <path>
                      specify Java installation path explicitly
  --print-class-path, --print-classpath
                      print runtime classpath elements
  --print-java-home
                      print path to the selected Java
  --print-java-info
                      print information about the selected Java
  --headless
                      run in text mode
  --heap, --mem, --memory <amount>
                      set Java's heap size to <amount> (e.g. 512M or 64%)
  --class-path, --classpath, -classpath, --cp, -cp <path>
                      append <path> to the class path
  --ext <path>
                      set Java's extension directory to <path>
  --debugger <port>[,suspend]
                      start Java in a mode so an IDE/debugger can attach to it
  --help, -h
                      show this help
  --dry-run
                      show the command line, but do not run anything
  --debug
                      verbose output
  --print-app-dir
                      print directory where the application is located
  --print-config-dir
                      print directory where the configuration files are located
  --system
                      do not try to run bundled runtime
--End of help text expected output--

Verify basic functionality
  $ ./hi
  Hello world

Cleanup:
  $ sh ../test/clean-app.sh hi
