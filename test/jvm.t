NB: general tests for Java configuration, using the 'hi' Java program
Pre-requisites:
1. run `make clean compile-all` in the root directory
2. Ensure a suitable JVM is installed on the system

Setup:

  $ cd "$TESTDIR/../build"
  $ sh ../test/make-app.sh hi

Tests:
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --print-java-home
  /*java* (glob)
  ABORT
  0

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --print-java-info
  root: /*java* (glob)
  libjvm: /*libjvm.so (glob)
  version: * (glob)
  distro: Private Build
  OS name: LINUX
  CPU arch: X64
  release file: <none>
  system properties:
  * java.runtime.name=* (glob)
  * sun.boot.library.path=/* (glob)
  * java.vm.version=* (glob)
  * java.vm.vendor=Private Build
  * java.vendor.url=http://java.oracle.com/
  * path.separator=:
  * java.vm.name=* (glob)
  * file.encoding.pkg=sun.io
  * user.country=* (glob)
  * sun.java.launcher=SUN_STANDARD
  * sun.os.patch.level=unknown
  * java.vm.specification.name=Java Virtual Machine Specification
  * user.dir=* (glob)
  * java.runtime.version=* (glob)
  * java.awt.graphicsenv=sun.awt.X11GraphicsEnvironment
  * java.endorsed.dirs=/* (glob)
  * os.arch=amd64
  * java.io.tmpdir=/tmp
  * line.separator=
  * java.vm.specification.vendor=Oracle Corporation
  * os.name=Linux
  * sun.jnu.encoding=* (glob)
  * java.library.path=/* (glob)
  * java.specification.name=Java Platform API Specification
  * java.class.version=* (glob)
  * sun.management.compiler=HotSpot 64-Bit Tiered Compilers
  * os.version=* (glob)
  * user.home=/* (glob)
  * user.timezone=
  * java.awt.printerjob=sun.print.PSPrinterJob
  * file.encoding=* (glob)
  * java.specification.version=* (glob)
  * user.name=* (glob)
  * java.class.path=.
  * java.vm.specification.version=* (glob)
  * sun.arch.data.model=64
  * java.home=* (glob)
  * sun.java.command=Props
  * java.specification.vendor=Oracle Corporation
  * user.language=en
  * awt.toolkit=sun.awt.X11.XToolkit
  * java.vm.info=mixed mode
  * java.version=* (glob)
  * java.ext.dirs=* (glob)
  * sun.boot.class.path=* (glob)
  * java.vendor=Private Build
  * java.specification.maintenance.version=* (glob)
  * file.separator=/
  * java.vendor.url.bug=http://bugreport.sun.com/bugreport/
  * sun.cpu.endian=little
  * sun.io.unicode.encoding=UnicodeLittle
  * sun.cpu.isalist=
  ABORT
  0
--End of expected output--

Memory tests: Verify that all the aliases pass the heap size
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --print-class-path
  <none>
  ABORT
  0

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --heap 2g
  JVM
  5
  /*libjvm.so (glob)
  2
  -Xmx2g
  -Djava.class.path=/* (glob)
  HelloWorld

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --mem 512m
  JVM
  5
  /*libjvm.so (glob)
  2
  -Xmx512m
  -Djava.class.path=/* (glob)
  HelloWorld

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --memory 1g
  JVM
  5
  /*libjvm.so (glob)
  2
  -Xmx1g
  -Djava.class.path=/* (glob)
  HelloWorld

Memory tests: Try running the app using percents with each alias
  $ ./hi --mem 50%
  Hello world

  $ ./hi --memory 25%
  Hello world

  $ ./hi --heap 73%
  Hello world

Memory tests: Run the app to verify the invalid heap size
  $ ./hi --memory -2g
  Invalid maximum heap size: -Xmx-2g
  Error creating Java Virtual Machine
  [3]

Memory tests: use a .cfg file to override memory settings
  $ echo "cfg.max-heap = '50%'" >> .jaunch/hi.toml
  $ echo "jvm.max-heap = '\${cfg.max-heap}'" >> .jaunch/hi.toml
  $ ./hi --dry-run
  [DRY-RUN] /*/bin/java -Djava.class.path=/*/build/.jaunch -Xmx*m HelloWorld (glob)
  $ echo "max-heap=2g" > .jaunch/hi.cfg
  $ ./hi --dry-run
  [DRY-RUN] /*/bin/java -Djava.class.path=/*/build/.jaunch -Xmx2g HelloWorld (glob)
  $ echo "max-heap=4g" > .jaunch/hi.cfg
  $ ./hi --dry-run
  [DRY-RUN] /*/bin/java -Djava.class.path=/*/build/.jaunch -Xmx4g HelloWorld (glob)
  $ rm .jaunch/hi.cfg
  $ rm .jaunch/hi.toml
  $ cp ../configs/hi.toml .jaunch/

Classpath tests: move our .class file and verify we broke things
  $ mv .jaunch/HelloWorld.class .
  $ ./hi
  Error finding class HelloWorld
  [4]

Make sure each alias works now
  $ ./hi --class-path .
  Hello world
  $ ./hi --classpath .
  Hello world
  $ ./hi --cp .
  Hello world
  $ ./hi -classpath .
  Hello world
  $ ./hi -cp .
  Hello world

Move the .class file back
  $ mv ./HelloWorld.class .jaunch/

  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --ext . --dry-run
  [DRY-RUN] /*/bin/java -Djava.ext.dirs=. -Djava.class.path=/*/build/.jaunch HelloWorld (glob)
  ABORT
  0

Verify --headless would pass the correct flags
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --headless --dry-run
  [DRY-RUN] /*java -Djava.awt.headless=true -Dapple.awt.UIElement=true -Djava.class.path=/*/build/.jaunch HelloWorld (glob)
  ABORT
  0

