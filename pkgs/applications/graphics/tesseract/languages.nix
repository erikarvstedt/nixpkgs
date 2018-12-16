{ stdenv, fetchurl, fetchFromGitHub }:

rec {
  makeLanguages = { tessdataRev, tessdata ? null, all ? null, languages ? {} }:
    let
      tessdataSrc = fetchFromGitHub {
        owner = "tesseract-ocr";
        repo = "tessdata";
        rev = tessdataRev;
        sha256 = tessdata;
      };

      languageFile = lang: sha256: fetchurl {
        url = "https://github.com/tesseract-ocr/tessdata/raw/${tessdataRev}/${lang}.traineddata";
        inherit sha256;
      };
    in
      {
        all = stdenv.mkDerivation {
          name = "all";
          buildCommand = ''
            mkdir $out
            cd ${tessdataSrc}
            cp *.traineddata $out
          '';
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = all;
        };
      } // (builtins.mapAttrs languageFile languages);

  v3 = makeLanguages {
    tessdataRev = "3cf1e2df1fe1d1da29295c9ef0983796c7958b7d";
    tessdata = "1v4b63v5nzcxr2y3635r19l7lj5smjmc9vfk0wmxlryxncb4vpg7";
    all = "0yj6h9n6h0kzzcqsn3z87vsi8pa60szp0yiayb0znd0v9my0dqhn";

    # Use the helper script ./get-language-hashes.sh to generate these hashes
    languages = {
      ara = "0nk495gki6jbbnwcl2ybsx4nd02d6qykcjncq0d2g8pbgapqmj91";
      ben = "0q7812kn5xjm47hcgdcg911lhbgqr7hbvqckfxxm8qw0yjx2cy0m";
      ces = "0zxkkyhpd74i6321nv86pkjb0k7p9cp6m174rbn42nl7jz6qxib0";
      chi_sim = "0k250xr0gk9yh22yqxd0zpxdsrqfzs164kdv5n9rxx1g996yffij";
      chi_tra = "03nxqpd546p0gwfj6pqzbdbv5zjpdddzlpa10xn4nvmks1mmckbp";
      dan = "1s1yj56rpzmif3ir3qs4iab744cgpflk7y8812z2665bh61illpr";
      deu = "0fna7fqk1a8ivd7q2k38vx37qm3vbn183zh4z5zfqb4pgqmb8znb";
      eng = "0vghah8kqcv0n5fnjb88w6siz156ysrc41fckw3f2y8c3sgmqlf0";
      fin = "1wac333k0lcd5jwprzg99b10bq8sdc96b9d6275kg9imyqjwcc7q";
      fra = "1ax7i0nw1lwkz4sbrvn4z0lcrcai77ymdpla7qk7yij6s4xb5bw6";
      guj = "0dp8mlxmf0x9wb8dg0c508sdwz03icq94z8ji8jhwgdqgv8hw1al";
      heb = "16za9ff1i3ya6hz75l9v3v7j4039kscxxw21g3i2w5p9zn52hyag";
      hrv = "15rqd6xiv2bdmalb5s6rxvw0yk6w9agn9fli3bvi703q6vpj2yn3";
      hun = "19zzwdxwi3h3vdsgr271i1m87gfpdirk6b1ljw2j8qmfilp4sw56";
      ita = "1lxklk3zc3x3k8yfpp6ygyv7fndgs57dfasc97rh8782ds16wkjs";
      jpn = "1wmayj8wh3pfwznjhalad2qzv38mhrzw2sxl71mycvzvpdy9ag1w";
      nld = "1clwbky71zkz55zd3f8r9hj8fhpnbkply80p1js4fvs7x12r715x";
      nor = "1ynvrz6s0vmlq1xkjd8k2w6bx8770x6v29qgx83d4nl17ngjd459";
      pan = "1fwdpwkydfmr6drwgkqzn89z12r2rdm02a75vvdxhxg2a9yiwmbv";
      pol = "155z870ygzws476kp7qpzi8jcjcv3jb5px8rbzhnag1fklqr48hx";
      por = "1814cff2rffpzlg4hyyrjzpf5ps2i95rmpa4c8ikblbvrlcv97q8";
      ron = "11lr80zhvnnngvwwk01z1d3prfpbh3qbwpl1nl5fp7h09d6n3wzl";
      rus = "1d6a8lg4bmd3np16jds1py3qpkaq4ahnhwghd5r0159y0jpxq00q";
      spa = "1npgl8ylvfm60hd4214z8a3lriy1hckhijschrbjpzmwdfcqafgj";
      swe = "0l10iyn2cr7ibgk0akmpg8725mpwpydawgv3s77izsw7y6xhfr1a";
      tur = "0xqnq99b2jb4v74bj95py6wmg14dm31zp5s3l48dmcv6zdgcxg2w";
      ukr = "0cdwjnfnnmzz7jdn49l96vqgaimclfxcxaw09cm63f5my382r2rg";
    };
  };
}
