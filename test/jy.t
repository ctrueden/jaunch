Tests for jython
Pre-requisites:
1. run `make clean compile-all` in the root directory
2. Ensure a suitable JVM is installed on the system

Setup:

  $ cd "$TESTDIR/../build"
  $ sh ../test/make-app.sh jy
  $ sh ../test/gather-lib.sh org.python jython

Test help text

  $ ./jy --help
  Usage: jy [<Runtime options>.. --] [<main arguments>..]
  
  Jy launcher (Jaunch v* / * / *) (glob)
  Runtime options are passed to the runtime platform (JVM or Python),
  main arguments to the launched program (Jy).
  
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

--End of Test 1 expected output--

Test that the correct Java program actually runs.

  $ ./jy -c 'print(1+2)'
  3

Test system property assignment.

  $ ./jy -Dcake=chocolate -c 'from java.lang import System; print(System.getProperty("cake"))'
  chocolate

Test divider symbol handling.

  $ ./jy -- --dry-run 2>&1
  Unknown option: -- or '--dry-run'
  usage: jython [option] ... [-c cmd | -m mod | file | -] [arg] ...
  Try 'jython -h' for more information.
  [1]

  $ ./jy --dry-run --
  [DRY-RUN] /*/bin/java -Dpython.import.site=false -Dpython.cachedir.skip=true -Dpython.console.encoding=UTF-8 -Djava.class.path=/*/jython-*.jar -Xmx*m org.python.util.jython (glob)

  $ ./jy --dry-run -Dfoo=before -- -Dfoo=after
  [DRY-RUN] /*/bin/java -Dpython.import.site=false -Dpython.cachedir.skip=true -Dpython.console.encoding=UTF-8 -Dfoo=before -Djava.class.path=/*/jython-*.jar -Xmx*m org.python.util.jython -Dfoo=after (glob)

  $ ./jy -Dfoo=before -- -Dfoo=after -c 'from java.lang import System; print(System.getProperty("foo"))'
  after

  $ ./jy bad -- good 2>&1 | head -n1
  Unrecognized runtime argument: bad

Cleanup:
  $ sh ../test/clean-app.sh jy
  $ rm -rf lib
