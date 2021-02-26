# using Cbc
# using JuMP
# using ConstraintSolver

include("helper.jl")

using Base.Threads
using Dates

problem_sets = ["a",
    "b",
    #"c",
    "d", "e"
    ]
input_files = [
    "Input/a_example",
    "Input/b_little_bit_of_everything.in",
    #"Input/c_many_ingredients.in",
    "Input/d_many_pizzas.in",
    "Input/e_many_teams.in"
]
best_known = [
    "Output/submission_a_example.txt",
    "Output/b_2021-02-24_13186_1.out",
    #"Output/submission_c_many_ingredients.in.txt",
    "Output/submission_d_many_pizzas.in.txt",
    "Output/submission_e_many_teams.in.txt"
]

for retries in 1:3
    for (i,problem) in enumerate(problem_sets)
        println("Currently working on problem $(problem)")
        inputfile = input_files[i]

        warm_start_file = best_known[i]

        ingredients, PD, PF, T2, T3, T4 = parse_input(inputfile);
        pizzas = [PF[i] for i in keys(PF)];

        if isnothing(warm_start_file)
            teamarray, usedpizzas, freepizzas = create(pizzas, 24, T2, T3, T4);
        else
            teamarray = warm_start(warm_start_file, PF);
            usedpizzas = union([t.pizzas for t in teamarray]...);
            freepizzas = setdiff(pizzas, usedpizzas);
        end


        T2_avail = T2 - count(==(2), x.members for x in teamarray)
        T3_avail = T3 - count(==(3), x.members for x in teamarray)
        T4_avail = T4 - count(==(4), x.members for x in teamarray)

        partlength = max(1,length(teamarray) ÷ (Threads.nthreads() - 1))

        T2_part = T2_avail ÷ (Threads.nthreads() - 1)
        T3_part = T3_avail ÷ (Threads.nthreads() - 1)
        T4_part = T4_avail ÷ (Threads.nthreads() - 1)

        # randomly pick some additional pizzas to try swapping out
        existing = partition(teamarray, partlength)
        num_rounds = length(existing)
        if length(freepizzas) >= num_rounds
            extralength = min(length(freepizzas) ÷ num_rounds, 24) # don't add all, just some
            extra = collect(partition(freepizzas, extralength))
        else
            extra = [Pizza[] for x in 1:num_rounds]
        end

        pieces = collect(zip(existing, extra))
        teamset = Set(teamarray)
        newteams = Set{Team}()

        local base_score = sum(x.score for x in teamarray)
        for (teampart, free) in pieces
            part_new, free_new, T2_part_new, T3_part_new, T4_part_new = remove_insert(teampart, free, T2_part, T3_part, T4_part, 12)
            push!(newteams, part_new...)
            # setdiff!(teamset, teampart)
            # union!(teamset, part_new)
            # new_score = sum(x.score for x in teamset)
            # if new_score > base_score
            #     println("found a new best solution for $(problem)!")
            #     outputfile = "Output/$(problem)_$(Dates.today())_$(new_score)_$(retries).out"
            #     best_known[i] = outputfile
            #     write_soln(teamset, outputfile)
            #     base_score = new_score
            # end
        end

        pizza_array = Int[]
        for t in newteams
            for p in t.pizzas
                push!(pizza_array, p.ID)
            end
        end
        sort!(pizza_array)


        score = sum(x.score for x in newteams)

        if score >= base_score
            println("found a new best solution for $(problem)!")
            outputfile = "Output/$(problem)_$(Dates.today())_$(score)_$(retries).out"
            best_known[i] = outputfile
            write_soln(newteams, outputfile)
        end
    end
end
