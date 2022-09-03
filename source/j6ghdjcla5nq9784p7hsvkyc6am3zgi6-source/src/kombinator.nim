import os, osproc, strutils, strformat, times, rdstdin
import cligen, parsetoml, suru, sequtils

template cd*(dir: string, body: untyped) =
    ## Sets the current dir to ``dir``, executes ``body`` and restores the
    ## previous working dir.
    let lastDir = getCurrentDir()
    setCurrentDir(dir)
    body
    setCurrentDir(lastDir)

proc generateKomb(variables: seq[(string, seq[string])], variableIndex: int, trackIndex: int, kombi : var seq[seq[(string, string)]]) =
    ## Generate params list of combination
    ## 'variables' list of variables
    ## 'variableIndex' index in variables
    ## 'trackIndex' index in tracks
    ## 'kombi' result of combinations
    if len(kombi) == 0:
        kombi.add(@[])
    var 
        value = variables[variableIndex]
        count = 0
        newTrack = kombi[trackIndex]
    for elem in value[1]:
        if count == 0:
            kombi[trackIndex].add((value[0], elem))
            if variableIndex < len(variables) - 1:
                generateKomb(variables, variableIndex + 1, trackIndex, kombi)
        else:
            kombi.add(newTrack)
            let newTrackIndex = len(kombi) - 1
            kombi[newTrackIndex].add((value[0], elem))
            if variableIndex < len(variables) - 1:
                generateKomb(variables, variableIndex + 1, newTrackIndex, kombi)
        inc count

proc convertTOMLValueToString(value: TomlValueRef): string =
    ## Convert TOML value in string
    case value.kind:
    of TomlValueKind.Int:
        result = $value
    of TomlValueKind.Float:
        result = $value
    of TomlValueKind.Bool:
        result = $value
    of TomlValueKind.String:
        result = $value
    else:
        result = ""

