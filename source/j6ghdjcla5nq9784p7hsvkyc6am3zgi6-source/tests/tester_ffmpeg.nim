import os, osproc, strutils

if not fileExists("ForBiggerFun.mp4"):
    discard execCmdEx("curl https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4 -O ForBiggerFun.mp4")

var (output, errC) = execCmdEx("nim r ./src/kombinator.nim -c tests/ffmpeg_conf.toml -y")
echo output
if errC != QuitSuccess:
    quit(QuitFailure)

var 
    resultExists = false
for file in walkDirRec("."):
    if file.contains("kombi_result.csv"):
        resultExists = true
        var (dir, _, _) = splitFile(file)
        
        # Clean
        removeDir(dir)
        assert resultExists
        break

