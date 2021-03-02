# using ...

include("helper.jl")
include("jump_start.jl")
include("smartstart.jl")
include("splitter.jl")
include("part_improver.jl")
include("stitcher.jl")
include("zipper.jl")

problems = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
]
inputfiles = [
     "a.txt",
     "b.txt",
     "c.txt",
     "d.txt",
     "e.txt",
     "f.txt"
]


for dur in 3:8
    for i in 1:6

        problem = problems[i]
        inputfile = inputfiles[i]
        prob = parse_input(inputfile);
        schedules = dumbstart(intersections, streets, cars, carqueues, dur)
        score, endtime = simulate(intersections, streets, cars, carqueues, schedules, D, F)

        write_output(schedules, "$(problem)_dumb_$(dur)")
        submit_soln("$(problem)_dumb_$(dur)")
    end
end
