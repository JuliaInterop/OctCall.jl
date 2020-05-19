using VersionParsing, Libdl

prefsfile = joinpath(first(DEPOT_PATH), "prefs", "OctCall")
mkpath(dirname(prefsfile))

MKOCTFILE = get(ENV, "MKOCTFILE", isfile(prefsfile) ? readchomp(prefsfile) : Sys.which("mkoctfile"))

MKOCTFILE === nothing && error("mkoctfile not found; make sure Octave is installed and in your PATH, or set the MKOCTFILE environment variable")
Sys.isexecutable(MKOCTFILE) || error("$MKOCTFILE is not executable")

OCTAVE_VERSION = vparse(readchomp(`$MKOCTFILE --version`))
OCTAVE_VERSION ≥ v"5" || error("octave version 5 or later is required; $OCTAVE_VERSION is not supported")

compile = Base.shell_split(readchomp(`mkoctfile --link-stand-alone -n foo.cxx`))

include_dirs = map(s -> s[3:end], filter(s -> startswith(s, "-I"), compile))
lib_dirs = map(s -> s[3:end], filter(s -> startswith(s, "-L"), compile))
libs = map(s -> s[3:end], filter(s -> startswith(s, "-l"), compile))

liboctave_names = sort!([s for s in libs if occursin("octave", s)], by=length)
isempty(liboctave_names) && error("liboctave not found in $libs")
liboctave_name = endswith(liboctave_names[1], dlext) ? liboctave_names[1] : liboctave_names[1] * '.' * dlext
if isabspath(liboctave_name)
    liboctave = liboctave_name
else
    if !startswith(liboctave_name, "lib")
        liboctave_name = "lib" * liboctave_name
    end
    liboctave_path = findfirst(ispath, joinpath.(lib_dirs, liboctave_name))
    liboctave_path === nothing && error("$liboctave_name not found in $lib_dirs")
    liboctave = abspath(lib_dirs[liboctave_path], liboctave_name)
end

oct_h_path = findfirst(ispath, joinpath.(include_dirs, "octave", "oct.h"))
oct_h_path === nothing && error("octave/oct.h not found in $include_dirs")
oct_h = abspath(joinpath(include_dirs[oct_h_path], "octave", "oct.h"))

function write_if_changed(filename, contents)
    if !isfile(filename) || read(filename, String) != contents
        write(filename, contents)
    end
end

deps = """
const MKOCTFILE = $(repr(MKOCTFILE))
const OCTAVE_VERSION = $(repr(OCTAVE_VERSION))
const liboctave = $(repr(liboctave))
const oct_h = $(repr(oct_h))
"""
write_if_changed("deps.jl", deps)
write_if_changed(prefsfile, MKOCTFILE)
