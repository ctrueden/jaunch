// Main entry point for Jaunch configurator.

import platform.posix.exit

const val USAGE_MESSAGE = """
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
"""

@Suppress("ArrayInDataClass")
data class JaunchOption(
    val flags: Array<String>,
    val assignment: String?,
    val help: String?,
) {
    fun help(): String = buildString {
        val indent = "$NL                    "
        append(flags.joinToString(", "))
        assignment?.let { append(" $it") }
        help?.let { append("$indent${it.replace("\n", indent)}") }
    }
}

typealias JaunchOptions = Map<String, JaunchOption>

fun main(args: Array<String>) {
    if (args.isEmpty()) {
        // The program was run without arguments, likely manually.
        // So we display a friendly greeting with tips, then quit.
        printlnErr(USAGE_MESSAGE)
        exit(1)
    }

    val (exeFile, inputArgs) = parseArguments(args)
    val appDir = discernAppDirectory(exeFile)
    val configDir = findConfigDirectory(appDir)
    val configFile = findConfigFile(configDir, exeFile)
    if (logFilePath == null) logFilePath = "${configFile.base.name}.log"
    val config = readConfig(configFile)

    val programName = config.programName ?: exeFile?.base?.name ?: "Jaunch"
    debug("programName -> ", programName)

    val supportedOptions: JaunchOptions = parseSupportedOptions(config.supportedOptions.asIterable())

    val hints = createHints()

    // Declare a set to store option parameter values.
    // It will be populated at argument parsing time.
    val vars = Vars(appDir, configDir, exeFile, config.cfgVars)

    // Sort out the arguments, keeping the user-specified runtime and main arguments in a struct. At this point,
    // it may yet be ambiguous whether certain user args belong with the runtime, the main program, or neither.
    val userArgs = classifyArguments(inputArgs, supportedOptions, vars, hints)

    applyModeHints(config.modes, hints, vars)

    val (launchDirectives, configDirectives) = calculateDirectives(config, hints, vars)

    // Declare the global (runtime-agnostic) directives.
    val globalDirectiveFunctions: DirectivesMap = mutableMapOf(
        "apply-update" to { _ -> applyUpdate(appDir, appDir / "update") },
        "dry-run" to { _ -> dryRunMode = true },
        "help" to { _ -> help(exeFile, programName, supportedOptions) },
        "print-app-dir" to { _ -> printDir(appDir, "Application") },
        "print-config-dir" to { _ -> printDir(configDir, "Configuration") },
    )

    // Execute the global directives (e.g. applying updates) before configuring
    // runtimes (e.g. building classpaths)
    val nonGlobalDirectives = executeGlobalDirectives(globalDirectiveFunctions,
        configDirectives, userArgs)

    val runtimes = configureRuntimes(config, configDir, hints, vars)

    debugBanner("BUILDING ARGUMENT LISTS")

    // Ensure that the user arguments meet our expectations.
    validateUserArgs(config, runtimes, userArgs)

    val argsInContext = contextualizeArgs(runtimes, userArgs, vars)

    // Now evaluate any expressions in the contextualized arguments.
    // We do this in a subsequent step separated from the previous one because the expressions
    // in question might themselves refer to the contextualized arguments of other runtimes.
    // Why? So that we can e.g. pass the final JVM arguments to a PYTHON launch, where the
    // Python script being invoked will itself start up a JVM with those given JVM arguments.
    // In the case of cyclic variable references between runtimes, the interpolation will be incomplete.
    for (programArgs in argsInContext.values) {
        vars.interpolateInto(programArgs.runtime)
        vars.interpolateInto(programArgs.main)
    }

    // Now that our program arguments have been fully interpolated, we offer the
    // runtimes an additional opportunity to perform any runtime-specific
    // custom logic (for example, resolving %'s in -Xmx notation).
    for (programArgs in argsInContext.values) {
        for (runtime in runtimes) {
            runtime.processArgs(programArgs.runtime)
        }
    }

    // Finally, execute all the remaining directives! \^_^/
    executeDirectives(nonGlobalDirectives, launchDirectives, runtimes, argsInContext)

    debugBanner("JAUNCH CONFIGURATION COMPLETE")
}

