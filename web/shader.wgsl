@group(0) @binding(0)
var<storage, read_write> output: array<u32>;

@compute @workgroup_size(64)
fn main(
  @builtin(global_invocation_id)
  global_id : vec3u,

  @builtin(local_invocation_id)
  local_id : vec3u,
) {
  output[global_id.x] = 1u;
}
