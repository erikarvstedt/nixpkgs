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
        url = "https://github.com/tesseract-ocr/tessdata/blob/${tessdataRev}/${lang}.traineddata";
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
      ara = "089ayqxr3qqfa9vy2llmhp5vycjhafakghn3nlhdd2rf65vkbwvh";
      ben = "1q98z1p7h66fll5js0x3dlbm03chhlsn1929jcbb2ypyiq4n1lzz";
      ces = "1lf01q7p6pvbf5k0iwhxz8k99rqhvbsjgmwslir9ab4d6j9483f8";
      dan = "0r46z6mnmcc3vhd8gdlw1w8bpyrw30zgp5qmdk58h32cib175bd8";
      deu = "1fqma46himg9yp4hkqcixwsbxqahr57wc86xcd7wx29xyizbm472";
      chi_sim = "1g2izs7h0h6n5sy7dccpyd0ykqcfmpjkssgfa1i78pj28cd440i8";
      chi_tra = "1zi54l0l5yj3n9r0fqdpf9ym7fsykqf432pdi726f7m9dyyblg9h";
      eng = "1h1zlg627wa15s1s7i7zk53v3ycq6b8x50ainvb56d0xjdm6d9ma";
      fin = "18zgfc8l9yn8vg726np5ls2k2npf6b19130s7ycjl5ksbiynwm1z";
      fra = "0wbkkxs129vyh516c8wm5wqpgfmfxlcpydip8nbrnlk70fj5ph6x";
      heb = "0rfp7incl5f0r92g1h1cqpxr898vxkyfprh9gh8mikwr0a16iq1b";
      hrv = "0k9j6fwbhpwbvz8kfg4s0h7dymagqcikxll9cw3v1in4qqpvyrv6";
      guj = "01l89b63rp1vyrlm3mn9lmhq4d29s0jf7gnl0ihfhcs53bqapazh";
      hun = "1jsq2zi6awchf03x1186zy0rbzr1dizjn2gga17s666qf07vsi8m";
      ita = "1cg1i9d6dx507gd15zz1c8b04p53v6vr2annlcznfznzjzymk2p4";
      jpn = "00zig78861j8pgfnlwnli7shpak3ywqld48w5cx6mi9bcj5d3vb2";
      nld = "039m7jjadvn2xs8iwq21f9pxz87lcjfm56l3jvq8kv44x6jm3r2j";
      pan = "0331flxkdxmi3x4dw53l61wxl3fa1hab9fdfckn201bzzvs0ydiz";
      nor = "16800lahfvj287pfxx65z2gnjfm604s118rdxca894n9dl86w78f";
      pol = "00nmgirvgw30wqhk70d048v08wsc1kp03w9hxsj6rbl45gklhlna";
      ron = "1brpab2bms7yf7is9rjwz9bhw4mlvlpv5mg8gl4mwayl1myr45hm";
      por = "1fy774ahjsnm0kaq70wsyf7x8gz0gm6slan9swb66s9ph0n5d3kc";
      spa = "07zbywq3mf1yaypnqfk894k2lmhgn9bxc9g6lhligdgwclhh3a3r";
      swe = "1gywdl0dfc6rlyfj9mlpxxi08n9rdlxn9alh4bp2d6dd5gf5fcc0";
      rus = "0bw41d92aj9slnz4713xcgjcwg16dcpyp8ny725nbfj5rl7qvbdz";
      ukr = "007mnyi05myjbx7m4fzvzh3jy1mcy9ac8h2n9cpvwvz03ikhw6rc";
      tur = "0m76w3bz8rkmz0z02szl34wjwv0p8d0s12ri5ax7j7lcb90jg4rj";
    };
  };
}