// -- Program flow functions --

private fun parseArguments(args: Array<String>): Pair<File?, List<String>> {
    // If a sole `-` argument was given on the CLI, read the arguments from stdin.
    val theArgs = if (args.size == 1 && args[0] == "-") stdinLines() else args

    // The first argument is the path to the calling executable.
    val executable = theArgs.getOrNull(0)

    // Subsequent arguments were specified by the user.
    val inputArgs = theArgs.slice(1..<theArgs.size)

    // Enable debug mode when --debug flag is present.
    debugMode = inputArgs.contains("--debug")

    // Note: We need to let parseArguments set the debugMode
    // flag in response to the --debug argument being passed.
    // So we wait until now to emit this initial debugging bookend message.
    debugBanner("PROCEEDING WITH JAUNCH CONFIGURATION")

    debug("executable -> ", executable ?: "<null>")
    debug("inputArgs -> ", inputArgs)

    val exeFile = executable?.let(::File) // The native launcher program.
    return Pair(exeFile, inputArgs)
}

private fun discernAppDirectory(exeFile: File?): File {
    // Check for native launcher in Contents/MacOS directory.
    // If so, treat the app directory as two directories higher up.
    // We do it this way, rather than OS_NAME == "MACOSX", so that the native
    // launcher also works on macOS when placed directly in the app directory.
    val exeDir = exeFile?.dir ?: File(".")
    val appDir = if (exeDir.name == "MacOS" && exeDir.dir.name == "Contents") exeDir.dir.dir else exeDir
    debug("appDir -> ", appDir)
    return appDir
}

private fun findConfigDirectory(appDir: File): File {
    // NB: This list should match the JAUNCH_SEARCH_PATHS array in jaunch.c.
    val configDirs = listOf(
        appDir / "jaunch",
        appDir / ".jaunch",
        appDir / "config" / "jaunch",
        appDir / ".config" / "jaunch"
    )
    val configDir = configDirs.find { it.isDirectory }
        ?: fail("Jaunch config directory not found. Please place config in one of: $configDirs")
    debug("configDir -> ", configDir)
    return configDir
}

private fun findConfigFile(configDir: File, exeFile: File?): File {
    var fileName = exeFile?.base?.name ?: "jaunch"
    // The launcher might have trailing suffixes such as OS_NAME and/or CPU_ARCH.
    // For example: fizzbuzz-linux-x64. In such a situation, we want to look for
    // fizzbuzz-linux-x64.toml, fizzbuzz-linux.toml, and fizzbuzz.toml.
    while (true) {
        val configFile = configDir / "$fileName.toml"
        debug("Looking for config file: $configFile")
        if (configFile.exists) return configFile
        val dash = fileName.lastIndexOf("-")
        if (dash < 0) break
        fileName = fileName.substring(0, dash)
    }
    fail("No config file found for $fileName")
}

/**
 * Parse the configuration's declared Jaunch options, wrapping each into a `JaunchOption` object.
 *
 * For each option, we have a string of the form:
 *   --alpha,...,--omega=assignment|Description of what this option does.
 *
 * We need to parse out the help text, the actual flags list, and whether the flags expect an assignment value.
 *
 * @param supportedOptions A `supportedOptions` list from a `JaunchConfig`.
 * @return a map of supported options, from each of the option's flags to the corresponding JaunchOption object.
 */
private fun parseSupportedOptions(supportedOptions: Iterable<String>): JaunchOptions {
    debug()
    debug("Parsing supported options...")
    return buildMap {
        for (optionLine in supportedOptions) {
            val (optionString, help) = optionLine bisect '|'
            val (flagsString, assignment) = optionString bisect '='
            val flags = flagsString.split(',')
            val option = JaunchOption(flags.toTypedArray(), assignment, help)
            debug("* ", option)
            for (flag in flags) this[flag] = option
        }
    }
}

/**
 * Declare a set of active hints, for activation of configuration elements.
 * Initially populated with hints for the current operating system and CPU architecture,
 * but it will grow over the course of the configuration process below.
 */
