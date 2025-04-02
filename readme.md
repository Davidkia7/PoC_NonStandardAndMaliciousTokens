# PoC: Kerentanan Token pada recoverERC20

### Kerentanan Griefing: Token Non-Standar dan Jahat Mengganggu recoverERC20

#### Deskripsi Singkat
Fungsi `recoverERC20` di kontrak seperti `Platformofmemecoins` gagal menangani token non-standar (tidak memberikan sinyal "ya/tidak") dan token jahat (mengunci setelah satu transfer), menyebabkan token terjebak dan pemulihan tidak berhasil.

#### Rincian
- **Cara Kerja Kerentanan:**
  - Fungsi `recoverERC20` menganggap semua token mengikuti standar ERC-20.
  - **Token Non-Standar**: Tidak mengembalikan sinyal "ya/tidak" (nilai `bool`) saat dipindahkan, menyebabkan error dan kegagalan fungsi.
  - **Token Jahat**: Berhasil pada transfer pertama ke kontrak, lalu memblokir transfer berikutnya dengan sengaja mengeluarkan error (revert).
- **Proses**: 
  - Pemilik mencoba memulihkan token menggunakan `recoverERC20`.
  - Transaksi gagal karena token tidak sesuai harapan atau sengaja diblokir.
- **Hasil Teknis**: Token tetap terjebak di kontrak karena pemulihan tidak bisa dilakukan.

#### Dampak
- **Efek pada Pemilik:**
  - Membuang gas untuk percobaan pemulihan yang selalu gagal.
  - Tidak bisa mengambil token yang terjebak di kontrak.
- **Efek pada Sistem:**
  - Kepercayaan pada fitur pemulihan rusak karena tidak bisa diandalkan.
  - Kontrak jadi kurang berguna dan terasa tidak aman.
- **Sifat Gangguan**: 
  - Tidak ada dana yang dicuri; penyerang tidak untung (griefing).
  - Bisa membuat pemilik takut mencoba memulihkan token lain yang sah.
