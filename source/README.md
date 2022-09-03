<div style="text-align:center"><img src="icons/Kombinator.png" width="200" height="200"></div>

# Kombinator

Application to run a command line with lot of combinations of values.

Kombinator parse a configuration file in TOML format and generate as soon as possible combinations of values. This combinations are used to call a command line and create a CSV report. Command outputs are kept and written in a log file.

## Installation 

### From Nim pakage manager Nimble
```bash
nimble install kombinator
```

### Executables
[Windows and Linux executable](https://gitlab.com/EchoPouet/kombinator/-/releases)

Contributions are welcome.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/EchoPouet)

## Configuration file

First, the mandatory key in the TOML configuration file is **cmd** to write the command line in string type.

```toml
cmd = "ffmpeg -i ../ForBiggerFun.mp4 -s $heightx$width -c:v $codec -ab $audio_bitrate output-$audio_bitrate-$heightx$width-$codec.mp4"
```

Text prefixed with **$** are the parameters that will be replaced when calling the command. To defined a parameter with its all possible values, you would add it in the config file like following:

```toml
height = [640, 800]
```

Possible values are:
* Float
* Boolean
* Integer
* String

Also, you can define a range of values for **Integer** and **Float** like follow:

```toml
audio_bitrate = {min = 128, max = 192, step = 32}
```

**min** and **max** keys are mandatory but not **step** which will have the default value of **1**.

See a complete example file **tests/ffmpeg_conf.toml**.

Sometime an executable needs a file with some parameters. To modify a file, you must define it like follow:

```toml
cfg = {file = "$here/../ref_file.cfg"}
```

The key **file** is mandatory to indicate that it is a file to modify. During execution, **Kombinator** will create a new file from referenced with all parameters modified like the command line. For example, if **$height** exists it will be replaced. To pass this new file to the command line, you must add the key with the prefix **$file** with the previous example.

### Reserved key
**$here** is a reserved key that will be replaced by the parent folder of the configuration file.

## Usage

To run the program, write following command:

```bash
kombinator -c your_conf.toml
```

During execution, **Kombinator** compute all combinations and ask you if you want run the command with them.

## Result file

A folder is created during execution with a name like **2021-08-12_22h-09m_output** and it contains a **CSV** file named **kombi_result.csv** and subdirectories with **log** for each commands.