private fun createHints(): MutableSet<String> {
    val hints = mutableSetOf(
        // Kotlin knows these operating systems:
        //   UNKNOWN, MACOSX, IOS, LINUX, WINDOWS, ANDROID, WASM, TVOS, WATCHOS
        "OS:$OS_NAME",
        // Kotlin knows these CPU architectures:
        //   UNKNOWN, ARM32, ARM64, X86, X64, MIPS32, MIPSEL32, WASM32
        "ARCH:$CPU_ARCH"
    )
    return hints
}

/**
 * Categorize the configurator's input arguments.
 *
 * An input argument matching one of Jaunch's supported options becomes an active hint.
 * So e.g. `--foo` would be added to the hints set as `--foo`.
 *
 * A matching input argument that takes a parameter not only adds the option as a hint,
 * but also adds the parameter value to the vars map.
 * So e.g. `--sigmas=5` would add the `--sigma` hint, and add `"5"` as the value for the `sigma` variable.
 * Variable values will be interpolated into argument strings later in the configuration process.
 *
 * Non-matching input arguments will be returned as a [ProgramArgs] struct, with each argument
 * sorted into one of three buckets: runtime args, main args, and ambiguous args. The exact
 * behavior will depend on whether the user provided the `--` separator in the input argument list.
 */
private fun classifyArguments(
    inputArgs: List<String>,
    supportedOptions: JaunchOptions,
    vars: Vars,
    hints: MutableSet<String>
): ProgramArgs {
    val userArgs = ProgramArgs()
    val divider = inputArgs.indexOf("--")
    var i = 0
    while (i < inputArgs.size) {
        val arg = inputArgs[i++]

        // Handle both --key and --key=value kinds of arguments.
        val equals = arg.indexOf("=")
        val argKey = if (equals >= 0) arg.substring(0, equals) else arg
        val argVal = if (equals >= 0) arg.substring(equals + 1) else null

        if (argKey == "--") {
            if (argVal != null) fail("Divider symbol (--) does not accept a parameter")
            if (i - 1 != divider) fail("Divider symbol (--) may only be given once")
        } else if ((divider < 0 || i <= divider) && argKey in supportedOptions) {
            // The argument is declared in Jaunch's configuration. Deal with it appropriately.
            val option: JaunchOption = supportedOptions[argKey]!!
            if (option.assignment == null) {
                // standalone option
                if (argVal != null) fail("Option $argKey does not accept a parameter")
            } else {
                // option with value assignment
                val v = argVal ?: if (i < inputArgs.size) inputArgs[i++] else
                    fail("No parameter value given for argument $argKey")

                // Normalize the argument to the primary flag on the comma-separated list.
                // Then strip leading dashes: --class-path becomes class-path, -v becomes v, etc.
                var varName = option.flags.first()
                while (varName.startsWith("-")) varName = varName.substring(1)

                // Store assignment value as a variable named after the normalized argument.
                // E.g. if the matching supported option is `--heap,--mem=<max>|Maximum heap size`,
                // and `--mem 52g` is given, it will store `"52g"` for the variable `heap`.
                vars[varName] = v
            }
            // Record hint matching the primary form of the option, not an alias.
            hints += option.flags.first()
        } else {
            // The argument is not a Jaunch one. Save it for later.
            if (divider < 0) {
                // No dash-dash divider was given, so we will need to guess later: runtime arg or main arg?
                userArgs.ambiguous += arg
            } else if (i <= divider) {
                // This argument is before the dash-dash divider, so must be treated as a runtime arg.
                userArgs.runtime += arg
            } else {
                // This argument is after the dash-dash divider, so we treat it as a main arg.
                userArgs.main += arg
            }
        }
    }

    debug()
    debug("Input arguments processed:")
    debug("* hints -> ", hints)
    debug("* vars -> ", vars)
    debug("* userArgs.runtime -> ", userArgs.runtime)
    debug("* userArgs.main -> ", userArgs.main)
    debug("* userArgs.ambiguous -> ", userArgs.ambiguous)

    return userArgs
}

