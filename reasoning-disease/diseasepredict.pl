% Fakta tentang penyakit dan gejalanya (dengan bobot untuk setiap gejala)
penyakit(gasritis, [(bengkak_rahang_atau_pipi, 5), (mulut_luka, 2), (bibir_pecah_pecah, 2)]).
penyakit(maag, [(napas_bau, 3), (muntah, 3)]).
penyakit(tumor_lambung, [(sakit_perut, 3), (diare, 4), (darah_dan_lendir_di_kotoran, 5)]).
penyakit(kanker_lambung, [
    (perut_nyeri_pedih_dan_sesak_diatas_perut, 5),
    (sering_sendawa_terutama_saat_lapar, 2),
    (sulit_tidur_karena_nyeri_uluhati, 4),
    (kehilangan_nafsu_makan, 3)
]).
penyakit(gerd, [(sembelit_lebih_dari_tiga_hari, 4), (mual, 2), (sensasi_terbakar_di_dada, 4)]).

% Fungsi untuk menanyakan gejala dengan jawaban ya/tidak
tanya_gejala(Gejala) :-
    format('Apakah Anda mengalami ~w? (ya/tidak): ', [Gejala]),
    read(Jawaban),
    (Jawaban == ya -> assertz(mengalami_gejala(Gejala)); fail).

% Fungsi untuk menghitung total bobot gejala yang cocok
hitung_bobot_gejala([], _, 0).
hitung_bobot_gejala([(Gejala, Bobot)|Sisa], GejalaDikenal, TotalBobot) :-
    (member(Gejala, GejalaDikenal) -> Bobot1 is Bobot; Bobot1 is 0),
    hitung_bobot_gejala(Sisa, GejalaDikenal, BobotSisa),
    TotalBobot is Bobot1 + BobotSisa.

% Fungsi diagnosis berdasarkan bobot gejala
diagnosis_bobot(Penyakit, Gejala, GejalaDikenal, TotalBobot) :-
    hitung_bobot_gejala(Gejala, GejalaDikenal, TotalBobot),
    TotalBobot > 0, % Hanya menampilkan penyakit jika ada bobot yang cocok
    format('Kemungkinan diagnosis: ~w (total bobot gejala cocok: ~2f)\n', [Penyakit, TotalBobot]).

% Memulai proses diagnosis
mulai_diagnosis :-
    retractall(mengalami_gejala(_)), % Reset gejala sebelumnya
    % Mengumpulkan gejala dari pengguna
    findall(Gejala, (
        penyakit(_, GejalaList),
        member((Gejala, _), GejalaList),
        \+ mengalami_gejala(Gejala),
        tanya_gejala(Gejala)
    ), _),
    % Mengumpulkan gejala yang telah dijawab ya
    findall(G, mengalami_gejala(G), GejalaDikenal),
    % Memproses diagnosis berdasarkan bobot
    findall((Penyakit, TotalBobot), (
        penyakit(Penyakit, GejalaList),
        diagnosis_bobot(Penyakit, GejalaList, GejalaDikenal, TotalBobot)
    ), Hasil),
    % Menentukan penyakit dengan bobot terbesar
    hasil_diagnosis(Hasil).

% Fungsi untuk menemukan semua penyakit dengan bobot terbesar
hasil_diagnosis([]) :-
    write('Tidak ada penyakit yang cocok berdasarkan gejala yang diberikan.\n').
hasil_diagnosis(Hasil) :-
    sort(2, @>=, Hasil, HasilUrut), % Urutkan berdasarkan bobot
    HasilUrut = [(DiagnosisPenyakit, BobotTerbesar)|_], % Ambil penyakit dengan bobot tertinggi
    include(bobot_sama(BobotTerbesar), HasilUrut, PenyakitTertinggi), % Ambil semua penyakit dengan bobot tertinggi
    format('Diagnosis akhir dengan bobot tertinggi (~2f):\n', [BobotTerbesar]),
    forall(member((Penyakit, _), PenyakitTertinggi), format('- ~w\n', [Penyakit])).

% Predicate untuk membandingkan bobot
bobot_sama(Bobot, (_, Bobot)) :- !. % Membandingkan jika bobot sama

% Memulai diagnosis dan mencetak hasil
run :-
    mulai_diagnosis,
    nl.
