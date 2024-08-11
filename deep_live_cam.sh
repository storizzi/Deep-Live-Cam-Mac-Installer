#!/bin/zsh

# Constants
ENV_NAME="deep-live-cam"
REQUIRED_PYTHON_VERSION="3.10"
REPO_URL="https://github.com/hacksider/Deep-Live-Cam.git"
MODELS_DIR="Deep-Live-Cam/models"
URL_GFPGAN="https://huggingface.co/hacksider/deep-live-cam/resolve/main/GFPGANv1.4.pth"
URL_INSWAPPER="https://huggingface.co/hacksider/deep-live-cam/resolve/main/inswapper_128_fp16.onnx"
MODEL_1="$MODELS_DIR/GFPGANv1.4.pth"
MODEL_2="$MODELS_DIR/inswapper_128_fp16.onnx"
COREML_DEPENDENCY="onnxruntime-silicon==1.13.1"
INTEL_DEPENDENCY="onnxruntime-coreml==1.13.1"
BREW_CONDA_PATH="/opt/homebrew/Caskroom/miniconda/base/bin"

# Function to display help message
display_help() {
    echo "Usage: ./deep_live_cam.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --run        Skip setup and run the application only."
    echo "  --setup      Perform setup only, without running the application."
    echo "  --nocam      Skip camera access check and proceed with setup and running."
    echo "  --cpu        Run the application using CPU only."
    echo "  --clean      Remove the Conda environment and delete the cloned repository."
    echo "  --camreset [APP_ID]  Reset camera access for the specified application (e.g., com.apple.Terminal or com.googlecode.iterm2)."
    echo "  --help       Display this help message and exit."
    exit 0
}

# Function to ensure we are using Homebrew's Conda
ensure_brew_conda() {
    if [ -d "$BREW_CONDA_PATH" ]; then
        export PATH="$BREW_CONDA_PATH:$PATH"
        echo "Using Conda from Homebrew installation at $BREW_CONDA_PATH"
    else
        echo "Homebrew Conda not found at $BREW_CONDA_PATH. Please ensure Miniconda is installed via Homebrew."
        exit 1
    fi
}

# Function to check if Homebrew is installed, and install it if not
check_and_install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ $? -ne 0 ]]; then
            echo "Failed to install Homebrew."
            exit 1
        fi
        echo "Homebrew installed successfully."
        # Add Homebrew to the PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew is already installed."
    fi
}

# Function to check if Conda is installed, and install Miniconda via Homebrew if not
check_and_install_conda() {
    ensure_brew_conda

    if ! command -v conda &> /dev/null; then
        echo "Conda is not installed. Installing Miniconda via Homebrew..."
        brew install --cask miniconda
        if [[ $? -ne 0 ]]; then
            echo "Failed to install Miniconda via Homebrew."
            exit 1
        fi
        echo "Miniconda installed successfully."
        # Initialize conda for the current shell
        conda init zsh
        source ~/.zshrc
    else
        echo "Conda is already installed."
        # Ensure Conda is initialized
        conda init zsh
        source ~/.zshrc
    fi
}

# Function to check the Python version in the environment
check_python_version_in_env() {
    local python_version=$(conda run -n $ENV_NAME python --version 2>&1 | awk '{print $2}')
    
    if [[ $python_version == $REQUIRED_PYTHON_VERSION* ]]; then
        echo "Conda environment '$ENV_NAME' already has the correct Python version ($REQUIRED_PYTHON_VERSION)."
        return 0
    else
        echo "Conda environment '$ENV_NAME' has an incorrect Python version ($python_version)."
        return 1
    fi
}

