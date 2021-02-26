# Construct a dumb solution and write it to file



function dumbstart(intersections, streets, cars, carqueues, duration = 1)
    schedules = Dict{Int,Schedule}()
    for (i, intersection) in intersections
        e = length(intersection.instreets)
        names = [x.name for x in intersection.instreets]
        durs = collect(repeat([duration], length(names)))
        sched = Schedule(i,e,names, durs)
        schedules[i] = sched
    end
    return(schedules)
end

function write_output(schedules, name)
    A = length(schedules)
    open("Outputs/$(name).out", "w") do f
        write(f, "$(A)\n")
        for (k,s) in schedules
            write(f, "$(s.id)\n")
            write(f, "$(s.numstreets)\n")
            for i in 1:length(s.streetorders)
                write(f, "$(s.streetorders[i]) $(s.streetdurations[i])\n")
            end
        end
    end
end
