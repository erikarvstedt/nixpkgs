{ callPackage, lowPrio }:

let
  tesseract3 = callPackage ./tesseract3.nix {};
  tesseract4 = callPackage ./tesseract4.nix {};
  languages = callPackage ./languages.nix {};
in
{
  tesseract = callPackage ./wrapper.nix {
    tesseractBase = tesseract3;
    languages = languages.v3;
  };

  tesseract4 = lowPrio (callPackage ./wrapper.nix {
    tesseractBase = tesseract4;
    languages = languages.v4;
  });
}