# Function to create or recreate the Conda environment with the correct Python version
create_or_update_conda_env() {
    if conda info --envs | grep -q "$ENV_NAME"; then
        if check_python_version_in_env; then
            conda activate $ENV_NAME
        else
            echo "Removing Conda environment '$ENV_NAME' due to incorrect Python version..."
            conda remove -n $ENV_NAME --all -y
            echo "Creating Conda environment '$ENV_NAME' with Python $REQUIRED_PYTHON_VERSION..."
            conda create -n $ENV_NAME python=$REQUIRED_PYTHON_VERSION -y
            if [[ $? -ne 0 ]]; then
                echo "Failed to create Conda environment with Python $REQUIRED_PYTHON_VERSION."
                exit 1
            fi
            conda activate $ENV_NAME
        fi
    else
        echo "Creating Conda environment '$ENV_NAME' with Python $REQUIRED_PYTHON_VERSION..."
        conda create -n $ENV_NAME python=$REQUIRED_PYTHON_VERSION -y
        if [[ $? -ne 0 ]]; then
            echo "Failed to create Conda environment with Python $REQUIRED_PYTHON_VERSION."
            exit 1
        fi
        conda activate $ENV_NAME
    fi
}

# Function to get the full path to Python and Pip in the Conda environment
get_conda_bin_paths() {
    CONDA_ENV_PATH=$(conda info --envs | grep "$ENV_NAME" | awk '{print $NF}')
    PYTHON_PATH="$CONDA_ENV_PATH/bin/python"
    PIP_PATH="$CONDA_ENV_PATH/bin/pip"

    if [[ -x "$PYTHON_PATH" && -x "$PIP_PATH" ]]; then
        echo "Using Python from $PYTHON_PATH: $($PYTHON_PATH --version)"
        echo "Using pip from $PIP_PATH: $($PIP_PATH --version)"
    else
        echo "Error: Python or pip not found in the Conda environment."
        exit 1
    fi
}

# Function to clone the Git repository if not already cloned
clone_repo() {
    if [[ ! -d "Deep-Live-Cam" ]]; then
        echo "Cloning the Deep-Live-Cam repository..."
        git clone "$REPO_URL"
        if [[ $? -ne 0 ]]; then
            echo "Failed to clone the Deep-Live-Cam repository."
            exit 1
        fi
    else
        echo "Deep-Live-Cam repository already exists."
    fi
}

# Function to check and download models
check_and_download_models() {
    # Ensure the models directory exists
    mkdir -p "$MODELS_DIR"

    # Download GFPGAN model if not already present
    if [[ ! -f $MODEL_1 ]]; then
        echo "Downloading $MODEL_1..."
        curl -L -o $MODEL_1 $URL_GFPGAN
        if [[ $? -ne 0 ]]; then
            echo "Failed to download $MODEL_1."
            exit 1
        fi
    else
        echo "$MODEL_1 already exists."
    fi

    # Download inswapper model if not already present
    if [[ ! -f $MODEL_2 ]]; then
        echo "Downloading $MODEL_2..."
        curl -L -o $MODEL_2 $URL_INSWAPPER
        if [[ $? -ne 0 ]]; then
            echo "Failed to download $MODEL_2."
            exit 1
        fi
    else
        echo "$MODEL_2 already exists."
    fi
}

# Function to install CoreML dependencies for Apple Silicon
install_coreml_dependencies() {
    echo "Installing CoreML dependencies for Apple Silicon..."
    $PIP_PATH install --upgrade pip
    $PIP_PATH uninstall -y onnxruntime-silicon || echo "WARNING: Skipping onnxruntime-silicon as it is not installed."
    if ! $PIP_PATH install $COREML_DEPENDENCY; then
        echo "ERROR: Could not find a compatible version of onnxruntime-silicon. Check your Python environment and ensure it supports this package."
        exit 1
    fi
}

# Function to install onnxruntime-coreml dependencies for Intel-based Mac
install_coreml_dependencies_intel() {
    echo "Installing CoreML dependencies for Intel-based Mac..."
    $PIP_PATH install --upgrade pip
    $PIP_PATH uninstall -y onnxruntime-coreml || echo "WARNING: Skipping onnxruntime-coreml as it is not installed."
    if ! $PIP_PATH install $INTEL_DEPENDENCY; then
        echo "ERROR: Could not find a compatible version of onnxruntime-coreml. Check your Python environment and ensure it supports this package."
        exit 1
    fi
}

