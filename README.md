# E-Commerce Sales & Customer Analysis dengan SQL

Analisis data e-commerce Olist (Brasil) memakai **SQL murni (SQLite)** untuk menjawab pertanyaan bisnis tentang penjualan, pengiriman, dan perilaku pelanggan. Proyek ini adalah lanjutan dari analisis Python/Streamlit pada dataset yang sama, dan hasilnya dipakai untuk memverifikasi angka di analisis tersebut.

- **Author:** Rolly Dhea Venesia Sibuea
- **Tools:** SQL (SQLite), DB Browser for SQLite
- **Dataset:** Olist Brazilian E-Commerce, 99.441 pesanan, 2016-2018
- **Mata uang:** Real Brasil (R$). Revenue dihitung dari harga barang (`price`), **belum termasuk ongkos kirim**.

## Pertanyaan Bisnis

| # | Pertanyaan | Teknik SQL |
|---|---|---|
| 1 | Apakah datanya lengkap dan bisa dipercaya? | COUNT, GROUP BY, HAVING, LEFT JOIN |
| 2 | Berapa total revenue dan nilai rata-rata pesanan? | JOIN 3 tabel, agregasi |
| 3 | Bagaimana tren penjualan bulanan? | CTE, window function `LAG()` |
| 4 | Kategori dan kota apa yang paling berkontribusi? | JOIN 4 tabel, window function `SUM() OVER()` |
| 5 | Apakah keterlambatan pengiriman memengaruhi kepuasan? | CASE WHEN, `julianday()`, JOIN |
| 6 | Seberapa banyak pelanggan yang kembali membeli, dan siapa yang bernilai tinggi? | CTE, `NTILE()`, segmentasi RFM |

## Temuan Utama

**Kualitas data**
- Tidak ada duplikat `order_id`. Tanggal pembelian dan estimasi pengiriman tidak ada yang kosong.
- 775 pesanan tidak punya item: 603 berstatus *unavailable*, 164 *canceled*, sisanya 8 pesanan. Tidak ada yang berstatus *delivered*, jadi analisis revenue tidak terpengaruh.
- Analisis penjualan dan pengiriman difokuskan pada pesanan berstatus *delivered* (96.478 pesanan).

**KPI**
- 96.478 pesanan terkirim dari 93.358 pelanggan unik.
- Total revenue **R$13,22 juta**, nilai rata-rata per pesanan **R$137,04**.

**Tren penjualan**
- Puncak pada **November 2017** (R$987,8 ribu, 7.289 pesanan). Lonjakan ini didorong **Black Friday (24 Nov 2017) dengan 1.147 pesanan dalam sehari**, sekitar 16% dari total pesanan bulan itu.
- Revenue Maret 2018 sekitar 2,7 kali Maret 2017 (+165%). Sejak Maret 2018 revenue mendatar di kisaran R$830-980 ribu per bulan.
- Data 2016 (hanya beberapa pesanan) dan akhir periode tidak dipakai untuk menafsirkan tren. Pertumbuhan MoM dibaca mulai Februari 2017.

**Kategori dan kota**
- Revenue tersebar: kategori teratas *health_beauty* hanya 9,33%. Sepuluh kategori teratas menyumbang 62,4%.
- *bed_bath_table* terjual paling banyak (10.953 item) tetapi peringkat ketiga di revenue, sedangkan *watches_gifts* unggul karena harga per item lebih tinggi.
- São Paulo menyumbang sekitar 15,6% pesanan terkirim. Sepuluh kota teratas menyumbang sekitar 35,1%, dan 4 di antaranya berada di negara bagian SP.

**Pengiriman dan kepuasan**
- Persentase terlambat: 6,63% (2017) dan 9,37% (2018). Rata-rata durasi kirim membaik (13,03 menjadi 12,14 hari), tetapi persentase terlambat naik.
- Rata-rata review pesanan terlambat **2,57** vs **4,29** untuk pesanan tepat waktu. Ini keterkaitan, **bukan bukti sebab-akibat**.
- Keterlambatan tertinggi di MA (19,67%), CE (15,32%), dan BA (14,04%). RJ (13,47%) menonjol karena volumenya besar (12.350 pesanan).

