"""A formatter that is always given its settings file from bazel_style."""

def _rlocation_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return ctx.workspace_name + "/" + file.short_path

def _configured_tool_impl(ctx):
    tool = ctx.attr.tool[DefaultInfo].files_to_run
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = launcher,
        substitutions = {
            "__ARGS__": " ".join(["'{}'".format(arg) for arg in ctx.attr.args_before_config]),
            "__CHANGED_FLAG__": ctx.attr.changed_exit_flag,
            "__CONFIG__": _rlocation_path(ctx, ctx.file.config),
            "__TOOL__": _rlocation_path(ctx, tool.executable),
        },
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = [ctx.file.config])
    runfiles = runfiles.merge(ctx.attr.tool[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles)
    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

configured_tool = rule(
    implementation = _configured_tool_impl,
    doc = "Runs `tool` with `args_before_config`, then the path of `config`, then the caller's arguments.",
    attrs = {
        "args_before_config": attr.string_list(
            doc = "Arguments before the path of `config`; the last is normally the tool's config flag.",
            mandatory = True,
        ),
        "changed_exit_flag": attr.string(
            doc = "A flag with which the tool exits 1 when it has changed files; that exit then counts as success.",
        ),
        "config": attr.label(allow_single_file = True, mandatory = True),
        "tool": attr.label(cfg = "target", executable = True, mandatory = True),
        "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
        "_template": attr.label(allow_single_file = True, default = ":configured_tool.sh.tpl"),
    },
    executable = True,
)