# Function to run the setup stage
run_setup() {
    # Check and install Homebrew if necessary
    check_and_install_homebrew

    # Check and install Conda if necessary
    check_and_install_conda

    # Create or update the Conda environment with the correct Python version
    create_or_update_conda_env

    # Get the paths to python and pip
    get_conda_bin_paths

    # Clone the repository before proceeding with other steps
    clone_repo

    # Check and download models after cloning the repository
    check_and_download_models

    # Change to the Deep-Live-Cam directory if it exists
    if [[ -d "Deep-Live-Cam" ]]; then
        cd Deep-Live-Cam || { echo "Failed to change directory to Deep-Live-Cam"; exit 1; }
    else
        echo "Error: Deep-Live-Cam directory not found."
        exit 1
    fi

    # Check for and install the appropriate CoreML or Intel dependencies
    if [[ "$IS_APPLE_SILICON" == true ]]; then
        install_coreml_dependencies
    else
        install_coreml_dependencies_intel
    fi

    # Install ffmpeg using Homebrew if not installed
    if ! command -v ffmpeg &> /dev/null; then
        echo "ffmpeg is not installed. Installing ffmpeg..."
        brew install ffmpeg
        if [[ $? -ne 0 ]]; then
            echo "Failed to install ffmpeg."
            exit 1
        fi
        echo "ffmpeg installed successfully."
    fi

    # Install Python dependencies if not already installed
    REQUIREMENTS_INSTALLED=true
    while IFS= read -r package; do
        if ! $PIP_PATH show "${package}" &> /dev/null; then
            REQUIREMENTS_INSTALLED=false
            break
        fi
    done < <(grep -Eo '^[a-zA-Z0-9-]+' requirements.txt)

    if [[ "$REQUIREMENTS_INSTALLED" = false ]]; then
        $PIP_PATH install --use-pep517 basicsr || $PIP_PATH install git+https://github.com/xinntao/BasicSR.git
        $PIP_PATH install -r requirements.txt
        if [[ $? -ne 0 ]]; then
            echo "Failed to install Python dependencies."
            exit 1
        fi
    else
        echo "All Python dependencies are already installed."
    fi

    cd ..
}

# Function to run the application
run_application() {
    if [[ -d "Deep-Live-Cam" ]]; then
        cd Deep-Live-Cam || { echo "Failed to change directory to Deep-Live-Cam"; exit 1; }
    else
        echo "Error: Deep-Live-Cam directory not found."
        exit 1
    fi

    if [[ "$USE_CPU_ONLY" == true ]]; then
        echo "Running the application using CPU only..."
        $PYTHON_PATH run.py
    else
        echo "Running the application with CoreML acceleration..."
        $PYTHON_PATH run.py --execution-provider coreml
    fi

    cd ..
}

# Function to detect whether the system is using Apple Silicon
detect_apple_silicon() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "Apple Silicon (arm64) detected."
        IS_APPLE_SILICON=true
    else
        echo "Intel-based Mac detected."
        IS_APPLE_SILICON=false
    fi
}

# Function to reset camera permissions using tccutil
reset_camera_permissions() {
    if [[ -z "$APP_ID" ]]; then
        detect_terminal_app_id
    fi

    if [[ -z "$APP_ID" ]]; then
        echo "Error: No application identifier could be detected automatically. Please specify the --camreset option with the correct APP_ID."
        exit 1
    fi

    echo "Resetting camera access for application ID: $APP_ID"
    tccutil reset Camera "$APP_ID"
    if [[ $? -ne 0 ]]; then
        echo "Failed to reset camera access for $APP_ID."
        exit 1
    else
        echo "Camera access reset for $APP_ID. Please re-run this script to check camera access."
        exit 0
    fi
}

# Function to check camera access with Swift
check_camera_access() {
    echo "Checking camera access..."
    swift check_camera_access.swift
    if [[ $? -ne 0 ]]; then
        echo "Camera access is required to proceed."
        echo ""
        echo "To manually enable camera access:"
        echo "1. Open 'System Settings' (or 'System Preferences' on older macOS versions)."
        echo "2. Go to 'Privacy & Security' > 'Camera'."
        echo "3. Find your terminal application (e.g., Terminal, iTerm)."
        echo "4. Ensure the checkbox next to your terminal application is checked."
        echo "5. Re-run this script after enabling camera access."
        echo ""
        echo "Alternatively, you can use the '--nocam' option to bypass this check."
        exit 1
    fi
}

