{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "1.2.2";
  archs = {
    x86_64-linux = {
      arch = "linux_amd64";
      sha256 = "8140098a51d3b81d5548d1c5e6db1a2d9930e5d141efe2a4bff7d079c4d321e8";
    };
    aarch64-linux = {
      arch = "linux_arm64";
      sha256 = "501f38a1070d4b9b3b6261a86a3c92c4a52366869021560430a4bb0036afd83a";
    };
  };
  platform = archs.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "beads";
  inherit version;

  src = fetchurl {
    url = "https://github.com/gastownhall/beads/releases/download/v${version}/beads_${version}_${platform.arch}.tar.gz";
    sha256 = platform.sha256;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp bd $out/bin/bd
    chmod +x $out/bin/bd
  '';

  meta = {
    description = "Beads - a memory upgrade for your coding agent";
    homepage = "https://github.com/gastownhall/beads";
    license = lib.licenses.mit;
    mainProgram = "bd";
  };
}
