NB: general tests for common configuration, using 'hello' 
Pre-requisites: run `make clean demo` in the root directory

Setup:

  $ cd "$TESTDIR/../demo"

Test: Help text with --help
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello --help
  Usage: hello [<Runtime options>.. --] [<main arguments>..]
  
  Hello launcher (Jaunch v* / * / *) (glob)
  Runtime options are passed to the runtime platform (JVM or Python),
  main arguments to the launched program (Hello).
  
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
  ABORT
  0
--End of expected output--

Test: Help text with -h
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello -h
  Usage: hello [<Runtime options>.. --] [<main arguments>..]
  
  Hello launcher (Jaunch v* / * / *) (glob)
  Runtime options are passed to the runtime platform (JVM or Python),
  main arguments to the launched program (Hello).
  
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
  ABORT
  0
--End of expected output--

Test: Debug output
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello --debug
  [DEBUG] 
  [DEBUG] /--------------------------------------\
  [DEBUG] | PROCEEDING WITH JAUNCH CONFIGURATION |
  [DEBUG] \--------------------------------------/
  [DEBUG] executable -> hello
  [DEBUG] inputArgs -> [--debug]
  [DEBUG] appDir -> /*/build (glob)
  [DEBUG] configDir -> /*/build/.jaunch (glob)
  [DEBUG] Looking for config file: /*/build/.jaunch/hello.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/hello.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/jvm.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/common.toml (glob)
  [DEBUG] programName -> Hello
  [DEBUG] 
  [DEBUG] Parsing supported options...
  [DEBUG] * JaunchOption(flags=[--java-home], assignment=<path>, help=specify Java installation path explicitly)
  [DEBUG] * JaunchOption(flags=[--print-class-path, --print-classpath], assignment=null, help=print runtime classpath elements)
  [DEBUG] * JaunchOption(flags=[--print-java-home], assignment=null, help=print path to the selected Java)
  [DEBUG] * JaunchOption(flags=[--print-java-info], assignment=null, help=print information about the selected Java)
  [DEBUG] * JaunchOption(flags=[--headless], assignment=null, help=run in text mode)
  [DEBUG] * JaunchOption(flags=[--heap, --mem, --memory], assignment=<amount>, help=set Java's heap size to <amount> (e.g. 512M or 64%))
  [DEBUG] * JaunchOption(flags=[--class-path, --classpath, -classpath, --cp, -cp], assignment=<path>, help=append <path> to the class path)
  [DEBUG] * JaunchOption(flags=[--ext], assignment=<path>, help=set Java's extension directory to <path>)
  [DEBUG] * JaunchOption(flags=[--debugger], assignment=<port>[,suspend], help=start Java in a mode so an IDE/debugger can attach to it)
  [DEBUG] * JaunchOption(flags=[--help, -h], assignment=null, help=show this help)
  [DEBUG] * JaunchOption(flags=[--dry-run], assignment=null, help=show the command line, but do not run anything)
  [DEBUG] * JaunchOption(flags=[--debug], assignment=null, help=verbose output)
  [DEBUG] * JaunchOption(flags=[--print-app-dir], assignment=null, help=print directory where the application is located)
  [DEBUG] * JaunchOption(flags=[--print-config-dir], assignment=null, help=print directory where the configuration files are located)
  [DEBUG] * JaunchOption(flags=[--system], assignment=null, help=do not try to run bundled runtime)
  [DEBUG] 
  [DEBUG] Input arguments processed:
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --debug]
  [DEBUG] * vars -> {app-dir=/*/build, config-dir=/*/build/.jaunch} (glob)
  [DEBUG] * userArgs.runtime -> []
  [DEBUG] * userArgs.main -> []
  [DEBUG] * userArgs.ambiguous -> []
  [DEBUG] 
  [DEBUG] Modes applied:
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --debug, LAUNCH:JVM]
  [DEBUG] 
  [DEBUG] /------------------------\
  [DEBUG] | CALCULATING DIRECTIVES |
  [DEBUG] \------------------------/
  [DEBUG] 
  [DEBUG] Directives parsed:
  [DEBUG] * directives -> [JVM]
  [DEBUG] * launchDirectives -> [JVM]
  [DEBUG] * configDirectives -> []
  [DEBUG] 
  [DEBUG] /-----------------------------\
  [DEBUG] | EXECUTING GLOBAL DIRECTIVES |
  [DEBUG] \-----------------------------/
  [DEBUG] 
  [DEBUG] Executing runtime-independent directives...
  [DEBUG] 
  [DEBUG] /--------------------------\
  [DEBUG] | CONFIGURING RUNTIME: JVM |
  [DEBUG] \--------------------------/
  [DEBUG] 
  [DEBUG] Root paths to search for Java:
  [DEBUG] * /usr/lib/jvm/java-1.8.0-openjdk-amd64
  [DEBUG] * /usr/lib/jvm/java-8-openjdk-amd64
  [DEBUG] 
  [DEBUG] Suffixes to check for libjvm:
  [DEBUG] * lib/server/libjvm.so
  [DEBUG] * jre/lib/amd64/server/libjvm.so
  [DEBUG] 
  [DEBUG] Discovering Java installations...
  [DEBUG] Analyzing candidate JVM directory: '*' (glob)
  [DEBUG] Guessing OS name...
  [DEBUG] Reading release file...
  [DEBUG] Invoking `"*/bin/java" Props`... (glob)
  [DEBUG] -> OS name: LINUX
  [DEBUG] Guessing CPU architecture...
  [DEBUG] -> CPU architecture: X64
  [DEBUG] Guessing Java version...
  [DEBUG] * rootString -> java-1.8.0-openjdk-
  [DEBUG] * versions8u -> []
  [DEBUG] * versionsPrefixed -> [1.8.0]
  [DEBUG] -> Java version: 1.8.0
  [DEBUG] Successfully discovered Java installation:
  [DEBUG] * rootPath -> /* (glob)
  [DEBUG] * libjvmPath -> /*/libjvm.so (glob)
  [DEBUG] * binJava -> /*/bin/java (glob)
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --debug, LAUNCH:JVM, JAVA:8, JAVA:0+, JAVA:1+, JAVA:2+, JAVA:3+, JAVA:4+, JAVA:5+, JAVA:6+, JAVA:7+, JAVA:8+]
  [DEBUG] 
  [DEBUG] Default classpath:
  [DEBUG] * /*/build (glob)
  [DEBUG] Default max heap: null
  [DEBUG] 
  [DEBUG] JVM arguments calculated:
  [DEBUG] <empty>
  [DEBUG] 
  [DEBUG] Calculating main class name...
  [DEBUG] mainProgram -> HelloSwing
  [DEBUG] 
  [DEBUG] Main arguments calculated:
  [DEBUG] <empty>
  [DEBUG] 
  [DEBUG] /-------------------------\
  [DEBUG] | BUILDING ARGUMENT LISTS |
  [DEBUG] \-------------------------/
  [DEBUG] 
  [DEBUG] Validating user arguments...
  [DEBUG] Contextualizing user arguments...
  [DEBUG] * jvm:runtime -> []
  [DEBUG] * jvm:main -> []
  [DEBUG] Guessing Java distribution...
  [DEBUG] -> Java distribution: Private Build
  [DEBUG] 
  [DEBUG] Classpath finalized:
  [DEBUG] * /*/build (glob)
  [DEBUG] Added classpath arg: -Djava.class.path=/*/build (glob)
  [DEBUG] 
  [DEBUG] Finalizing max heap settings...
  [DEBUG] 
  [DEBUG] /----------------------\
  [DEBUG] | EXECUTING DIRECTIVES |
  [DEBUG] \----------------------/
  [DEBUG] 
  [DEBUG] Executing configurator-side directives...
  [DEBUG] 
  [DEBUG] Emitting launch directives to stdout...
  [DEBUG] Processing directive: JVM
  JVM
  4
  /*/libjvm.so (glob)
  1
  -Djava.class.path=/*/build (glob)
  HelloSwing
  [DEBUG] 
  [DEBUG] /-------------------------------\
  [DEBUG] | JAUNCH CONFIGURATION COMPLETE |
  [DEBUG] \-------------------------------/
--End of expected output--

Test: dry-run
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello --dry-run
  [DRY-RUN] /*/bin/java -Djava.class.path=/*/build HelloSwing (glob)
  ABORT
  0

Test: print-app-dir
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello --print-app-dir
  --- Application Directory ---
  /*/build (glob)
  
  JVM
  4
  /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre/lib/amd64/server/libjvm.so
  1
  -Djava.class.path=/*/build (glob)
  HelloSwing

Test: print-config-dir
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hello --print-config-dir
  --- Configuration Directory ---
  /home/*/build/.jaunch (glob)
  
  JVM
  4
  /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre/lib/amd64/server/libjvm.so
  1
  -Djava.class.path=/*/build (glob)
  HelloSwing
