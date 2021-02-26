using DataStructures

struct Event
    time
    car
    intersection
    carqueue
end

function simulate(intersections, streets, cars, carqueues, schedules, D, F)
    # given a schedule, get the total score
    eventQ = PriorityQueue{Event, Int}()
    # add the cars crossing the next iteration according to their order
    local current_time = 0
    for car in cars
        # get next street
        if length(car.streets) == 0
            continue
        end
        nextstreet = popfirst!(car.streets)
        # where does that street end?
        finish = intersections[nextstreet.finish] # intersection
        # how long until we finish the road and join the queue?
        L = nextstreet.L
        # how many cars until we're at the front of the queue ?
        cq = carqueues[(finish.id, nextstreet.name)]
        # depth = length(cq.carqueue)
        # how long until all cars in front of me have passed
        if length(cq.carqueue) > 0
            jam_time, jam_car = last(cq.carqueue)
        else
            jam_time = 0
        end
        # when will we be at the front of the queue and ready to go
        if current_time + L > jam_time
            front_time = current_time + L
        else
            front_time = jam_time
        end
        # then how long do we wait for green?
        s = schedules[finish.id]
        pos = findfirst(==(nextstreet.name), s.streetorders)
        total_cycle_time = sum(s.streetdurations)
        if pos > 1
            time_before = sum(s.streetdurations[1:(pos-1)])
        else
            time_before = 0
        end
        if pos < length(s.streetorders)
            time_after = sum(s.streetdurations[(pos + 1):end])
        else
            time_after = 0
        end
        mytime = s.streetdurations[pos]
        seconds_since_cycle_start = mod(front_time, total_cycle_time)
        if seconds_since_cycle_start < time_before
            # then wait for green in this current cycle
            waiting_time = time_before - seconds_since_cycle_start
        elseif seconds_since_cycle_start < time_before + mytime
            # then we can go now!
            waiting_time = 0
        else
            # we missed this cycle's window, go next cycle
            waiting_time = total_cycle_time - seconds_since_cycle_start + time_before
        end
        go_time = front_time + waiting_time
        next_event_time = current_time + go_time + 1
        event = Event(next_event_time, car, finish, cq)
        #push car onto carqueue for next car to see
        enqueue!(cq.carqueue, (next_event_time, car))
        enqueue!(eventQ, event, next_event_time)
    end

    println("Length of eventQ: $(length(eventQ))")

    # now all cars have "entered" and belong to a CarQueue somewhere
    # now, process the event Queue until time D has elapsed

    local total_score = 0

    while (current_time <= D) & (length(eventQ) > 0)
        println("Start of loop: At time $(current_time) the event queue has $(length(eventQ)) events left")
        # get next event
        event = dequeue!(eventQ)
        current_time = event.time
        car = event.car
        # intersection = event.intersection
        # cq = event.carqueue
        # get next street
        if length( car.streets) == 0
            # println("Car made it in under the wire!")
            # woohoo car has no more work to do, and can add to score!
            my_score = F + (D - current_time)
            total_score += my_score
            println("Continuing")
            continue
        end

        nextstreet = popfirst!(car.streets)
        # where does that street end?
        finish = intersections[nextstreet.finish] # intersection
        # how long until we finish the road and join the queue?
        L = nextstreet.L
        # how many cars until we're at the front of the queue ?
        cq = carqueues[finish.id, nextstreet.name]
        # depth = length(cq.carqueue)
        # how long until all cars in front of me have passed
        if length(cq.carqueue) > 0
            jam_time, jam_car = last(cq.carqueue)
        else
            jam_time = 0
        end
        # when will we be at the front of the queue and ready to go
        if (current_time + L) > jam_time
            front_time = current_time + L
        else
            front_time = jam_time
        end
        # then how long do we wait for green?
        s = schedules[finish.id]
        pos = findfirst(==(nextstreet.name),s.streetorders )
        total_cycle_time = sum(s.streetdurations)
        if pos > 1
            time_before = sum(s.streetdurations[1:(pos-1)])
        else
            time_before = 0
        end
        if pos < length(s.streetorders)
            time_after = sum(s.streetdurations[(pos + 1):end])
        else
            time_after = 0
        end
        mytime = s.streetdurations[pos]
        seconds_since_cycle_start = mod(front_time, total_cycle_time)
        if seconds_since_cycle_start < time_before
            # then wait for green in this current cycle
            waiting_time = time_before - seconds_since_cycle_start
        elseif seconds_since_cycle_start < (time_before + mytime)
            # then we can go now!
            waiting_time = 0
        else
            # we missed this cycle's window, go next cycle
            waiting_time = total_cycle_time - seconds_since_cycle_start + time_before
        end
        go_time = front_time + waiting_time
        next_event_time = current_time + go_time + 1
        event = Event(next_event_time, car, finish, cq)
        #push car onto carqueue for next car to see
        enqueue!(cq.carqueue, (next_event_time, car))
        enqueue!(eventQ, event, next_event_time)
        println("At time $(current_time) the event queue has $(length(eventQ)) events left")
    end
    return total_score, current_time
end
