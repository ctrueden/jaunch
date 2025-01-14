NB: assumes running on linux x64 system.
Pre-requisites: run `make clean compile-all` in the root directory

Setup:

  $ cd "$TESTDIR/../build"

Test 1: help text

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe
  
  Hello! You have found the Jaunch configurator.
  Your curiosity is an asset. :-)
  
  This program is intended to be called internally by Jaunch's native
  launcher executable. Normally, you do not need to run it yourself.
  
  However, if you wish, you can test its behavior by passing command line
  arguments in the same manner as you would to Jaunch's native launcher,
  prepended by the name of the native launcher executable.
  
  For example, if your native launcher is called fizzbuzz, you could try:
  
      jaunch fizzbuzz --heap 2g --debugger 8000
  
  and watch how Jaunch transforms the arguments.
  If the behavior is not what you expect, try using the --debug flag:
  
      jaunch fizzbuzz --heap 2g --debugger 8000 --debug
  
  You can also see similar information using Jaunch's --dry-run option:
  
      fizzbuzz --heap 2g --debugger 8000 --dry-run
  
  For more details, check out the nearby TOML files. Happy Jaunching!
  
  [1]
--End Test 1 epected output--

Test 2: using jaunch to launch an absent application

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe parsy a b c
  ERROR
  2
  20
  Jaunch config directory not found. Please place config in one of: * (glob)
  [20]
--End of Test 2 expected output--

Test 3: use jaunch configurator manually

  $ mkdir .jaunch
  $ cp -r ../configs/* .jaunch/
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe parsy a b c
  JVM
  7
  *libjvm.so (glob)
  1
  -Xmx64m
  org/scijava/parsington/Main
  a
  b
  c
  $ rm -rf .jaunch
--End of Test 3 expected output--