**Pelanggan**
- **Repeat rate hanya 3,0%**: 90.557 dari 93.358 pelanggan hanya membeli sekali.
- Dua segmen belanja tinggi (*Big Spender Baru* dan *At Risk*) menyumbang sekitar 78% revenue (perkiraan dari jumlah pelanggan dikali rata-rata belanja).
- 22.046 pelanggan belanja tinggi (*At Risk*) terakhir membeli sekitar 413 hari sebelum akhir data.

## Segmentasi RFM

Definisi segmen dibuat sendiri (bukan standar baku), berdasarkan pesanan *delivered*:

| Komponen | Aturan |
|---|---|
| Recency (R) | `NTILE(4)` dari tanggal pesanan terakhir; 4 = paling baru |
| Frequency (F) | 3 jika ≥ 3 pesanan, 2 jika 2 pesanan, 1 jika 1 pesanan |
| Monetary (M) | `NTILE(4)` dari total belanja; 4 = terbesar |

| Segmen | Aturan | Pelanggan | Rata-rata belanja |
|---|---|---|---|
| Champions | R ≥ 3, F ≥ 2, M ≥ 3 | 1.310 | R$300,23 |
| Loyal / Repeat | F ≥ 2 (di luar Champions) | 1.491 | R$224,75 |
| Big Spender Baru | R ≥ 3, M ≥ 3 | 22.289 | R$231,63 |
| At Risk (Big Spender) | R ≤ 2, M ≥ 3 | 22.046 | R$233,71 |
| Pelanggan Baru | R ≥ 3 | 22.846 | R$47,02 |
| Hibernating | lainnya | 23.376 | R$47,22 |

Karena 97% pelanggan hanya membeli sekali, skor frekuensi hampir seragam, sehingga segmen lebih banyak dibedakan oleh kebaruan dan nilai belanja.

## Rekomendasi

1. Siapkan stok, gudang, dan logistik ekstra menjelang periode promosi seperti Black Friday.
2. Prioritaskan perbaikan logistik di RJ (dampak terbesar) dan wilayah timur laut (MA, CE, BA), serta tinjau cara estimasi pengiriman dihitung.
3. Jalankan kampanye *win-back* untuk segmen *At Risk*, dan dorong pembelian kedua dari *Big Spender Baru*.
4. Pantau persentase pesanan terlambat dan repeat rate sebagai KPI rutin.

## Keterbatasan

- Revenue bukan profit, dan tidak termasuk ongkos kirim, sehingga tidak bisa dipakai untuk menyimpulkan kategori mana yang paling menguntungkan.
- "Terlambat" didefinisikan sebagai tanggal diterima setelah tanggal estimasi.
- Hubungan keterlambatan dengan review score adalah keterkaitan, bukan sebab-akibat.
- Segmen RFM, terutama *At Risk*, adalah perkiraan berbasis aturan buatan sendiri.
- Query cohort retention (bagian 6.2 pada file SQL) tersedia, tetapi hasilnya belum dianalisis di README ini.

## Struktur Repository

```
├── olist_sql_analysis_sqlite.sql   # seluruh query, dikelompokkan per bagian
├── screenshots/                    # hasil tiap query
└── README.md
```

## Cara Menjalankan

1. Download `olist.sqlite` dari Kaggle (lihat Sumber Data). File database **tidak** disertakan di repository ini.
2. Buka dengan [DB Browser for SQLite](https://sqlitebrowser.org/) (Open Database).
3. Buka tab **Execute SQL**, tempel query dari `olist_sql_analysis_sqlite.sql` satu per satu, lalu jalankan.

## Sumber Data

- Olist Brazilian E-Commerce Public Dataset (Kaggle): https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- Versi SQLite oleh pengunggah di Kaggle, "E-commerce dataset by Olist (SQLite)" (lisensi CC BY-NC 4.0): **[tempel link halaman dataset di sini]**

Proyek ini dibuat untuk tujuan pembelajaran dan portofolio non-komersial.
