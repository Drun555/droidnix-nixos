{
  autoPatchelfHook,
  expat,
  fetchurl,
  libdrm,
  libx11,
  libxcb,
  libxext,
  libxshmfence,
  libxxf86vm,
  lm_sensors,
  llvmPackages_19,
  stdenv,
  stdenvNoCC,
  wayland,
  zlib,
  zstd,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mesa-for-android-container";
  version = "26.2.0-devel-20260709";

  src = fetchurl {
    url = "https://github.com/lfdevs/mesa-for-android-container/releases/download/mesa-${finalAttrs.version}/mesa-for-android-container_${finalAttrs.version}_debian_trixie_arm64.tar.gz";
    hash = "sha256-TuUltIRPsYnzdi/3Xvd/W4Du6PbNqy5ViHMbXJ+BaLs=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    expat
    libdrm
    libx11
    libxcb
    libxext
    libxshmfence
    libxxf86vm
    lm_sensors
    llvmPackages_19.libllvm
    stdenv.cc.cc.lib
    wayland
    zlib
    zstd
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib" "$out/share"
    cp -a usr/lib/aarch64-linux-gnu/. "$out/lib/"
    cp -a usr/share/. "$out/share/"

    substituteInPlace "$out/share/vulkan/icd.d/freedreno_icd.aarch64.json" \
      --replace-fail "/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
                     "$out/lib/libvulkan_freedreno.so"

    runHook postInstall
  '';

  meta = {
    description = "Mesa Turnip/Freedreno build patched for Android containers";
    homepage = "https://github.com/lfdevs/mesa-for-android-container";
    platforms = [ "aarch64-linux" ];
  };
})
