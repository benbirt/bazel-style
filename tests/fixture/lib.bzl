"""A macro for the fixture."""

def greeting(name, message):
    native.genrule(name = name, outs = [name + ".txt"], cmd = "echo '%s' > $@" % message)
