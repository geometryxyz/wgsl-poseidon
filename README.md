# Poseidon in WGSL

This repository contains code which allows you to compute Poseidon hashes in
your GPU. The code is written in WGSL, a shader programming language that
works with WebGPU.

This implementation of the Poseidon hash targets the BN254 scalar field, with
the following parameters:

- Number of inputs: 1
- `t = 2`
- `n_rounds_f = 8`
- `n_rounds_p = 56`

The results from this implementation should match those of the circomlibjs
implementation on BN254.

## Credits

Much of the big integer and finite field code was adapted from 
[msm-webgpu](https://github.com/sampritipanda/msm-webgpu) by Sampriti Panda,
Adhyyan Sekhsaria, and Nalin Bhardwaj.

The structure of the Poseidon WGSL code was inspired by
[poseidon-ark](https://github.com/arnaucube/poseidon-ark) by arnaucube.

## Getting started

Clone this repository, navigate to the project directory, and run:

```bash
cargo test test_poseidon -- --nocapture
```

You should see output like this:

```
Computing 16384 Poseidon hashes in Rust / WebGPU
CPU took 609ms
AdapterInfo { name: "Quadro P520", vendor: 4318, device: 7476, device_type: DiscreteGpu, driver: "NVIDIA", driver_info: "535.54.03", backend: Vulkan }
GPU took 276ms
test poseidon::test_poseidon ... ok
```

The time taken by the GPU to compute a hash the first time you run this command
may be slower than the time it takes during subsequent runs. This may be due to
the GPU caching the shader code.

This code has been successfully tested with an Nvidia Quadro P520 with 2GB
memory on a Ubuntu Linux machine with version 535.54.03 of the Nvidia driver.

The code, however, fails to run on the same machine's Intel(R) UHD Graphics 620
(WHL GT2) integrated GPU with the Mesa v22.2.5 driver.

## Poseidon hash using WebGPU in the browser

The following was tested with [Firefox
Nightly](https://www.mozilla.org/en-US/firefox/nightly/notes/) 117.0a1
(2023-07-15) (64-bit).

Enter `about:config` in the address bar and set the following to true:

- `dom.webgpu.enabled`
- `gfx.webgpu.force-enabled`

Next, in the command line, navigate to the `web` subdirectory:

```bash
cd web
```

Install dependencies:

```bash
npm i
```

Run the web server:

```bash
npx parcel index.html
```

Navigate to the URL that appears and viola! You should see something like the following:

```
Computing 16384 Poseidon hashes in the browser / WebGPU
CPU took 1983 ms
GPU took 299 ms
```
