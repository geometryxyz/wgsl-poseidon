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

## Getting started

Clone this repository, navigate to the project directory, and run:

```bash
cargo test test_poseidon -- --nocapture
```

You should see output like this:

```
AdapterInfo { name: "Quadro P520", vendor: 4318, device: 7476, device_type: DiscreteGpu, driver: "NVIDIA", driver_info: "535.54.03", backend: Vulkan }
GPU took 132ms
Input: 1
Result from GPU: 18586133768512220936620570745912940619677854269274689475585506675881198879027
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

Navigate to the URL that appears and viola! You should see the following hash of the field element `1`:

```
18586133768512220936620570745912940619677854269274689475585506675881198879027
```
