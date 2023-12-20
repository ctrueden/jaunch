import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
@Suppress("ArrayInDataClass")
data class JaunchConfig (

    /** Runtime classpath elements to pass to Java. */
    val classpath: Array<String> = emptyArray(),

    /**
     * Maximum amount of memory for the Java heap to consume. Examples:
     * <ul>
     * <li>For 1567 MB: "1567m"</li>
     * <li>For 48 GB: "48g"</li>
     * <li>For 75% of available RAM: "75%"</li>
     * <li>For 3 GB less than available RAM: "-3g"</li>
     * </ul>
     * These will be translated into an appropriate "-Xmx..." argument.
     */
    @SerialName("max-heap")
    val maxHeap: String? = null,

    /** TODO */
    @SerialName("supported-options")
    val supportedOptions: Array<String> = emptyArray(),

    /** TODO */
    @SerialName("recognized-jvm-args")
    val recognizedJvmArgs: Array<String> = emptyArray(),

    /** TODO */
    @SerialName("allow-unrecognized-jvm-args")
    val allowUnrecognizedJvmArgs: Boolean? = null,

    /** Minimum acceptable Java version to match. */
    @SerialName("version-min")
    val versionMin: Long? = null,

    /** Maximum acceptable Java version to match. */
    @SerialName("version-max")
    val versionMax: Long? = null,

    /** Paths to check on all systems. */
    @SerialName("root-paths")
    val rootPaths: Array<String> = emptyArray(),

    /**
     * TODO
     *
     * Any of the following can be bare, or nested in another JDK root folder.
     * No assumption is made about the naming scheme of such a JDK root folder,
     * because not all distros are predictably named. Examples:
     * <pre>
     * macosx  JBRSDK 8u252          : jdk/Contents/Home/jre/lib/jli/libjli.dylib
     * linux64 JBRSDK 11.0.6-b520.66 : jbrsdk/lib/server/libjvm.so
     * linux64 JBRSDK 11.0.8         : jbrsdk_11.0.8_x64/jbr/lib/server/libjvm.so
     * </pre>
     * The nested jre/ is only present for OpenJDK 8, nothing after.
     * But one wrinkle: on macOS, some distros *also* have a libjli.dylib
     * in Contents/MacOS in addition to its other location. And the two
     * are *not* binary identical. Testing is needed to determine if
     * there's any difference in behavior based on which one gets linked.
     */
    @SerialName("libjvm-suffixes")
    val libjvmSuffixes: Array<String> = emptyArray(),

    /** TODO */
    val modes: Array<String> = emptyArray(),

    /** TODO */
    val directives: Array<String> = emptyArray(),

    /** Additional flags to pass to the JVM at launch. */
    @SerialName("jvm-args")
    val jvmArgs: Array<String> = emptyArray(),

    /** TODO */
    @SerialName("main-class")
    val mainClass: String? = null,

    /** TODO */
    @SerialName("main-class-candidates")
    val mainClassCandidates: Array<String> = emptyArray(),

    /** TODO */
    @SerialName("main-args")
    val mainArgs: Array<String> = emptyArray(),
) {
    /** TODO */
    val mainClasses: Array<String>
        get() {
            return if (mainClass == null) mainClassCandidates else arrayOf(mainClass) + mainClassCandidates
        }

    /** Return true iff the given argument is on the list of {@link #recognizedJvmArgs}. */
    fun recognizes(arg: String): Boolean {
        for (okArg in recognizedJvmArgs) {
            if (okArg.endsWith("*")) {
                val prefix = okArg.substring(0, okArg.length - 1)
                if (arg.startsWith(prefix)) return true else continue
            }
            var trimmed = arg
            for (symbol in listOf(":", "=")) {
                val index = trimmed.indexOf(symbol)
                if (index >= 0) trimmed = trimmed.substring(0, index)
            }
            if (trimmed == okArg) return true
        }
        return false
    }

    operator fun plus(config: JaunchConfig): JaunchConfig {
        return JaunchConfig(
            classpath = config.classpath + classpath,
            maxHeap = config.maxHeap ?: maxHeap,
            supportedOptions = config.supportedOptions + supportedOptions,
            recognizedJvmArgs = config.recognizedJvmArgs + recognizedJvmArgs,
            allowUnrecognizedJvmArgs = config.allowUnrecognizedJvmArgs ?: allowUnrecognizedJvmArgs,
            versionMin = config.versionMin ?: versionMin,
            versionMax = config.versionMax ?: versionMax,
            rootPaths = config.rootPaths + rootPaths,
            libjvmSuffixes = config.libjvmSuffixes + libjvmSuffixes,
            modes = config.modes + modes,
            directives = config.directives + directives,
            jvmArgs = config.jvmArgs + jvmArgs,
            mainClass = config.mainClass ?: mainClass,
            mainClassCandidates = config.mainClassCandidates + mainClassCandidates,
            mainArgs = config.mainArgs + mainArgs,
        )
    }
}