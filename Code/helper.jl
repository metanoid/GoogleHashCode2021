# useful helper functions
using Combinatorics
# using JuMP
# using Cbc
# using ConstraintSolver
using Base.Iterators
using TerminalLoggers
# global_logger(TerminalLogger(right_justify = 120))
using ProgressLogging
using DataStructures

# const CS = ConstraintSolver


# Define useful structs here
struct Street
    id::Int # strictly internal
    start::Int
    finish::Int
    name::String
    L::Int
    cq::Queue{Tuple{Int, Int}}
end

# Street(args...) = Street2(args...)

struct Intersection
    id::Int
    instreets::Vector{Int}
    outstreets::Vector{Int}    
end

# Intersection(args...) = Intersection2(args...)


struct Car
    id::Int 
    num_streets::Int
    streets::Vector{Int}
end


struct Problem
    cars::Vector{Car}
    intersections::Vector{Intersection}
    streets::Vector{Street}
    D::Int
    I::Int
    S::Int
    V::Int
    F::Int
end


# struct Schedule
#     id # id of intersection
#     numstreets # number of streets handled
#     streetorders # array of streets giving order of visit
#     streetdurations # array of integers giving timing of green
# end





# define useful struct modification tools here



# file management utilities

function details_o(outputfile)
    parts = split(outputfile,"_")
    problem_id = string(parts[1])
    score = parse(Int,string(parts[2]))
    reg = r"(\d+)\.out"
    code = match(reg, string(parts[3])).captures[1]
    return problem_id, score, code
end

function details_p(partfile)
    parts = split(partfile,"_")
    problem_id = string(parts[1])
    score = parse(Int,string(parts[2]))
    reg = r"(\d+)\.out"
    code = string(parts[3])
    part_id = parse(Int, string(parts[4]))
    N = match(reg, string(parts[5])).captures[1]
    return problem_id, score, code, part_id, N
end

function parse_input(inputfile)
    prob = open("Inputs/$(inputfile)") do f
        D,I,S,V,F = parse.(Int, split(readline(f)," "))
        streetdict = Dict{String,Int}()
        streets = Vector{Street}(undef, S)        
        intersections = Vector{Intersection}(undef, I)
        instreets = Vector{Vector{Int}}(undef, I)
        outstreets = Vector{Vector{Int}}(undef, I)  
        for i in 1:I
            instreets[i] = Vector{Int}()
            outstreets[i] = Vector{Int}()
        end    
        cars = Vector{Car}(undef,V)  
        for s in 1:S
            d = split(readline(f), " ")
            b = parse(Int, d[1])+1
            e = parse(Int, d[2])+1
            n = string(d[3])
            l = parse(Int, d[4])
            q = Queue{Tuple{Int,Int}}()
            street = Street(s,b,e,n,l,q)
            streetdict[n] = s
            streets[s] = street
            push!(instreets[e], s)
            push!(outstreets[b], s)
        end
        for i in 1:I 
            intersection = Intersection(i,instreets[i], outstreets[i])
            intersections[i] = intersection    
        end        
        for v in 1:V
            d = split(readline(f), " ")
            p = parse(Int, d[1])
            streetnames = d[2:p]
            path = [streetdict[s] for s in streetnames]
            c = Car(v, p, path)
            cars[v] = c
        end

        prob = Problem(cars, intersections,streets,D,I,S,V,F)
        
        return prob
    end
    return prob
end







