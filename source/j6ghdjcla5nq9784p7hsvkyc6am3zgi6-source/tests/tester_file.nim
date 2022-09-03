import os, osproc, strutils

const CSVResult = """
valid;test_0;test_1;cfg;duration_ms;output_dir
OK;12;85;0-file_conf.cfg;0;run_0
OK;74;96;1-file_conf.cfg;0;run_1
"""

var (output, errC) = execCmdEx("nim r ./src/kombinator.nim -c tests/file_conf.toml -y")
echo output
if errC != QuitSuccess:
    quit(QuitFailure)

for file in walkDirRec("."):
    if file.contains("kombi_result.csv"):
        let csvFile = open(file, fmRead)
        assert csvFile.readAll() == CSVResult

        # Clean
        var (dir, _, _) = splitFile(file)
        removeDir(dir)
        break
