{ writeTextFile, writeScript, system }:

# A special kind of derivation that is only meant to be consumed by
# nix-shell. This differs from `mkShell` in that it does not use `stdenv`
# (i.e. coreutils)
{
# A list of packages to add to the shell environment
packages ? [ ], ... }@attrs:
derivation ({
  inherit system;

  name = "minimal-nix-shell";

  # Nix checks if attribute `stdenv` exists and sources that.
  # We use it here to setup the pure enviroment and to clear env vars like PATH.
  # Reference: https://github.com/NixOS/nix/blob/94ec9e47030c2a7280503d338f0dca7ad92811f5/src/nix-build/nix-build.cc#L494
  stdenv = writeTextFile {
    name = "setup";
    executable = true;
    destination = "/setup";
    text = ''
      set -e

      # This is needed for `--pure` to work as expected.
      # https://github.com/NixOS/nix/issues/5092
      PATH=

      for p in $packages; do
        export PATH=$p/bin:$PATH
      done
    '';
  };

  # Typically, `mkShell` is not buildable. This has made it difficult to upload
  # the dependency closure to a binary cache. Rather than add a confusing attribute to capture this
  # just make the nix-shell buildable but message to the user that it doesn't make much sense.
  #
  # The builtin `export` dumps all current environment variables,
  # which is where all build input references end up (e.g. $PATH for
  # binaries). By writing this to $out, Nix can find and register
  # them as runtime dependencies (since Nix greps for store paths
  # through $out to find them)
  # https://github.com/NixOS/nixpkgs/pull/95536/files#diff-282a02cc3871874f16401347d8fadc90d59d7ab11f6a99eaa5173c3867e1a160R358
  #
  # For purity you generally don't want to rely on /bin/sh but since this derivation is *strictly* for a nix-shell
  # we can rely on the fact that the underlying system is POSIX compliant.
  builder = writeScript "builder.sh" ''
    #!/bin/sh
    echo
    echo "This derivation is not meant to be built, unless you want to capture the dependency closure.";
    echo
    export > $out
  '';
} // attrs)
