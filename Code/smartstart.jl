using Random

function smartstart(intersections, streets, cars, carqueues, durationmean = 3)
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
