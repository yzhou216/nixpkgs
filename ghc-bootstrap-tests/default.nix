# Scratch tests for haskell.compiler.ghc622Bootstrap.  Not part of any PR.
#
#   features            feature tests of the installed compiler (features/run.sh)
#   nofib.SUITE.OPT     nofib of November 2004, SUITE imaginary, spectral or real,
#                       OPT O0, O1 or O2 (nofib/run.sh)
#   selfhost.*          GHC 6.2.2 rebuilt by the installed compiler, twice, and
#                       the three installed trees compared
#   downstream.*        upstream's GHC 6.6 rung (happy 1.16, alex 2.1.0, GHC 6.6)
#                       built with this GHC 6.2.2, happy and GMP
#   upstream.*          upstream's own chain to 6.2.2, on its pinned Nixpkgs, and
#                       its .hc files of stages 2 to 5 compared with these
{
  pkgs ? import ../. { },
}:

let
  inherit (pkgs) lib runCommand runCommandCC;

  ghc = pkgs.haskell.compiler.ghc622Bootstrap;

  upstreamSrc = pkgs.fetchFromGitHub {
    owner = "andreabedini";
    repo = "ghc-bootstrap";
    rev = "436cc10129a2119a9de1389bcdbdae02fb7ed7fb";
    hash = "sha256-F0y262lyEPmBN8Nt+6evb1SYO2ZQ+eIEndGrB2WwrRM=";
  };

  nofibSrc = pkgs.fetchzip {
    url = "https://gitlab.haskell.org/ghc/nofib/-/archive/06ad94c3ad40c36d5a33b091a7a00cb7d2f896c8/nofib-06ad94c3ad40c36d5a33b091a7a00cb7d2f896c8.tar.gz";
    hash = "sha256-qce0eVHn5SFi0Jig4R5um2902FKXFVE8lZ8SvMd4ai0=";
  };

  # GHC 6.2.2's runstdtest, with the settings its Makefile prepends
  runstdtest = runCommand "runstdtest-6.2.2" { } ''
    tar xjf ${ghc.src} ghc-6.2.2/glafp-utils/runstdtest/runstdtest.prl
    {
      echo '$DEFAULT_TMPDIR = "/tmp";'
      echo '$CONTEXT_DIFF = "diff -U3";'
      echo '$RM = "rm -f";'
      # $* was removed from Perl 5.30, and egrep warns on every call
      sed -e 's/^\([[:space:]]*\)\$\* = 1;/\1/' -e 's/`egrep /`grep -E /' ghc-6.2.2/glafp-utils/runstdtest/runstdtest.prl
    } > $out
    ! grep -n '\$\* = 1' $out
  '';

  compare =
    name: a: b:
    runCommand name { } ''
      mkdir $out
      bash ${./compare.sh} ${a} ${b} ${name} | tee $out/report.txt
    '';

  # GHC 6.2.2 built by an installed GHC 6.2.2 rather than by stage 3
  rebuiltBy =
    boot:
    pkgs.callPackage ../pkgs/development/compilers/ghc/bootstrap/6.2.2/inst.nix {
      inherit (ghc) tree happy gmp;
      inherit boot;
      ghc-bootstrap-src = upstreamSrc;
    };
  inst1 = rebuiltBy ghc;
  inst2 = rebuiltBy inst1;

  downstreamScope = (import upstreamSrc { inherit pkgs; }).overrideScope (
    final: prev: {
      ghc622 = ghc;
      inherit (ghc) happy;
      gmp612 = ghc.gmp;
    }
  );

  upstreamGhc622 = (import upstreamSrc { }).ghc622;

  # Stage N's .hc and .hi files here against upstream's
  hcAgainstUpstream =
    n: ours: theirs:
    runCommand "ghc-6.2.2-stage${toString n}-vs-upstream" { } ''
      mkdir $out
      bash ${./compare.sh} ${ours}/stage${toString n} ${theirs}/stage${toString n} stage${toString n} | tee $out/report.txt
    '';
in
{
  features = runCommandCC "ghc-6.2.2-features" { } ''
    bash ${./features/run.sh} ${./features} ${ghc}/bin ${pkgs.haskell.compiler.ghc984Binary}/bin $out
  '';

  nofib = lib.genAttrs [ "imaginary" "spectral" "real" ] (
    suite:
    lib.mapAttrs
      (
        opt: flag:
        runCommandCC "ghc-6.2.2-nofib-${suite}-${opt}" { nativeBuildInputs = [ pkgs.perl ]; } ''
          bash ${./nofib/run.sh} ${nofibSrc} ${./nofib} ${runstdtest} ${ghc}/bin ${suite} ${flag} $out
        ''
      )
      {
        O0 = "-Onot";
        O1 = "-O";
        O2 = "-O2";
      }
  );

  selfhost = {
    inherit inst1 inst2;
    compare01 = compare "ghc-6.2.2-inst-vs-inst1" ghc inst1;
    compare12 = compare "ghc-6.2.2-inst1-vs-inst2" inst1 inst2;
  };

  downstream = {
    inherit (downstreamScope.ghc66) happy116 alex210;
    ghc66 = downstreamScope.ghc66;
  };

  upstream = {
    ghc622 = upstreamGhc622;
    stage2 = hcAgainstUpstream 2 ghc.stage2.hc upstreamGhc622.stage2.hc;
    stage3 = hcAgainstUpstream 3 ghc.stage3.hc upstreamGhc622.stage3.hc;
    stage4 = hcAgainstUpstream 4 ghc.stage4.hc upstreamGhc622.stage4.hc;
    stage5 = hcAgainstUpstream 5 ghc.stage5 upstreamGhc622.stage5;
    inst = compare "ghc-6.2.2-inst-vs-upstream" ghc upstreamGhc622;
  };
}
