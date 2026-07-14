# ALS-FPGA

An [F4PGA](https://f4pga.org/)-based flow for Xilinx 7-Series FPGAs (`xc7`) with an approximate-LUT synthesis integrated into the Yosys flow.

## Repository layout
 
```
als-fpga/
├── tools/
│   ├── f4pga/          
│   ├── vtr/             
│   └── f4pga-examples/  
└── README.md
```

## Prerequisites
 
- Linux x86-64.
- `git`, `wget`, `xz-utils`.
- ~10–15 GB of free disk for the toolchain environment.
- Miniconda is downloaded during installation.

## Install the base toolchain

Go to the f4pga-examples directory:

```bash
cd tools/f4pga-examples
```

Dowload Miniconda installer:

```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O conda_installer.sh
```

Declare dedicated path and family installation:

```bash
export F4PGA_INSTALL_DIR=~/opt/f4pga-als
export FPGA_FAM=xc7
```

Install conda in the path and create the environment:

```bash
bash conda_installer.sh -u -b -p $F4PGA_INSTALL_DIR/$FPGA_FAM/conda
source "$F4PGA_INSTALL_DIR/$FPGA_FAM/conda/etc/profile.d/conda.sh"
conda env create -f $FPGA_FAM/environment.yml   
```

Download architecture definitions and part files:

```bash
export F4PGA_PACKAGES='install-xc7 xc7a50t_test xc7a100t_test xc7a200t_test xc7z010_test'
mkdir -p $F4PGA_INSTALL_DIR/$FPGA_FAM
F4PGA_TIMESTAMP='20220920-124259'
F4PGA_HASH='007d1c1'
for PKG in $F4PGA_PACKAGES; do
  wget -qO- https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/${F4PGA_TIMESTAMP}/symbiflow-arch-defs-${PKG}-${F4PGA_HASH}.tar.xz | tar -xJC $F4PGA_INSTALL_DIR/${FPGA_FAM}
done
```

## Override with the modified F4PGA
 
With the environment active, uninstall the upstream `f4pga` and install this repo's version in editable mode:
 
```bash
conda activate xc7
pip uninstall -y f4pga
pip install -e tools/f4pga/f4pga    # adjust the path depending on where you are
```
 
> You should see it uninstall `f4pga 0.0.0+e1cd038f0` (upstream) and install `f4pga 0.0.0+8bfab9dc`.