# Function to detect the terminal emulator and set the appropriate app identifier
detect_terminal_app_id() {
    case "$TERM_PROGRAM" in
        "Apple_Terminal")
            APP_ID="com.apple.Terminal"
            ;;
        "iTerm.app")
            APP_ID="com.googlecode.iterm2"
            ;;
        "vscode")
            APP_ID="com.microsoft.VSCode"
            ;;
        "WezTerm")
            APP_ID="org.wezfurlong.wezterm"
            ;;
        *)
            APP_ID=""
            echo "Unknown terminal emulator. Please specify the --camreset option with the correct APP_ID."
            ;;
    esac
}

# Function to clean the environment and delete the repository
# Function to clean the environment and delete the repository
clean_environment() {
    echo "Cleaning up environment and repository..."
    
    # Ensure Conda is initialized in the current shell
    conda init zsh
    source ~/.zshrc
    
    # Deactivate the environment if it is active
    if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
        echo "Deactivating the Conda environment '$ENV_NAME'..."
        conda deactivate || echo "Warning: Could not deactivate the environment. Continuing with cleanup."
    fi

    # Remove Conda environment if it exists
    if conda info --envs | grep -q "$ENV_NAME"; then
        echo "Removing Conda environment '$ENV_NAME'..."
        conda remove -n $ENV_NAME --all -y || echo "Warning: Could not remove the environment. Please ensure it is deactivated and try again."
    else
        echo "Conda environment '$ENV_NAME' does not exist."
    fi

    # Delete the cloned repository
    if [[ -d "Deep-Live-Cam" ]]; then
        echo "Deleting the Deep-Live-Cam repository..."
        rm -rf Deep-Live-Cam
    else
        echo "Deep-Live-Cam repository does not exist."
    fi

    echo "Cleanup complete."
}

# Main script logic
SKIP_CAMERA_CHECK=false
USE_CPU_ONLY=false
APP_ID=""
CLEAN_ONLY=false

# Parse command-line arguments
for arg in "$@"; do
    case "$arg" in
        --run)
            echo "--run parameter detected. Skipping setup and running the application..."
            SKIP_SETUP=true
            ;;
        --setup)
            echo "--setup parameter detected. Performing setup only..."
            SKIP_RUN=true
            ;;
        --nocam)
            echo "--nocam parameter detected. Skipping camera access check..."
            SKIP_CAMERA_CHECK=true
            ;;
        --cpu)
            echo "--cpu parameter detected. Running application with CPU only..."
            USE_CPU_ONLY=true
            ;;
        --clean)
            echo "--clean parameter detected. Cleaning environment and repository..."
            CLEAN_ONLY=true
            ;;
        --camreset)
            shift # Move to the next argument to get the app identifier
            APP_ID="$1"
            ;;
        --help)
            display_help
            ;;
        *)
            ;;
    esac
done

# Perform clean and exit if --clean is specified
if [[ "$CLEAN_ONLY" == true ]]; then
    clean_environment
    exit 0
fi

# Check for Apple Silicon
detect_apple_silicon

# Run setup if not skipped
if [[ "$SKIP_SETUP" != true ]]; then
    run_setup
fi

# Get the paths to python and pip
get_conda_bin_paths

# Check camera access if not skipped
if [[ "$SKIP_CAMERA_CHECK" = false ]]; then
    check_camera_access
fi

# Reset camera permissions if the camreset option is provided or automatically detect the terminal
if [[ -n "$APP_ID" ]]; then
    reset_camera_permissions
fi

# Run application if not skipped
if [[ "$SKIP_RUN" != true ]]; then
    run_application
fi

# Deactivate the environment only if it was activated in this session
if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
    conda deactivate
fi
