Tests for app defined in paunch.toml (essentially just python)

Pre-requisites:
1. run `make clean compile-all` in the root directory
2. Ensure python 3.8+ is available (system or by running in conda env)

Setup:

  $ cd "$TESTDIR/../build"
  $ sh ../test/make-app.sh paunch

Test help text

  $ ./paunch --help
  Usage: paunch [<Runtime options>.. --] [<main arguments>..]
  
  Paunch launcher (Jaunch v* / * / *) (glob)
  Runtime options are passed to the runtime platform (JVM or Python),
  main arguments to the launched program (Paunch).
  
  In addition, the following options are supported:
  --python-home <path>
                      specify PYTHON_HOME explicitly
  --print-python-home
                      print path to the selected Python
  --print-python-info
                      print information about the selected Python
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

Do some basic python stuff
  $ ./paunch -c "print(1+2)"
  3

  $ ./paunch -c "import os; print(os.name)"
  * (glob)

  $ ./paunch -c "import math; print(math.factorial(15))"
  1307674368000

Cleanup:
  $ sh ../test/clean-app.sh paunch
