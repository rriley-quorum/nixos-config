{ lib, buildNpmPackage, fetchurl, runCommand, gnutar }:

let
  version = "1.0.47";
  tarball = fetchurl {
    url = "https://registry.npmjs.org/agents-shire/-/agents-shire-${version}.tgz";
    hash = "sha512-b4qvJSO8MBePkLQBqn7BE2NqDAab83hnw6xYRUxQV8T9X6h2+5LQSha3JwxLwj/IWLrBipSNFzt/VdR3jydgrA==";
  };
  src = runCommand "agents-shire-src-${version}" { nativeBuildInputs = [ gnutar ]; } ''
    mkdir -p $out
    tar -xzf ${tarball} -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  pname = "agents-shire";
  inherit version src;

  npmDepsHash = "sha256-59pU8nWwYRlB8A6G3eo10B7CsVGkswLI7zJiuH6k90c=";

  dontNpmBuild = true;

  meta = {
    description = "AI agent orchestration platform";
    homepage = "https://github.com/victor36max/shire";
    license = lib.licenses.mit;
    mainProgram = "shire";
  };
}