private fun applyModeHints(
    modes: Array<String>,
    hints: MutableSet<String>,
    vars: Vars
) {
    for (mode in vars.calculate(modes, hints)) {
        if (mode.startsWith("!")) {
            // Negated mode expression: remove the mode hint.
            hints -= mode.substring(1)
        } else hints += mode
    }
    debug()
    debug("Modes applied:")
    debug("* hints -> ", hints)
}

private fun configureRuntimes(
    config: JaunchConfig,
    configDir: File,
    hints: MutableSet<String>,
    vars: Vars
): List<RuntimeConfig> {
    // Build the list of enabled runtimes.
    val runtimes = mutableListOf<RuntimeConfig>()
    if (config.jvmEnabled == true) runtimes += JvmRuntimeConfig(config.jvmRecognizedArgs)
    if (config.pythonEnabled == true) runtimes += PythonRuntimeConfig(config.pythonRecognizedArgs)

    // Discover the runtime installations.
    for (r in runtimes) {
        debugBanner("CONFIGURING RUNTIME: ${r.directive}")
        r.configure(configDir, config, hints, vars)
    }

    return runtimes
}

/** Discern directives to perform. */
private fun calculateDirectives(
    config: JaunchConfig,
    hints: MutableSet<String>,
    vars: Vars
): Pair<List<String>, List<String>> {
    debugBanner("CALCULATING DIRECTIVES")

    val directives = vars.calculate(config.directives, hints).flatMap { it.split(",") }.toSet()
    val (launchDirectives, configDirectives) = directives.partition { it == it.uppercase() }

    debug()
    debug("Directives parsed:")
    debug("* directives -> ", directives)
    debug("* launchDirectives -> ", launchDirectives)
    debug("* configDirectives -> ", configDirectives)

    return Pair(launchDirectives, configDirectives)
}

/** Ensure user arguments meet expectations. */
fun validateUserArgs(
    config: JaunchConfig,
    runtimes: List<RuntimeConfig>,
    userArgs: ProgramArgs
) {
    debug()
    debug("Validating user arguments...")

    // Verify that some runtime recognizes each argument given as a runtime arg,
    // unless allow-unrecognized-args is set to true.
    val strict = config.allowUnrecognizedArgs != true
    for (arg in userArgs.runtime) {
        if (strict && unknownArg(runtimes, arg)) fail("Unrecognized runtime argument: $arg")
    }
}

/**
 * Calculate program arguments *in context* -- i.e. with respect to each runtime.
 *
 * For example, the `-b` argument holds meaning to `python`, enabling warnings relating
 * to byte arrays and strings, whereas `-b` it is not a valid argument to `java`.
 * As such, an ambiguous `-b` will be treated as a runtime argument for the Python runtime,
 * and therefore *discarded* for the JVM runtime, since Python has "claimed" it.
 *
 * If no runtime recognizes an ambiguous argument, it will be treated as a main argument to all runtimes.
 *
 * @return A map from each runtime prefix to its contextualized arguments (bundle of runtime and main args).
 */
private fun contextualizeArgs(
    runtimes: List<RuntimeConfig>,
    userArgs: ProgramArgs,
    vars: Vars
): Map<String, ProgramArgs> {
    debug("Contextualizing user arguments...")
    val argsInContext = runtimes.associate { it.prefix to contextualizeArgsForRuntime(runtimes, it, userArgs) }

    // Inject runtime configuration values into the variables.
    vars += argsInContext.entries.associate { (k, v) -> "$k.runtimeArgs" to v.runtime }
    vars += argsInContext.entries.associate { (k, v) -> "$k.mainArgs" to v.main }
    runtimes.forEach { it.injectInto(vars) } // Runtime-specific keys.
    return argsInContext
}

/**
 * Calculate program arguments in context for a *particular runtime*.
 * Helper method of [contextualizeArgs].
 */
