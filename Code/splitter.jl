function split_output(inputfile, outputfile, N)
    # create N valid partial solutions from the outputfile, given the inputfile

    input_a, input_b, input_c = parse_input(inputfile)

    output_a, output_b, output_c = parse_output(outputfile)

    problem_id, full_score, solution_code = details_o(outputfile)

    soln_size = length(output_a)
    part_size = soln_size ÷ (N - 1)
    remainder = soln_size - (part_size * (N-1))
    if remainder == 0
        act_N = N-1
    else
        act_N = N
    end

    for (i, part) in partitions(output_b, part_size)
        part_score = get_score(part, input_a)
        file_name = "Partial/$(problem_id)_$(part_score)_$(solution_code)_$(i)_$(act_N).part"
        write_output(part, filename)
    end

    println("Split solution $(outputfile) into $(act_N) parts")

end
