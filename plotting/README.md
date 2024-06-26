# plot_counter - Display amount of plots for each C-level

`plot_counter`: A script that counts Chia plots on multiple disks and calculates their total size in TiB (tebibytes). The script will scan mounted disks at a specified interval and display the count and size of plots found for each compression level. It will also display how many plots and data has been written to the identified disks in a given time. The results are displayed in a table format in the terminal.

## Usage

```bash
./plot_counter (--mount-dir </path/to/dir> | --label <disklabel>) [--interval interval_seconds]
```

## Options
   - `--mount-dir` </path/to/dir>: Count Chia plots in the specified directory
   - `--label` <disklabel>: Count Chia plots in the disks starting with the specified label pattern (default: CHIA)
   - `--interval` <interval_seconds>: Set the rescan interval in seconds (default: 120 seconds)

## Examples

count all plots in /media/root/* Rescan after 100 seconds.

```bash
./plot_counter --mount-dir /media/root --interval 100
```


count all plots from all disks in /media/root/ beginning with the pattern CHIA* (/media/root/CHIA-001 /media/root/CHIA-002 ...)

```bash
./plot_counter /media/root/CHIA
```   

count all plots from all disks labelled beginning with the pattern GIGA (no matter where they are mounted at in the system).

```bash
./plot_counter --label GIGA
```   


# plot_mover - A simple and user-friendly plot moving script

`plot_mover` is a Bash script that monitors a specified source directory for new Chia plot files and moves them to a specified destination directory using `rsync`. `plot_mover` is a rather simple script that will currently handle only one file at a time. If a new plot arrives in the `watch_dir` it isn't processed until the current copy process is finished. Hence, this tool won't take advantage of expanding transfer bandwith by using multiple target hard drives.
That's why I would recommend to use the in-built `-d, --finaldir` argument of the cuda plotter to handle moving of plots. There are two ways to achieve bandwith optimized moving plots:
- use `plot-sink` and specify a remote or local host IP (current default of `plot_starter`)
- use the mergerfs `/mnt/garden` as a destination directory. The specified write policy `mfs (most free space)` will always pick a new drive as long as the drives offer equally free space.

## Prerequisites

- rsync

## Usage

```bash
./plot_mover <watch_dir> <dest_dir>
```

- `<watch_dir>`: The source directory to monitor for new plot files.
- `<dest_dir>`: The destination directory to move the plot files to.

## Example

```bash
./plot_mover /mnt/plotting /mnt/garden
```

This command will monitor the `/mnt/plotting` directory for new plot files and move them to the `/mnt/garden` directory when detected.



# plot_over - A replot helper

`plot_over`: This script will assist your replotting process by gradually removing undesired plots with a given compression level. To achieve this it will monitor the free space of Chia plot disks and automatically remove older plots of one or multiple given C-levels when the free space of a disk falls below a specified threshold. The script aims to maintain a desired number of disks with at least the specified minimum free space. This way enough disks are continously offered to other tools like plot_sink or mergerfs to optimize bandwith.

## Requirements

- duf-utility https://github.com/muesli/duf
- your plot files are either distributed on disks labelled with the same prefix or the plot disks are all mounted in one mountpoint exclusively.

## Usage

1. Open the script in a text editor and set the following variables according to your setup:

   - `min_free_space`: minimum free space in GB per Disk(e.g., 100)
   - `replot_levels`: comma-separated list of plot compression levels that may be replotted
   - `amount_free_disks`: desired number of disks with minimum free space (e.g., 10)
   - `interval`: rescan interval in seconds (default is 30 seconds)
   - `logfile`: set to `/path/to/file.log` or leave empty (`""`)
     
2. To run the script make sure to make it executable first

   - `chmod +x plot_over`
   - `./plot_over`


## Examples
   
   Call plot_over and load its config file from /etc/chiagarden/plot_over.config
   ```bash
   ./plot_over --config /etc/chiagarden/plot_over.config
   ```



# plot_starter - A better start for plotting

`plot_starter`: is a script that automates the Chia plotting process. The script cleans up your plotting drive before plotting begins. It checks if the plotting directory is mounted, and mounts it if necessary. It removes temporary files that are no longer in use and moves finished *.plot files before starting the plotting process with the given parameters. It offers to load custom profiles and has a builtin cooldown counter so the plotting process is delayed if your system encountered too many hard crashes (nvme wearout, GPU overpowered, etc)

## Requirements

- chia_plot_sink and chia_plot_copy in /usr/local/bin/. This is recommended for cleanup of the plotting directory.
- we assume you are using gigahorse cuda_plot_k32
- profile files (load with --profile) should be put current working dir, /etc/chiagarden or ~/.config/chiagarden/

## Usage

1. Open the script in a text editor and set the variables according to your setup

   - `farmerkey`: your farmerkey
   - `contract`: your pool contract address
   - `plotting_dir`: your temporary plotting dir (-t in cuda_plot_k32)
   - `dest_dir`: et to a destination dir or a host where plotsink is running

   Variables for the guru-mediation option. 
   It delays start of the plotting process if the system has rebooted (crashed) too often
   This is a known behaviour if a nvme is worn out, or your GPU overpowered. If you have configured your server to autostart the plotting process upon boot this will avoid constant crashes and reboots.
   - `max_reboots=2`     Number of xx reboots..
   - `lastminutes=120`   ...in the last yy in minutes
   - `cooldowntime=15`   Wait time in minutes before plotting is started.

2. To run the script make sure to make it executable first

   - `chmod +x plot_starter`
   - `./plot_starter`

## Options

   - `--profile`: `</path/to/profile>` a text file containing any of the variables of the script to be set individually. If path is omitted, it is searched for in current working dir, /etc/chiagarden or ~/.config/chiagarden/
   - `--guru-meditation` : activate a delay if the system has crashed multiple times before (see variable in the script for finetuning)
   - `--help`: display a help text

## Installation
The systemd services for plotsink and plotstarter are part of the installation routine. You can always use `systemctl enable/disable nameof.service` to (de)activate the service on boot.

## Examples
   
   Start plotting process, read some variables (for example farmerkey and contract address) from /etc/chiagarden/myfarm.profile
   ```bash
   ./plot_starter --profile myfarm.profile --guru-meditation
   ```


# plot_timer - Plotting Time Calculation Script

This script calculates the average creation time of Chia plots over a specified period by parsing the `plot-starter` logs.

## Features

- Calculate the average plot creation time for Chia plots.
- Ability to specify the time frame for the logs to be considered.

# Usage

To execute the script, you can simply run it from the command line. 
By default, the script calculates the average plot creation time for the last 30 minutes:
```bash
plot_timer
```

To specify a different time frame, use the `--last` parameter followed by the number of minutes:
```bash
plot_timer --last=60
```

# plot_cleaner - remove those unfinished .plot.tmp files

The Plot Cleaner script is designed to help manage disk space by periodically identifying and removing `.plot.tmp` files that are no longer being written to. This is particularly useful for example, when a plotting stops for an unexpected reason.
A plot file's age is checked against a user-defined threshold (in minutes). If a file is older than the specified age, it is a candidate for deletion.
To ensure that a file is not currently being written to, the script monitors the file size over a user-defined interval (in seconds). If the file size does not change between checks, it is assumed that the file is no longer being actively written to and can be safely removed.   


## Features

- **Automatic Deletion**: Deletes `.plot.tmp` files based on age and write-status.
- **Configurable**: Allows custom settings for directory paths, age threshold, and check intervals.
- **Dry Run Option**: Includes a dry run mode to preview files that would be deleted without actually removing them.

## Installation

To run plot_cleaner periodically add a line to crontab:
```bash
crontab -e
```
for example, to run the script once every hour:
```
0 * * * * /usr/local/bin/plot_cleaner
```

## Usage

To use the script, navigate to the directory containing `plot_cleaner` and run the following command:

```bash
./plot_cleaner [OPTIONS]
```

## Options

- `--directory PATH`: Set the directory where `.plot.tmp` files are stored (default: `/mnt/garden/gigahorse`).
- `--age MINUTES`: Set the minimum age of files to be considered for deletion (in minutes).
- `--watchtime SECONDS`: Set the duration to wait between file size checks to determine if the file is still being written to (in seconds).
- `--dry-run`: Display the files that would be deleted without actually performing the deletion.

## Example

Perform a dry run that displays files older than 720 minutes which would be deleted
```bash 
./plot_cleaner --directory /mnt/garden/gigahorse --age 720 --watchtime 15 --dry-run
```