Verify --debugger would pass the correct flags
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --debugger 8000 --dry-run
  [DRY-RUN] /*/bin/java -agentlib:jdwp=transport=dt_socket,server=y,address=localhost:8000 -Djava.class.path=/*/build/.jaunch HelloWorld (glob)
  ABORT
  0

For testing --java-home, we use an invalid path and just verify it's in the search space
  $ ./bin/linuxX64/releaseExecutable/jaunch.kexe hi --java-home . --debug
  [DEBUG] 
  [DEBUG] /--------------------------------------\
  [DEBUG] | PROCEEDING WITH JAUNCH CONFIGURATION |
  [DEBUG] \--------------------------------------/
  [DEBUG] executable -> hi
  [DEBUG] inputArgs -> [--java-home, ., --debug]
  [DEBUG] appDir -> /*/build (glob)
  [DEBUG] configDir -> /*/build/.jaunch (glob)
  [DEBUG] Looking for config file: /*/build/.jaunch/hi.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/hi.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/jvm.toml (glob)
  [DEBUG] Reading config file: /*/build/.jaunch/common.toml (glob)
  [DEBUG] programName -> Hi
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
  [DEBUG] 
  [DEBUG] Input arguments processed:
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --java-home, --debug]
  [DEBUG] * vars -> {app-dir=/*/build, config-dir=/*/build/.jaunch, executable=/*/build/hi, java-home=.} (glob)
  [DEBUG] * userArgs.runtime -> []
  [DEBUG] * userArgs.main -> []
  [DEBUG] * userArgs.ambiguous -> []
  [DEBUG] 
  [DEBUG] Modes applied:
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --java-home, --debug, LAUNCH:JVM]
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
  [DEBUG] * .
  [DEBUG] * /usr/lib/jvm/java-1.8.0-openjdk-amd64
  [DEBUG] * /usr/lib/jvm/java-8-openjdk-amd64
  [DEBUG] 
  [DEBUG] Suffixes to check for libjvm:
  [DEBUG] * lib/server/libjvm.so
  [DEBUG] * jre/lib/amd64/server/libjvm.so
  [DEBUG] 
  [DEBUG] Discovering Java installations...
  [DEBUG] Analyzing candidate JVM directory: '.'
  [DEBUG] No JVM library found.
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
  [DEBUG] * hints -> [OS:LINUX, ARCH:X64, --java-home, --debug, LAUNCH:JVM, JAVA:8, JAVA:0+, JAVA:1+, JAVA:2+, JAVA:3+, JAVA:4+, JAVA:5+, JAVA:6+, JAVA:7+, JAVA:8+]
  [DEBUG] 
  [DEBUG] Default classpath:
  [DEBUG] * /*/build/.jaunch (glob)
  [DEBUG] Default max heap: null
  [DEBUG] 
  [DEBUG] JVM arguments calculated:
  [DEBUG] <empty>
  [DEBUG] 
  [DEBUG] Calculating main class name...
  [DEBUG] mainProgram -> HelloWorld
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
  [DEBUG] * /*/build/.jaunch (glob)
  [DEBUG] Added classpath arg: -Djava.class.path=/*/build/.jaunch (glob)
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
  -Djava.class.path=/*/build/.jaunch (glob)
  HelloWorld
  [DEBUG] 
  [DEBUG] /-------------------------------\
  [DEBUG] | JAUNCH CONFIGURATION COMPLETE |
  [DEBUG] \-------------------------------/
--End of expected output--

Cleanup:
  $ sh ../test/clean-app.sh hi
