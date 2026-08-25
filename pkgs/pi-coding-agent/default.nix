{ lib, buildNpmPackage, fetchurl, runCommand, gnutar, jq }:

let
  version = "0.84.3";
  tarball = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha512-Yr2p9PubrbFZmYEPYI+C8KmZP9xlFuLDnAG64RtU0ZDgrdiXYWa+y7WGyJO5OlqPliOkVCMd9IzVszO3/t0D0w==";
  };
  # The published npm-shrinkwrap.json is missing "integrity" for the
  # @earendil-works/* workspace packages; patched copy adds it back
  # (fetched from the registry) so fetchNpmDeps can verify downloads.
  src = runCommand "pi-coding-agent-src-${version}" { nativeBuildInputs = [ gnutar ]; } ''
    mkdir -p $out
    tar -xzf ${tarball} -C $out --strip-components=1
    cp ${./npm-shrinkwrap.json} $out/npm-shrinkwrap.json
  '';
in
buildNpmPackage {
  pname = "pi-coding-agent";
  inherit version src;

  npmDepsHash = "sha256-i+8Sb1mmULN0jfkg6NktVPLUjKWHoTXZmPEB3nrK670=";

  nativeBuildInputs = [ jq ];

  # The shrinkwrap omits devDependencies, but package.json still lists them;
  # npm ci tries to reconcile the two and hits the network. Strip them
  # before npmConfigHook's npm ci runs.
  prePatch = ''
    ${jq}/bin/jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  dontNpmBuild = true;

  meta = {
    description = "Pi coding agent CLI";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