private fun contextualizeArgsForRuntime(
    runtimes: List<RuntimeConfig>,
    runtime: RuntimeConfig,
    userArgs: ProgramArgs
): ProgramArgs {
    val resolved = ProgramArgs()

    // Add the already-resolved arguments for this specific runtime.
    resolved.runtime += runtime.runtimeArgs
    resolved.main += runtime.mainArgs

    // Add user-specified arguments intended as runtime args.
    //
    // For each such argument, there are three scenarios:
    // 1) This runtime recognizes the argument, so we add it to this runtime's list of runtime args.
    // 2) This runtime does not recognize it, but some other runtime(s) do, in which case we skip it.
    // 3) No runtime recognizes the argument, so we add it to this (and all) runtime's list of runtime args.
    //
    // Note that if scenario (3) happens here, it must be because the allow-unrecognized-args
    // flag was set to true (otherwise the validateUserArgs check would have failed), so it
    // makes sense to throw up our hands and pass this weird argument to all enabled runtimes.
    var i = 0
    while (i < userArgs.runtime.size) {
        val arg = userArgs.runtime[i++]
        val r = runtime.recognizes(arg)
        if (r > 0 || unknownArg(runtimes, arg)) {
            // Case (1) or (3).
            i = appendRuntimeArg(i - 1, r, userArgs.runtime, resolved)
        }
        // else case (2): another runtime will snarf up this arg, so this one should ignore it.
    }

    // Add user-specified arguments intended as main args. Nothing tricky here.
    resolved.main += userArgs.main

    // Finally: we need to sort through the ambiguous user arguments.
    // If the user used the minus-minus (--) separator, this list will be empty.
    i = 0
    while (i < userArgs.ambiguous.size) {
        val arg = userArgs.ambiguous[i++]
        val r = runtime.recognizes(arg)
        if (r > 0) {
            // This runtime recognizes the argument.
            i = appendRuntimeArg(i - 1, r, userArgs.ambiguous, resolved)
        }
        else if (unknownArg(runtimes, arg)) {
            // No runtime recognizes it; treat it as a main argument.
            resolved.main += arg
        }
        // else another runtime will snarf up this arg, so this one should ignore it.
    }

    debug("* ${runtime.prefix}:runtime -> ${resolved.runtime}")
    debug("* ${runtime.prefix}:main -> ${resolved.main}")

    return resolved
}

/**
 * Append the argument at the given index, along with any parameter arguments.
 *
 * @return The advanced index beyond the appended arguments.
 */
private fun appendRuntimeArg(
    index: Int,
    r: Int,
    args: List<String>,
    resolved: ProgramArgs
): Int {
    var endIndex = index + r
    if (endIndex > args.size) {
        // This parameterized argument is missing needed parameters.
        warn("Argument ${args[index]} has too few parameters.")
        endIndex = args.size
    }
    resolved.runtime += args.slice(index..<endIndex)
    return endIndex
}

/**
 * @return True iff the given argument is unrecognized by *all* runtimes on the list.
 */
private fun unknownArg(
    runtimes: List<RuntimeConfig>,
    arg: String
): Boolean {
    return runtimes.firstOrNull { it.recognizes(arg) > 0 } == null
}

/**
 * Executes any global (runtime-independent) directives in the given
 * configDirectives list.
 *
 * Returns a new immutable list containing any directives that could not be
 * executed globally.
 */
private fun executeGlobalDirectives(
    globalDirectiveFunctions: DirectivesMap,
    configDirectives: List<String>,
    userArgs: ProgramArgs
): List<String> {
    debugBanner("EXECUTING GLOBAL DIRECTIVES")

    // Execute the runtime-independent directives.
    debug()
    debug("Executing runtime-independent directives...")
    val runtimeDirectives = mutableListOf<String>()
    for (directive in configDirectives) {
        // Execute the directive globally if possible.
        val doDirective = globalDirectiveFunctions[directive]
        if (doDirective != null) {
            doDirective(userArgs)
            continue
        }

        // Any non-global directives will need to be handled by the runtimes
        runtimeDirectives.add(directive)
    }
    return runtimeDirectives.toList()
}

