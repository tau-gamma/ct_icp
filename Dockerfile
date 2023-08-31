# Using Ubuntu 18.04 as the base image
FROM ubuntu:18.04

# Metadata to indicate that this image is for CT-ICP
LABEL description="Ubuntu 18.04 with GCC >= 7.5 and CMake >= 3.14 for CT-ICP"
LABEL version="1.0"
LABEL application="CT-ICP"

# Avoids prompts and messages from apt during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary tools and the desired GCC and CMake versions
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y \
        gcc-7 \
        g++-7 \
        wget \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100 

# Installing CMake 3.14
RUN wget -qO- "https://github.com/Kitware/CMake/releases/download/v3.14.0/cmake-3.14.0-Linux-x86_64.tar.gz" \
    | tar --strip-components=1 -xz -C /usr/local

RUN apt-get install -y \
        git-all \
        build-essential 

# Clean up to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/ct_icp
COPY . /root/ct_icp
WORKDIR /root/ct_icp

#< Creates the cmake folder
WORKDIR /root/ct_icp/.cmake-build-superbuild    

#< (1) Configure step 
RUN cmake ../superbuild                                             

#< Build step (Downloads and install the dependencies), add -DWITH_VIZ3D=ON to install with the GUI
RUN cmake --build . --config Release                                

#Inside the main directory < Create the build directory
WORKDIR /root/ct_icp/cmake-build-release

#< (2) Configure with the desired options (specify arguments with -D<arg_name>=<arg_value>), add -DWITH_VIZ3D=ON to install with the GUI
RUN cmake .. -DCMAKE_BUILD_TYPE=Release                                   

#< Build and Install the project
RUN cmake --build . --target install --config Release --parallel 12       

# Set the default command
CMD ["/bin/bash"]
