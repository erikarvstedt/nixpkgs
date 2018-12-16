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

    # Run `./get-language-hashes.sh <tessdataRev>` to generate these hashes
    languages = {
      afr = "15dsnzy4i9ai26ilm73gkfj4ck039raa88i6w443c4b1fnay2akf";
      amh = "1wbcsdq3svxga3j1alk61xs72a9fhsfsyjxhp3cwxfaqfhrzg7h4";
      ara = "0nk495gki6jbbnwcl2ybsx4nd02d6qykcjncq0d2g8pbgapqmj91";
      asm = "0c3wq15yphq7x74s2sn3f90k6z1cf5j7ic62z0dynidrv99bddfh";
      aze = "0pz073hxqkx1a1cshlgg5k11lj73s52sdxa7k3020drc314lhaxw";
      aze_cyrl = "0djbfgx28ykcjsn2p0766qrmj256g7vhc7valc3ivsva8b906lxq";
      bel = "04zqy8vik0fcakq6apfp8wjhkkhlg0yn9kmag1lk7s8fy9ax3ws2";
      ben = "0q7812kn5xjm47hcgdcg911lhbgqr7hbvqckfxxm8qw0yjx2cy0m";
      bod = "0rwq7539zzfs8xs0bf1535z1cwkm0yk1ni25f5gjav7nm6qpiaan";
      bos = "1qr04dj7lx347gxpin5nfprbggmxq2mwx8kf3pcc3vb5x3pa57g4";
      bul = "0cyyqgi3i4y9bfzwls0lwljzgd0r8ayfqb4bbvdh4qmbni9x42ya";
      cat = "0kgw8f5pdw9lfbn6cfp5n1s0j8pj3418yx6rsbagzcf1gr36gbr9";
      ceb = "1g1n4np4vhar7wfwx2km5k6kldb600rrl7npfbf75229rar068f1";
      ces = "0zxkkyhpd74i6321nv86pkjb0k7p9cp6m174rbn42nl7jz6qxib0";
      chi_sim = "0k250xr0gk9yh22yqxd0zpxdsrqfzs164kdv5n9rxx1g996yffij";
      chi_tra = "03nxqpd546p0gwfj6pqzbdbv5zjpdddzlpa10xn4nvmks1mmckbp";
      chr = "1k1sg3hap0kd5aa36ysvmhp7r3fynxf0f7lzz814h6p3g250zclb";
      cym = "0d6wbf9cmrrzf66mhcckwdfy3xh2i38r0by9nk6isw9rl7bf7j07";
      dan = "1s1yj56rpzmif3ir3qs4iab744cgpflk7y8812z2665bh61illpr";
      dan_frak = "1bxi53ymib5g0139vfd2pflh7nl5925vqznq3sfgaqx7gdx630vi";
      deu = "0fna7fqk1a8ivd7q2k38vx37qm3vbn183zh4z5zfqb4pgqmb8znb";
      deu_frak = "1y4krkvarg7jxhcq49fgybg4phbn58y9c0z2bm8mnp28jkih1cnb";
      dzo = "1fcz0imi7zxi99762pxfcm5iz2jcbqj3s742magka4ihrxnz07xm";
      ell = "0r0f71jy4y29bg055qvvy93wchi3lh08zz0k9c8l7466b03yvq5v";
      eng = "0vghah8kqcv0n5fnjb88w6siz156ysrc41fckw3f2y8c3sgmqlf0";
      enm = "10y61xv3w1ypgqz5rgb22y5hh1i4zx03cwiqw21ifqvg4xdrln46";
      epo = "1y5lh55mbcx33cm7qlf1dcah8ffycxmlcpzjzx9r6ij14fdd4964";
      equ = "1nqrd0a9jqqh6byy8snfhad1hisrc92dcx44wsy7v4nf40j3mx1s";
      est = "12ll8lq1hjcsq9hh93020w78r7f1rcxcwlvrjqw8j5p3k9jg5a4g";
      eus = "034s9mp7lw1a4yvf2cmbbj2fbqbaq6xnjqh30yn0wq0c0jck96nw";
      fas = "0m61p4byc0kzf75cdn6g18s8hcg9r8ifs34wr85lbsb65kil4ijx";
      fin = "1wac333k0lcd5jwprzg99b10bq8sdc96b9d6275kg9imyqjwcc7q";
      fra = "1ax7i0nw1lwkz4sbrvn4z0lcrcai77ymdpla7qk7yij6s4xb5bw6";
      frk = "16nmr71p93724vk1x5mq4r8vxpwnm448p6dwqv8scg8asch1cidp";
      frm = "00yz3hz7wcralq8wbx1ap4c6b37ac6vnz5bgmxmgdx0kqzibiddn";
      gle = "1n8z8kmn5m628rlzgz5v0iw6h46aalflq5asa1wj5rygx1y2azpa";
      glg = "0fdniayplc3iwmlmvhblarh1gm97dp8rqhhkb8b0clwfd9cj342z";
      grc = "04r2193qcxqyab5998xn8bf7197wiccmjm7iakij8d0c7l61dnxb";
      guj = "0dp8mlxmf0x9wb8dg0c508sdwz03icq94z8ji8jhwgdqgv8hw1al";
      hat = "0793mmlxbb09c8103jhdvlczz647nyn4ykkgd3gwgavncmjh72v8";
      heb = "16za9ff1i3ya6hz75l9v3v7j4039kscxxw21g3i2w5p9zn52hyag";
      hin = "1vnn5wpc724kgib8jbx0kpnnp4al60ivqir72gnbyh6cpnflb6bf";
      hrv = "15rqd6xiv2bdmalb5s6rxvw0yk6w9agn9fli3bvi703q6vpj2yn3";
      hun = "19zzwdxwi3h3vdsgr271i1m87gfpdirk6b1ljw2j8qmfilp4sw56";
      iku = "1v1yvc1194qycjgb4ihh5hpj6472nlbp66dii183514g2dh9x0db";
      ind = "120d4b41wvsgcd1sgy2mp78i9hvi7w03a63078dz1yds0yqdwf1p";
      isl = "003ngk8dfv6dglkq8pmi6jsglrfkc65js5ywh3vvkg7qfqf6qsxz";
      ita = "1lxklk3zc3x3k8yfpp6ygyv7fndgs57dfasc97rh8782ds16wkjs";
      ita_old = "188gby1y51pa1ycyc8y17d16hs5w27yl5ch7xzni98bdjkwbkl1z";
      jav = "1fjyjznjchls5ifbnx2b9xagisgxvgj9lsf39rr9d87sbzdbbwbp";
      jpn = "1wmayj8wh3pfwznjhalad2qzv38mhrzw2sxl71mycvzvpdy9ag1w";
      kan = "0hak4953whw9vd9dzl0hq076kzb19kk45kmfxk03af4k6gb206vg";
      kat = "16k0057cvvdc6snm5svhdv3cr7cw71g74yy8215njjbsi838imi3";
      kat_old = "02gl755d38plyvzwfjqxvjgfqkbjs9rvzx33qfhm2zvmgbwrfrfh";
      kaz = "0hc36w7zz5waycsk220v0r83sg991gd5f5r937mvz44viql80sgm";
      khm = "1gb2nv5qdq5fz9w9xq4fj68p46b62sd1m986ra5qbnskxqizr12s";
      kir = "1b1ing6qqi8qqfh4xpk76rp4gxp69wdjdl5m777ayx3v02d7nhh3";
      kor = "1rldj6f8h1nn5wpx57b0ci7p0fnivnwzgaf0d3576xls26z2wcgv";
      kur = "1cp2pfd6g662gvxi7ywkxfbfq1lwbis888bf1gg8ynzy342mx1ic";
      lao = "03bdaxakmxpbbr9vsnbzzfksvm6js0l5i0ijwl71piqyxqjj1gxf";
      lat = "1q7v7drnwpna9k2l79jbdlxiv1j617rqzjc9d48h3lfrma5z97sj";
      lav = "0fxzyvw7n67rmw2irvlghkf1bii4w47200zv26p0v3a9dwvhc7sg";
      lit = "0f00ggjjqrl94kwwjmjqwajyfprsml0br8vhn2gvn11gaxvm52hm";
      mal = "1i83plhin3m6sq8p92vzlyng5z59gvvqypyh7rnmvdmm9rranx8a";
      mar = "0ay7q53yl3709crvn5l9c9jx7hw6m5d3x2crmvnvczsh83ayfdik";
      mkd = "1q1wadcr4j1dzssyyqz43qmizc6vfqkbivr6xi2p7p4h9rl11x73";
      mlt = "1qp4v6habak1l7xrw322wglvjjndrfp4j7bj8d4npwbzk1sh4s0h";
      msa = "048p6mkx9zr40s9s5vbi0gnizhvqwn0g8i1hf1l8db7igbax5xyj";
      mya = "17nyr5bd42kzvid3421n3mwckd49vzrjhjahd8rnfsmbsy1x382l";
      nep = "154375r32sdmvcnp1ckvgbp3wxvb2xiiypb8bxbsvrabrz4wzjqc";
      nld = "1clwbky71zkz55zd3f8r9hj8fhpnbkply80p1js4fvs7x12r715x";
      nor = "1ynvrz6s0vmlq1xkjd8k2w6bx8770x6v29qgx83d4nl17ngjd459";
      ori = "0dsakc8gnwhs6z5kxc2wdkbn31gkkiqk5vriw0swghychp164aac";
      osd = "1zq0dfliavglmix7zzrqdxz1w01rm1f1x1352bqn8xf4zivdbxcw";
      pan = "1fwdpwkydfmr6drwgkqzn89z12r2rdm02a75vvdxhxg2a9yiwmbv";
      pol = "155z870ygzws476kp7qpzi8jcjcv3jb5px8rbzhnag1fklqr48hx";
      por = "1814cff2rffpzlg4hyyrjzpf5ps2i95rmpa4c8ikblbvrlcv97q8";
      pus = "1iz5nn1zfvn1l9gb1jriwx991d2hwwc7x4k1nvzjlwpzscplx25b";
      ron = "11lr80zhvnnngvwwk01z1d3prfpbh3qbwpl1nl5fp7h09d6n3wzl";
      rus = "1d6a8lg4bmd3np16jds1py3qpkaq4ahnhwghd5r0159y0jpxq00q";
      san = "169f4ajgwn99yfdfrlwfvdgvv1abal7fpdp31sknvq8l7w2sak3g";
      sin = "1411g18r6f6j6f4n0sn7ajgs4gkplb892s6ak0hi9nyyxwv3r1gm";
      slk = "0bxfbrg1nf6px0xzkh6ihdi71fmr1rxxs99qb191k7pm16x2lpds";
      slk_frak = "0zyqnn1y5cyx1y7wzgw743k4584ljl0rhvk2q1ni6jnjx9ciwzqy";
      slv = "1kjn9m9hbwp0m0p2v8c3skpzr6f8x42hz8x48zl22550a7hq8n1h";
      spa = "1npgl8ylvfm60hd4214z8a3lriy1hckhijschrbjpzmwdfcqafgj";
      spa_old = "0w4ivkv8flyn7bjlyjcrcrdnslkvrrfs7l33mvird1jhhkyqd8sx";
      sqi = "15wzvh6qm3yx7yf0k5j7g1imsaqxvq7r2xh6a0xgmkqbyypbbkdf";
      srp = "05blqriv30x02c80ds3x7zhw0y21nc6lkqlv5jwgwnjgw4yfpgrm";
      srp_latn = "0ss8s3q60aq8sd2a3sbnzvp13qqarxnjw4hij8hd9ab5gsjw0nwr";
      swa = "1pwwhx7ldq21cv06cchws8gvwsmkwn5sjcy9z3nk3nbp9qjsf44f";
      swe = "0l10iyn2cr7ibgk0akmpg8725mpwpydawgv3s77izsw7y6xhfr1a";
      syr = "08bxil13wyp5h4hvbxjcys7ypgqgg46rrp653m7gyv5q94ycjgb0";
      tam = "1g155kyba2wjfgzgy48g6yd2csinwbfjdi5r7vw0wm3dh1z39dvz";
      tel = "0fydrcb54b6mmqazb337x4s36i2a64sb4xm7y7g3nqqmk9afsipv";
      tgk = "0f6j37friywj7y132fv0jm6aj4sx8f0b7brspj3pbjqqpi4v5ws0";
      tgl = "0f1r0gicif57qhyw8xaa1sqgny720q3z5cpd5srrn9i6fihaz577";
      tha = "1y2hw55jfpidk95y8qbsiczgg2r2khabac97s1y3gl0v93a44jna";
      tir = "1y7iryhjr83ca4yh5jjz7qlnrx4kbrp0a0p650whjvk2gnv8m98h";
      tur = "0xqnq99b2jb4v74bj95py6wmg14dm31zp5s3l48dmcv6zdgcxg2w";
      uig = "1sdddr15zlb33kd1d7hzi5lfd15bfhqn105d7x6snfpqp7vq4bxv";
      ukr = "0cdwjnfnnmzz7jdn49l96vqgaimclfxcxaw09cm63f5my382r2rg";
      urd = "10xcn1zs2lfswp5yai0ckyg7js587qhr5cf7qib3i35qjbw7nc18";
      uzb = "1jkkd5j6vsx5jv5gwprbfwg1vwh714prm8j446wzvp74brmk949l";
      uzb_cyrl = "1kdia38rgm2qd3ly80a412jyagxxryr09h1nz2d0iw71bmfn4855";
      vie = "1ja18jxxaw282y4jljxpjf1gj15il61vc2ykpfy22vn88wvydxff";
      yid = "1jddd0g8mm5v00z5kb8rbpfs7ppzgq9kzm1xlhhvv960yfdbi6fd";
    };
  };
}