private fun executeDirectives(
    configDirectives: List<String>,
    launchDirectives: List<String>,
    runtimes: List<RuntimeConfig>,
    argsInContext: Map<String, ProgramArgs>
) {
    debugBanner("EXECUTING DIRECTIVES")

    // Execute the configurator-side directives.
    debug()
    debug("Executing configurator-side directives...")
    for (directive in configDirectives) {
        var success = false
        val (activatedRuntimes, dormantRuntimes) =
            runtimes.partition { it.directive in launchDirectives }

        // First, we try the activated runtimes.
        for (runtime in activatedRuntimes) {
            val myArgs = argsInContext[runtime.prefix]
                ?: fail("No contextual args for {runtime.prefix} runtime?!")
            success = success || runtime.tryDirective(directive, myArgs)
        }

        if (!success) {
            // None of the activated runtimes wanted to handle it,
            // so now we give the remaining ones a chance.
            for (runtime in dormantRuntimes) {
                val myArgs = argsInContext[runtime.prefix]
                    ?: fail("No contextual args for {runtime.prefix} runtime?!")
                success = success || runtime.tryDirective(directive, myArgs)
            }
        }

        if (!success) fail("Invalid directive: $directive")
    }

    // Emit launch-side directives.
    debug()
    debug("Emitting launch directives to stdout...")

    // Should we actually proceed with the launch?
    val abort = dryRunMode || launchDirectives.isEmpty() || "ABORT" in launchDirectives
    val go = !abort

    for (directive in launchDirectives) {
        debug("Processing directive: $directive")
        val runtime = runtimes.firstOrNull { it.directive == directive }
        val lines = runtime?.launch(argsInContext[runtime.prefix]!!) ?: emptyList()
        if (go) {
            println(directive)
            println(lines.size)
            lines.forEach { println(it) }
        }
    }
    if (abort) {
      println("ABORT")
      println("0")
    }
}

// -- Helper functions --

private infix fun String.bisect(delimiter: Char): Pair<String, String?> {
    val index = indexOf(delimiter)
    return if (index < 0) Pair(this, null) else Pair(substring(0, index), substring(index + 1))
}

// -- Directive handlers --

private fun help(exeFile: File?, programName: String, supportedOptions: JaunchOptions) {
    val exeName = exeFile?.name ?: "jaunch"
    printlnErr("Usage: $exeName [<Runtime options>.. --] [<main arguments>..]")
    printlnErr()
    printlnErr("$programName launcher (Jaunch v$JAUNCH_VERSION / $JAUNCH_BUILD / $BUILD_TARGET)")
    printlnErr("Runtime options are passed to the runtime platform (JVM or Python),")
    printlnErr("main arguments to the launched program ($programName).")
    printlnErr()
    printlnErr("In addition, the following options are supported:")
    val optionsUnique = linkedSetOf(*supportedOptions.values.toTypedArray())
    optionsUnique.forEach { printlnErr(it.help()) }
}

private fun printDir(dir: File, dirName: String) {
    printlnErr("--- $dirName Directory ---")
    printlnErr(dir.path)
    printlnErr()
}

/** Recursively move over all files in the update subdir. */
private fun applyUpdate(appDir: File, updateSubDir: File) {
    if (!updateSubDir.exists) return

    fun emit(s: String) { dryRun(s); debug(s) }

    for (file in updateSubDir.ls()) {
        val dest = appDir / file.path.substring((appDir / "update").path.length)
        if (file.isDirectory) {
            emit("+ mkdir '$dest'")
            if (!dryRunMode) dest.mkdir() || fail("Couldn't create path $dest")
            applyUpdate(appDir, file)
        }
        else {
            if (file.length == 0L) {
                // Zero-length file is a special signal that the file should be deleted.
                emit("+ rm '$dest'")
                if (!dryRunMode) dest.rm() || fail("Couldn't remove $dest")
                emit("+ rm '$file'")
                if (!dryRunMode) file.rm() || fail("Couldn't remove $file")
            } else {
                emit("+ mv '$file' '$dest'")
                if (!dryRunMode) file.mv(dest) || fail("Couldn't replace $dest")
            }
        }
    }

    updateSubDir.rmdir()
}
