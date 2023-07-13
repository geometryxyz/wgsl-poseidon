# Poseidon in WGSL

This repository contains code which allows you to compute Poseidon hashes in
your GPU.

## Help needed:

I'm running into limits getting Poseidon running on my Intel Integrated
Graphics card. If anyone has a Macbook, please help me test this partial
implementation of Poseidon (with 1 input, so t = 2):

```bash
cargo test test_poseidon -- --nocapture
```

## Rust code

## Browser code

## Credits

Much of the big integer and field arithmetic code was adapted from
[msm-webgpu](https://github.com/sampritipanda/msm-webgpu) by Sampriti, Adhyyan,
and Nalin.
