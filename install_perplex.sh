#!/bin/bash

# Function to detect the current operating system
detect_os() {
    local uname_out
    uname_out="$(uname -s)"  # Get system name

    case "$uname_out" in
        Linux*)     echo "linux";;                               # Linux
        Darwin*)    echo "macos";;                               # macOS
        CYGWIN*|MINGW*|MSYS*) echo "windows";;                   # Windows (via Git Bash, etc.)
        *)          echo "unknown";;                             # Anything else
    esac
}

# Detect OS and select the appropriate Makefile
OS_TYPE=$(detect_os)
if [[ "$OS_TYPE" == "macos" ]]; then
    makefilename="OSX_makefile2"
elif [[ "$OS_TYPE" == "linux" ]]; then
    makefilename="LINUX_makefile"
elif [[ "$OS_TYPE" == "windows" ]]; then
    makefilename="WINDOWS_makefile"
else
    echo "Unsupported OS"
    exit 1
fi

# Extract version info from the source file (Fortran source)
version_message=`grep "Perple_X release" external/Perple_X/src/tlib.f | awk -F"'" '{print $2}'`
version=`echo ${version_message} | awk -F"release" '{print $2}' | awk '{print $1}'`

# Print installation summary
echo "Installing ${version_message} to ${OS_TYPE}"

# Remove any previously installed version if the version number matches
rm -fr Perple_X_${version}

# Go to source directory
cd external/Perple_X/src/

# Compile the program using the platform-specific Makefile
make -f $makefilename

# Clean and recreate bin/ directory for executables
rm -fr bin
mkdir bin

# Move all executable, non-hidden files into bin/
# (compatible with macOS and Linux, avoids -executable flag)
find . -maxdepth 1 -type f ! -name '.*' -exec sh -c '
  for file; do
    [ -x "$file" ] && mv "$file" bin/
  done
' _ {} +

# Run make clean to remove build artifacts (*.o files)
make clean

# Create a version-specific installation directory and move the compiled executables there
mkdir ../../../Perple_X_${version}
mv bin ../../../Perple_X_${version}/

# Return to the root of the project
cd ../../../

# Copy data files into the new versioned directory
cp -fr external/Perple_X/datafiles ./Perple_X_${version}/datafiles

# Create a symbolic link "Perple_X" pointing to the just-installed version of Perple_X
ln -sf Perple_X_${version} Perple_X
