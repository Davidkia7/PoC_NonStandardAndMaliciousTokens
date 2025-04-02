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

## Cara Menguji (Langkah demi Langkah)
Berikut langkah-langkah untuk menguji kerentanan ini menggunakan [Remix IDE](https://remix.ethereum.org/), alat gratis berbasis browser.

### Apa yang Dibutuhkan
- Peramban web untuk membuka Remix.
- Tidak perlu perangkat lunak tambahan—gunakan lingkungan tes bawaan Remix.

#### 1. Buka Remix dan Tambah File
1. Buka [Remix IDE](https://remix.ethereum.org/).
2. Di panel kiri (File Explorer), klik "+" untuk membuat tiga file:
   - `Platformofmemecoins.sol`
   - `NonStandardToken.sol`
   - `MaliciousToken.sol`
3. Salin dan tempel kode dari masing-masing file di repositori ini ke file yang sesuai di Remix.

#### 2. Siapkan Kontrak Target (Platformofmemecoins)
1. **Kompilasi**:
   - Buka tab "Solidity Compiler" (ikon palu).
   - Pilih versi `0.8.20`.
   - Klik "Compile Platformofmemecoins.sol". Tunggu tanda centang hijau.
2. **Deploy**:
   - Buka tab "Deploy & Run Transactions" (ikon putar).
   - Pilih `Platformofmemecoins` dari dropdown.
   - Isi detail:
     - `name_`: `TestToken`
     - `symbol_`: `TTK`
     - `decimals_`: `18`
     - `initialBalance_`: `1000`
     - `tokenOwner`: Alamat akun Remix Anda (misalnya, `0x5B38...`—salin dari dropdown "Account").
     - `feeReceiver_`: Sama dengan `tokenOwner`.
     - `Value`: Biarkan `0`.
   - Klik **Deploy**.
3. **Cek**:
   - Temukan kontrak di "Deployed Contracts".
   - Klik, lalu panggil `owner()` untuk memastikan itu alamat Anda.
   - Salin alamat kontrak (misalnya, `0xTargetAddress`).

#### 3. Siapkan NonStandardToken
1. **Kompilasi**:
   - Kompilasi `NonStandardToken.sol`.
2. **Deploy**:
   - Pilih `NonStandardToken`.
   - Masukkan `initialSupply`: `1000`.
   - Klik **Deploy**.
3. **Cek**:
   - Panggil `balanceOf` dengan alamat Anda—harus menunjukkan `1000000000000000000000` (1000 token).
   - Salin alamat kontrak (misalnya, `0xNonStandardAddress`).

#### 4. Siapkan MaliciousToken
1. **Kompilasi**:
   - Kompilasi `MaliciousToken.sol`.
2. **Deploy**:
   - Pilih `MaliciousToken`.
   - Masukkan `initialSupply`: `1000`.
   - Klik **Deploy**.
3. **Cek**:
   - Panggil `balanceOf` dengan alamat Anda—harus `1000000000000000000000`.
   - Salin alamat kontrak (misalnya, `0xMaliciousAddress`).

#### 5. Kirim Token ke Platformofmemecoins
- **NonStandardToken**:
  1. Pilih kontrak `NonStandardToken`.
  2. Panggil `transfer`:
     - `recipient`: Tempel `0xTargetAddress`.
     - `amount`: `100000000000000000000` (100 token).
     - Klik **transact**.
  3. Cek: Panggil `balanceOf(0xTargetAddress)`—harus `100000000000000000000`.
- **MaliciousToken**:
  1. Pilih kontrak `MaliciousToken`.
  2. Panggil `transfer`:
     - `recipient`: `0xTargetAddress`.
     - `amount`: `100000000000000000000`.
     - Klik **transact**.
  3. Cek: Panggil `balanceOf(0xTargetAddress)`—harus `100000000000000000000`.

#### 6. Coba Pulihkan Token
- **Gunakan Platformofmemecoins**:
  1. Kembali ke kontrak `Platformofmemecoins`.
  2. Pastikan akun Anda (misalnya, `0x5B38...`) dipilih—itu pemiliknya.
- **Pulihkan NonStandardToken**:
  1. Panggil `recoverERC20`:
     - `tokenAddress`: Tempel `0xNonStandardAddress`.
     - `tokenAmount`: `100000000000000000000`.
     - Klik **transact**.
  2. Lihat panel "Terminal" di bawah—akan ada error seperti `"execution reverted"`.
- **Pulihkan MaliciousToken**:
  1. Panggil `recoverERC20`:
     - `tokenAddress`: `0xMaliciousAddress`.
     - `tokenAmount`: `100000000000000000000`.
     - Klik **transact**.
  2. Cek Terminal—error seperti `"Malicious token: Transfer disabled after initial transfer"`.

#### 7. Lihat Hasilnya
- **NonStandardToken**: Gagal karena tidak ada sinyal "ya/tidak".
- **MaliciousToken**: Gagal karena token memblokir setelah masuk.
- **Cek Lagi**:
  - Panggil `balanceOf(0xTargetAddress)` pada kedua token—token masih ada.
  - Gas Anda (ETH palsu Remix) berkurang, tapi token tidak bergerak.

## Sumber Kerentanan
#### Analisis Mendalam
- **Fungsi `recoverERC20`**:
  - Fungsi ini tidak siap untuk token yang tidak standar atau jahat.
  - Tidak memeriksa saldo sebelum transfer dan tidak menangani error, sehingga gagal saat token bermasalah.
- **Token Non-Standar**:
  - Tidak mengembalikan sinyal "ya/tidak" (`bool`), melanggar standar ERC-20, tapi ini desain token, bukan bug kontrak.
- **Token Jahat**:
  - Sengaja memblokir transfer setelah satu kali, memanfaatkan asumsi `recoverERC20` bahwa semua token baik-baik saja.
- **Kesimpulan**:
  - **Utama**: Kerentanan ada pada `recoverERC20` karena desainnya tidak defensif terhadap token eksternal yang bermasalah.
  - **Pemicu**: Token non-standar dan jahat memperburuk masalah, tapi tidak akan jadi isu jika fungsi lebih kuat.

#### Implikasi
- Pemilik kontrak harus membuat fungsi yang tahan terhadap token aneh atau jahat, yang umum di blockchain.
- Ini adalah "griefing"—gangguan tanpa untung bagi penyerang, tapi merusak kepercayaan.

## Cara Memperbaiki
Ubah `recoverERC20` agar lebih tangguh:
```solidity
function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    require(balance >= tokenAmount, "Not enough tokens");
    (bool success, ) = tokenAddress.call(
        abi.encodeWithSelector(IERC20.transfer.selector, owner(), tokenAmount)
    );
    if (!success) {
        emit RecoveryFailed(tokenAddress, tokenAmount);
    }
}
event RecoveryFailed(address indexed tokenAddress, uint256 amount);