function generate(pizzas, T2_part, T3_part, T4_part)
    # n = length(pizzas)
    p = collect(powerset(pizzas, 2, 4))
    scores = Dict(pz => score_val(pz) for pz in p)
    m = JuMP.Model(Cbc.Optimizer)
    set_silent(m)
    @variable(m, assign[p], Bin) # one variable for if each possible value is used
    # OL = zeros(length(pizzas),length(p))
    for (i,pz) in enumerate(pizzas)
        overlap = filter(x -> pz ∈ x, p)
        ids = findall(x -> pz ∈ x, p)
        # OL[i, ids] .= 1
        @constraint(m, sum(assign[f] for f in overlap) <= 1)
    end
    @constraint(m, sum(assign[f] for f in p if length(f) == 2) <= T2_part);
    @constraint(m, sum(assign[f] for f in p if length(f) == 3) <= T3_part);
    @constraint(m, sum(assign[f] for f in p if length(f) == 4) <= T4_part);
    @objective(m, Max, sum(assign[f]*scores[f] for f in p));
    optimize!(m)

    # get teams
    vals = findall(==(1.0), JuMP.value.(assign).data)
    combos = p[vals]
    myteams = Team[]
    for combo in combos
        ing = union([c.ingredients for c in combo]...)
        t = Team(length(combo), Set(combo), ing, length(ing), length(ing)^2 )
        push!(myteams, t)
    end
    used_pizzas = vcat(combos...)
    return (myteams, used_pizzas)
end




function ruin_recreate(teams, freepizzas, T2_rem, T3_rem, T4_rem)
    score_pre = sum(x.score for x in teams)
    eaten = union([team.pizzas for team in teams]...)
    fullpizzas = union(freepizzas, eaten)
    T2_pre = count(==(2), x.members for x in teams)
    T3_pre = count(==(3), x.members for x in teams)
    T4_pre = count(==(4), x.members for x in teams)
    newteams, takenpizzas = generate([fullpizzas...], T2_pre + T2_rem, T3_pre + T3_rem, T4_pre + T4_rem)
    score_post = sum(x.score for x in newteams)
    if score_post > score_pre
        println("Improved Score by $(score_post - score_pre)!")
        leftovers = setdiff(fullpizzas, takenpizzas)
        T2_post = T2_rem + T2_pre - count(==(2), x.members for x in newteams)
        T3_post = T3_rem + T3_pre - count(==(3), x.members for x in newteams)
        T4_post = T4_rem + T4_pre - count(==(4), x.members for x in newteams)
        return true, newteams, takenpizzas, leftovers, T2_post, T3_post, T4_post
    else
        return false, teams, eaten, freepizzas, T2_rem, T3_rem, T4_rem
    end
end

function remove_insert(teampart, freepizzas, T2_part, T3_part, T4_part, n)
    teamset = Set(teampart)
    newset = Set{Team}()
    @progress for teams in collect(partition(teamset, n))
        success, newteams, eaten, free, T2_new, T3_new, T4_new = ruin_recreate(teams, freepizzas, T2_part, T3_part, T4_part)
        if success
            # remove old teams and replace with new
            push!(newset, newteams...)
            freepizzas = free
            T2_part = T2_new
            T3_part = T3_new
            T4_part = T4_new
        else
            # keep the previous assignments
            push!(newset, teams...)
        end
    end
    teampart_new = [x for x in newset]
    return teampart_new, freepizzas, T2_part, T3_part, T4_part
end


function write_soln(newteams, name)
    # total deliveries to distnct teams
    D = length(newteams)
    open(name,"w") do f
        write(f, "$(D)\n")
        for team in newteams
            write(f, "$(team.members) $(join([p.ID for p in team.pizzas], " "))\n")
        end
    end
end

function warm_start(filename, pizzadict)
    teams = open(filename, "r") do f
        num_teams = parse(Int, readline(f))
        teams = Array{Team, 1}(undef, num_teams)
        local i = 1
        while !eof(f)
            line = split(readline(f), " ")
            members = parse(Int, line[1])
            ids = parse.(Int, line[2:end])
            pz = Set([pizzadict[i] for i in ids])
            ing = union([p.ingredients for p in pz]...)
            team = Team(members, pz,ing,length(ing), length(ing)^2)
            teams[i] = team
            i+= 1
        end
        return teams
    end
    return teams
end
