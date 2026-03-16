# OrangeFox Action Builder
Compile your first custom recovery from OrangeFox Recovery using Github Action.

# How to Use
1. Fork this repository.

2. Go to `Action` tab > `All workflows` > `OrangeFox - Build` > `Run workflow`, then fill all the required information:
 * MANIFEST_BRANCH (`12.1` and `14.1`)
 * DEVICE_TREE (Your device tree repository link.)
 * DEVICE_TREE_BRANCH (Your device tree repository branch; it does not need to match the manifest branch name)
 * DEVICE_PATH (`device/vendor/codename`)
 * DEVICE_NAME (Your device codename)
 * BUILD_TARGET (`boot`, `recovery`, `vendorboot`)

 # Note
* This action will now only support manifest 12.1 and 14.1, since all orangefox manifest below 12.1 are considered obsolete.
* Make sure your tree uses right variable (updated vars) from OrangeFox; [fox_12.1](https://gitlab.com/OrangeFox/vendor/recovery/-/blob/fox_12.1/orangefox_build_vars.txt) and [fox_14.1](https://gitlab.com/OrangeFox/vendor/recovery/-/blob/fox_14.1/orangefox_build_vars.txt), to avoid build erros.
* When you build an Android 16-targeted tree on the `14.1` manifest, the workflow now runs `patches/fox_14.1/apply_a16_compat.sh` after source sync so missing `external/guava` sources are restored automatically for host Java builds, and CTS release/version files are patched whenever the `cts` directory exists in that source tree.
* If a future `14.1` build still fails on another Android 16 compatibility check, extend that same patch script instead of scattering extra `sed` commands throughout the workflow.
* In the workflow logs, check the patch step for `Cloned external/guava...` or `Validated external/guava module definition: name: "guava"` before trusting any later build failure.