proc kombinator(configFilePath: string, yes = false): int =
    ## Main function
    ## 'configFilePath' configuration file path
    ## 'yes' don't ask to run
    if fileExists(configFilePath):
        var configTOML: TomlValueRef
        try:
            configTOML = parsetoml.parseFile(configFilePath)
        except:
            echo "Error : parsing config file got exception"
            return 1

        # Create here variable
        var here = os.parentDir(configFilePath)
        if not os.isAbsolute(here):
            here = os.absolutePath(here, getCurrentDir())

        var 
            variables: seq[(string, seq[string])]
            allVariablesName: seq[string]
        if not configTOML.hasKey("cmd"):
            echo "Error : cmd not found"
            return 1
        else:
            # Read command
            var command = configTOML["cmd"].getStr()
            
            # Read variables
            var 
                fileToModif: Table[string, string]
                combinationArray: Table[string, seq[string]]
                sizeOfTab: int
            for variable, value in configTOML.getTable():
                if variable != "cmd":
                    case value.kind:
                    of TomlValueKind.Table:
                        var list : seq[string]
                        if value.getTable().hasKey("min") and value.getTable().hasKey("max"):
                            let 
                                min = value.getTable()["min"].getFloat()
                                max = value.getTable()["max"].getFloat()
                            
                            var step = 1.0
                            if value.getTable().hasKey("step"):
                                step = value.getTable()["step"].getFloat()

                            var 
                                currentValue = min
                                tmp: string
                            while(currentValue < max):
                                tmp = $currentValue
                                tmp.trimZeros()
                                list.add(tmp)
                                currentValue += step
                            tmp = $currentValue
                            tmp.trimZeros()
                            list.add(tmp)

                            variables.add((variable, list))
                            allVariablesName.add(variable)

                        elif value.getTable().hasKey("file"):
                            fileToModif[variable] = value.getTable()["file"].getStr().replace("$here", here)
                        else:
                            echo &"Error : {variable} hasn't the good format"
                            return 1
                    of TomlValueKind.Array:
                        var list : seq[string]
                        # Check if array of array
                        if value[0].kind == TomlValueKind.Array:
                            # Check if all array are the same size
                            sizeOfTab = value[0].len()
                            if not value.getElems().all(proc (x: TomlValueRef): bool = len(x) == sizeOfTab):
                                echo &"{variable} hasn't array with the same size"
                            else:
                                for subArray in value.getElems():
                                    var count = 0
                                    for elem in subArray.getElems():
                                        let variableName = &"{variable}_{count}"
                                        if not combinationArray.hasKey(variableName):
                                            combinationArray[variableName] = @[convertTOMLValueToString(elem)]
                                            allVariablesName.add(variableName)
                                        else:
                                            combinationArray[variableName].add(convertTOMLValueToString(elem))
                                        inc count
                        else:
                            for elem in value.getElems():
                                list.add(convertTOMLValueToString(elem))
                            variables.add((variable, list))
                            allVariablesName.add(variable)
                    of TomlValueKind.Int, TomlValueKind.Float, TomlValueKind.Bool, TomlValueKind.String:
                        variables.add((variable, @[convertTOMLValueToString(value)]))
                        allVariablesName.add(variable)
                    else:
                        echo &"Error : {variable} hasn't the good type"
                        return 1

            # Run combination generation
            var kombi : seq[seq[(string, string)]]
            if variables.len() != 0: 
                generateKomb(variables, 0, 0, kombi)

            # Add array params
            if combinationArray.len() != 0:
                var newKombi : seq[seq[(string, string)]]

                # If hasn't variables in kombi
                if kombi.len() == 0:
                    kombi.add(@[])
                
                for valuePar in kombi.items():
                    for i in (0..sizeOfTab-1):
                        var initValuePar = valuePar
                        for keyTab, valueTab in combinationArray.pairs():
                            initValuePar.add((keyTab, valueTab[i]))
                        newKombi.add(initValuePar)
                kombi = newKombi

            if kombi.len() == 0:
                echo "Error : no variables found"
                return 1

            echo "Number of combination is " & $kombi.len()

            # Check if all variables are used in the command and files
            var paramNotFound: seq[string] = @[]
            for param in allVariablesName:
                if not command.contains(param):
                    paramNotFound.add(param)
            for filePath in fileToModif.values():
                if fileExists(filePath):
                    let 
                        fileOpen = open(filePath)
                        fileContent = readAll(fileOpen)
                    for param in paramNotFound:
                        if not fileContent.contains(param):
                            echo &"Warning : the variable {param} not found in command or files"

            # Ask to run
            var run = if yes : true
                    else: false
            if not yes:
                var response = readLineFromStdin(&"Do you want run commands ? (Y/n): ")
                while true:
                    if "y" == response.toLower() or response == "":
                        run = true
                        break
                    elif "n" == response.toLower() or response == "":
                        break
                    else:
                        response = readLineFromStdin("What ? y or n ? ")

            if run:
                # Change directory
                let outputFolder = $now().format("yyyy-MM-dd'_'HH'h'-mm'm'") & "_output"
                createDir(outputFolder)
                cd outputFolder:

                    # Init CSV file
                    let csvFilePath = "kombi_result.csv"
                    var
                        csvFile = open(csvFilePath, fmWrite)
                        header = "valid"

                    # Write header
                    for param in kombi[0]:
                        header = header & &";{param[0]}"
                    for fileKey in fileToModif.keys():
                        header = header & &";{fileKey}"
                    let patternHeader = header
                    header = header & ";duration_ms;output_dir"
                    writeLine(csvFile, header)

                    # Run commands
                    var nbRun = 0
                    var bar: SuruBar = initSuruBar()
                    bar[0].total = len(kombi)
                    bar.setup()
                    for params in kombi:
                        var
                            currentRunCommand = command
                            paramsToCSV = patternHeader

                        let runDir = &"run_{nbRun}"
                        createDir(runDir)

                        # Run in a nex run directory
                        cd runDir:
                            # Replace $here if exists
                            currentRunCommand = currentRunCommand.replace("$here", here)

                            # Command params
                            for param in params:
                                currentRunCommand = currentRunCommand.replace("$" & param[0], param[1])
                                paramsToCSV = paramsToCSV.replace(param[0], param[1])

                            # File
                            for fileKey, filePath in fileToModif.pairs():
                                if fileExists(filePath):
                                    let fileOpen = open(filePath)
                                    var fileContent = readAll(fileOpen)

                                    fileContent = fileContent.replace("$here", here)
                                    for param in params:
                                        fileContent = fileContent.replace("$" & param[0], param[1])

                                    # Create file
                                    let
                                        filename = extractFilename(filePath)
                                        newFile = &"{nbRun}-{filename}"

                                    writeFile(newFile, fileContent)

                                    # Replace file in command
                                    currentRunCommand = currentRunCommand.replace("$" & fileKey, newFile)
                                    paramsToCSV = paramsToCSV.replace(fileKey, newFile)
                                else:
                                    echo &"Error : file from {fileKey} not found in {filePath}"
                                    return 1

                            # Execute
                            let startTime = now()
                            var (outp, errC) = execCmdEx(currentRunCommand)
                            let execDurationInMs = (now() - startTime).inMilliseconds()

                            # Write output in file
                            let depLogFilePath = &"run_{nbRun}.log"
                            outp = currentRunCommand & "\n" & outp
                            writeFile(depLogFilePath, outp)

                            # Check success
                            if errC != QuitSuccess:
                                paramsToCSV = paramsToCSV.replace("valid", "KO")
                            else:
                                paramsToCSV = paramsToCSV.replace("valid", "OK")

                            # Write params line in CSV
                            paramsToCSV = &"{paramsToCSV};{execDurationInMs};{runDir}"
                            writeLine(csvFile, paramsToCSV)
                            csvFile.flushFile()

                            # Inc progressbar
                            inc nbRun
                            inc bar
                            bar.update()

                    bar.finish()
                    csvFile.close()
    else:
        echo "Error : config file not found"
        return 1

    return 0

when isMainModule:
    dispatch(kombinator, doc = "Application to run a command line with lot of combinations of values.", help = { "configFilePath": "Configuration file", "yes": "Run commands without asking"})