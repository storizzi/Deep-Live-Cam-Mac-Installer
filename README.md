# Deep-Live-Cam Mac Installer

This repository provides an installation script for setting up the [Deep-Live-Cam](https://github.com/hacksider/Deep-Live-Cam) project on macOS, specifically tailored for systems with Apple Silicon and Intel-based Macs. The script handles everything from setting up the Conda environment, installing necessary dependencies, and running the application with GPU acceleration if available.

## Repository Links

- **Original Deep-Live-Cam Repository**: [hacksider/Deep-Live-Cam](https://github.com/hacksider/Deep-Live-Cam)
- **Installer Code Repository**: [storizzi/Deep-Live-Cam-Mac-Installer](https://github.com/storizzi/Deep-Live-Cam-Mac-Installer)

## Prerequisites

- **macOS**: The script is designed for macOS, supporting both Apple Silicon and Intel-based Macs.


## Warning - VERY PRESCRIPTIVE AUTO-INSTALLATION

This installer is VERY opinionated and if you don't have homebrew, it was install it for you, and it will install miniconda if you don't have it, the appropriate version of python in a conda session, and ffmpeg.

It also aims to avoid pitfalls of other types of environment approaches by pinpointing the exact paths to python / pip etc in the conda session created

## Installation Instructions

1. **Clone the Installer Repository**:

   Clone the repository containing the installation script:

   ```
   git clone https://github.com/storizzi/Deep-Live-Cam-Mac-Installer.git
   cd Deep-Live-Cam-Mac-Installer
   ```

2. **Run the Installation Script**:

   Run the `deep_live_cam.sh` script to set up the environment and install dependencies:

   ```
   ./deep_live_cam.sh
   ```

   This script will:
   - Check for and install Conda if necessary.
   - Set up a Conda environment with Python 3.10.
   - Clone the Deep-Live-Cam repository.
   - Download required models.
   - Install necessary dependencies, including appropriate CoreML support for either Intel or Apple Silicon
   - Check for camera access and guide you to enable it if necessary for most popular terminal types

3. **Running the Application**:

   After the installation is complete, the script will automatically run the Deep-Live-Cam application. The script supports various command-line options to customize the setup and execution.

## Command-Line Options

- **`--run`**: Skip setup and run the application only.
- **`--setup`**: Perform setup only, without running the application.
- **`--nocam`**: Skip the camera access check and proceed with setup and running.
- **`--cpu`**: Run the application using CPU only (no GPUs).
- **`--clean`**: Remove the Conda environment and delete the cloned repository.
- **`--camreset [APP_ID]`**: Reset camera access for the specified application (e.g., `com.apple.Terminal` or `com.googlecode.iterm2`).
- **`--help`**: Display help message and exit.

All other options will be passed directly to the Deep-Live-Cam Python library.

## Camera Access

The application requires camera access. If the script detects that camera access is not granted, it will guide you through the process of enabling it.

### Manually Enabling Camera Access

1. Open `System Settings` (or `System Preferences` on older macOS versions).
2. Go to `Privacy & Security` > `Camera`.
3. Find your terminal application (e.g., Terminal, iTerm).
4. Ensure the checkbox next to your terminal application is checked.
5. Re-run the script after enabling camera access.

Alternatively, you can use the `--nocam` option to bypass this check if you do not want to use the live cam feature.

## Cleaning Up

If you wish to remove the Conda environment and delete the cloned repository, you can use the `--clean` option:

```
./deep_live_cam.sh --clean
```

This will remove the environment and delete the `Deep-Live-Cam` directory, allowing you to start fresh.

## Uninstalling Miniconda and Homebrew

If you decide to remove Miniconda and Homebrew from your system, follow the steps below:

### Uninstalling Miniconda

Since Miniconda was installed using Homebrew, you can easily uninstall it using the following command:

'''
brew uninstall --cask miniconda
'''

This command will remove the Miniconda installation from your system.

**Note**: Uninstalling Miniconda via Homebrew will not automatically delete the Conda environments and configurations stored in your home directory. To fully clean up, you may want to manually delete these directories:

1. **Delete Conda Environments and Configuration Files**:

   '''
   rm -rf ~/miniconda3 ~/.conda ~/.condarc ~/.continuum ~/.anaconda
   '''

   These commands will remove:
   - The default Miniconda installation directory (`~/miniconda3`).
   - The Conda configuration file (`~/.condarc`).
   - The Conda environments directory (`~/.conda`).
   - Continuum-related settings (`~/.continuum`).
   - Any remaining Anaconda-related settings (`~/.anaconda`).

2. **Remove Conda Initialization from Shell Profile**:

   If you had initialized Conda in your shell, you might also want to remove the Conda initialization commands from your shell configuration files, such as `~/.zshrc` or `~/.bashrc`. Open the file and remove any lines referencing Conda, such as:

   '''
   # >>> conda initialize >>>
   __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
   if [ $? -eq 0 ]; then
       eval "$__conda_setup"
   else
       if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
           . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
       else
           export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
       fi
   fi
   unset __conda_setup
   # <<< conda initialize <<<
   '''

   After making these changes, you can reload your shell configuration or restart your terminal session.

### Uninstalling Homebrew

To completely remove Homebrew from your system, use the following steps:

1. **Run the Homebrew Uninstall Script**:

   Homebrew provides an official uninstall script that you can use to remove it from your system:

   '''
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   '''

   This script will remove all Homebrew packages, directories, and settings from your system.

2. **Manual Cleanup** (Optional):

   After running the uninstall script, some residual files may remain. You can remove them manually by deleting the Homebrew directory:

   '''
   sudo rm -rf /usr/local/Homebrew
   sudo rm -rf /opt/homebrew
   rm -rf ~/.brew
   rm -rf /usr/local/Caskroom /usr/local/Cellar /usr/local/Frameworks
   '''

   These commands remove the main Homebrew directories, any cached files, and any additional installations.

### Final Steps

After uninstalling both Miniconda and Homebrew, your system will be free of these tools. If you ever need them again, you can reinstall them following the instructions on their official websites:

- **Miniconda**: [https://docs.conda.io/en/latest/miniconda.html](https://docs.conda.io/en/latest/miniconda.html)
- **Homebrew**: [https://brew.sh/](https://brew.sh/)

or by re-running this installation script!

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

- The original Deep-Live-Cam project is developed and maintained by [hacksider](https://github.com/hacksider).
- This installer script is developed and maintained by [Simon Huggins of Storizzi](https://github.com/storizzi).

## Prompt for this readme was:

Can you create a README.md markdown file for this that explains how to install this? Can you specify that it depends on the github repo which can be found at: https://github.com/hacksider/Deep-Live-Cam.
The code will be stored at this location: https://github.com/storizzi/Deep-Live-Cam-Mac-Installer.

Can you include a few sections on how to uninstall miniconda and homebrew if you want to (bearing in mind we installed miniconda with homebrew)

Can you use ``` instead of 
backticks so that I can copy paste the markdown.

Can you put the markdown text into a code block so I. can see the markdown to copy include links etc