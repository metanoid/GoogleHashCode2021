using ZipFile

function zip_code_folder(name)
    w = ZipFile.Writer("Submissions/$(name).zip")
    files = readdir("Code")
    for f in files
        text = read("Code/$f", String)
        wf = ZipFile.addfile(w,f)
        write(wf, text)
    end
    close(w)
end

function submit_soln(name)
    soln_file = "$(name).out"
    Base.Filesystem.cp("Outputs/$(soln_file)", "Submissions/$(soln_file)", force = true)
    zip_code_folder(name)
    println("Submission $(name) ready to upload!")
end
