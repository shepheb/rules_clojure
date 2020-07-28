def clojure_aot_impl(ctx):
    toolchain = ctx.toolchains["@rules_clojure//rules:toolchain_type"]

    output = ctx.actions.declare_directory("%s.aot" % ctx.label.name)

    transitive_runtime_deps = depset(transitive = [dep[JavaInfo].transitive_runtime_deps for dep in ctx.attr.deps])

    cmd = """
        set -e;
        rm -rf {output}
        mkdir -p {output}
        {java} -cp {classpath} -Dclojure.compile.path={output} -Dclojure.compile.jar={jar} -Dclojure.compile.aot={aot} clojure.main {script}
    """.format(
        java = toolchain.java,
        classpath = ":".join([f.path for f in toolchain.files.runtime + transitive_runtime_deps.to_list() + [output]]),
        output = output.path,
        jar = ctx.outputs.jar.path,
        aot = ",".join(ctx.attr.ns),
        script = [f for f in toolchain.files.scripts if f.basename == "aot.clj"][0].path,
    )

    ctx.actions.run_shell(
        command = cmd,
        outputs = [output, ctx.outputs.jar],
        inputs = transitive_runtime_deps.to_list() + toolchain.files.runtime + toolchain.files.scripts + toolchain.files.jdk,
        mnemonic = "ClojureAOT",
        progress_message = "Building clojure aot for %s" % ctx.label,
    )

    return JavaInfo(
        output_jar = ctx.outputs.jar,
        compile_jar = ctx.outputs.jar,
        source_jar = ctx.outputs.jar,
        deps = [dep[JavaInfo] for dep in toolchain.runtime + ctx.attr.deps],
    )
