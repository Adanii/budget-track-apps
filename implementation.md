# Implementation Plan — FinTrack
**Aplikasi Pencatatan Keuangan Pribadi**

> **Tech Stack:** Flutter · Firebase Firestore · Deploy: Web + Android
> **UI Style:** Dark theme · Sage green accent · Elegant minimalist · Vibe coding aesthetic
> **Auth:** Tidak ada autentikasi

---

## 1. Overview Proyek

FinTrack adalah aplikasi pencatatan keuangan sederhana yang memungkinkan satu atau lebih pengguna (tanpa login) mencatat pemasukan dan pengeluaran harian. Data disimpan di Firebase Firestore dan dapat diakses via browser maupun Android.

---

## 2. Fitur Utama

| Field | Keterangan |
|---|---|
| `person` | Siapa yang memasukkan / mengeluarkan uang (dropdown atau free text) |
| `date` | Tanggal transaksi (date picker) |
| `amount` | Nominal transaksi |
| `expense_type` | Auto-kategorisasi: **Pengeluaran Kecil** < Rp 200.000 / **Pengeluaran Besar** ≥ Rp 200.000 |
| `transaction_type` | Jenis transaksi: Pemasukan / Pengeluaran |
| `payment_method` | Metode: Cash · QR · Debit |
| `balance` | Saldo berjalan (dihitung otomatis) |
| `month` | Bulan transaksi berjalan (auto-fill dari tanggal) |

---

## 3. Arsitektur & Struktur Proyek

```
fintrack/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme.dart
│   │   ├── constants.dart
│   │   └── extensions.dart          # CurrencyFormatter, DateFormatter
│   ├── models/
│   │   └── transaction_model.dart
│   ├── services/
│   │   └── firestore_service.dart
│   ├── providers/
│   │   ├── transaction_provider.dart
│   │   └── form_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── add_transaction_screen.dart
│   │   └── history_screen.dart
│   └── widgets/
│       ├── transaction_card.dart
│       ├── balance_header.dart
│       ├── month_chip.dart
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── loading_shimmer.dart      # Skeleton loading cards
│       ├── snackbar_helper.dart      # Success / error / warning / info snackbar
│       ├── confirm_dialog.dart       # Dialog konfirmasi delete
│       └── connectivity_banner.dart  # Banner offline/online
├── pubspec.yaml
└── firebase_options.dart
```

---

## 4. Data Model — Firestore

**Collection:** `transactions`

```json
{
  "id": "auto-generated",
  "person": "Budi",
  "date": "2025-05-09T10:30:00Z",
  "amount": 150000,
  "transaction_type": "expense",
  "expense_type": "small_expense",
  "payment_method": "qr",
  "note": "Makan siang",
  "month": "2025-05",
  "balance_after": 2850000,
  "created_at": "timestamp"
}
```

**Firestore Rules:**
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /transactions/{id} {
      allow read, write: if true;
    }
  }
}
```

---

## 5. Logic Bisnis

### Auto-kategorisasi Pengeluaran
```dart
String getExpenseType(int amount, String transactionType) {
  if (transactionType == 'income') return 'none';
  return amount < 200000 ? 'small_expense' : 'large_expense';
}
```

### Kalkulasi Saldo (Running Balance)
```dart
Future<int> getLatestBalance() async {
  final snapshot = await firestore
    .collection('transactions')
    .orderBy('created_at', descending: true)
    .limit(1)
    .get();
  return snapshot.docs.isEmpty ? 0 : snapshot.docs.first['balance_after'];
}
```

### Filter Bulan Berjalan
```dart
Stream<List<Transaction>> getMonthlyTransactions(String month) {
  return firestore
    .collection('transactions')
    .where('month', isEqualTo: month)
    .orderBy('date', descending: true)
    .snapshots();
}
```

---

## 6. UI / UX Spec

### Color Palette
```dart
const sagePrimary    = Color(0xFF8FAF8A);
const sageDark       = Color(0xFF5C7A57);
const sageLight      = Color(0xFFC8DCC5);
const backgroundDark = Color(0xFF121212);
const surfaceDark    = Color(0xFF1E1E1E);
const cardDark       = Color(0xFF252525);
const textPrimary    = Color(0xFFF0F0F0);
const textSecondary  = Color(0xFF9E9E9E);
const incomeGreen    = Color(0xFF66BB6A);
const expenseRed     = Color(0xFFEF5350);
const warningAmber   = Color(0xFFFFB300);
const shimmerBase    = Color(0xFF2A2A2A);
const shimmerHigh    = Color(0xFF3A3A3A);
```

---

## 7. Screen Breakdown

### 7.1 Home Screen

**Layout:**
- `AppBar` minimal — judul "FinTrack" + icon history kanan
- `BalanceHeader` — saldo total bulan berjalan (large text sage), subtitle nama bulan aktif
- Summary row — 2 card: Total Pemasukan (hijau) | Total Pengeluaran (merah)
- List transaksi real-time via `StreamBuilder`
- `FAB` tombol tambah transaksi, bottom-right

**State yang wajib dihandle:**

| State | Tampilan |
|---|---|
| **Loading awal** | `LoadingShimmer` — 5 skeleton card beranimasi shimmer (warna `shimmerBase` → `shimmerHigh`) |
| **Data kosong** | `EmptyState` — icon minimalist, teks "Belum ada transaksi bulan ini", tombol "+ Catat Sekarang" |
| **Data tersedia** | List `TransactionCard` dengan `AnimatedList` (slide-in dari bawah saat item baru masuk) |
| **Error stream** | `ErrorState` — icon warning, pesan error ringkas, tombol "Coba Lagi" yang trigger re-subscribe stream |
| **Offline** | `ConnectivityBanner` di atas list: "Tidak ada koneksi — menampilkan data cache" (amber, auto-dismiss saat online kembali) |

---

### 7.2 Add Transaction Screen

**Layout:**
- Modal bottom sheet atau full screen dengan back button
- Segmented control di atas: **Pemasukan** / **Pengeluaran**
- Form fields dengan animasi transisi label saat focused (border sage)
- Preview label otomatis: "Pengeluaran Kecil 🟢" / "Pengeluaran Besar 🔴" muncul real-time saat user mengetik nominal
- Tombol **Simpan** — disabled (opacity 0.4) jika form belum valid, enabled setelah semua required field terisi

**Fields:**

| Field | Widget | Validasi |
|---|---|---|
| Person | `DropdownButtonFormField` + opsi "Tambah Baru" | Required |
| Tanggal | `InkWell` → `showDatePicker` styled dark | Required, tidak boleh future date |
| Nominal | `TextFormField` dengan currency formatter (Rp) | Required, > 0 |
| Jenis Transaksi | Segmented control | Required |
| Metode Bayar | `ChoiceChip` row: Cash · QR · Debit | Required |
| Catatan | `TextFormField` multiline, opsional | Max 100 char |

**State & Feedback saat submit:**

| State | Tampilan |
|---|---|
| **Validasi gagal (client)** | Inline error merah di bawah field, fade-in animasi. Tombol Simpan shake animation (translateX ±4px, 3x) |
| **Loading simpan** | Tombol Simpan ganti isi jadi `CircularProgressIndicator` sage. Semua field disabled. Overlay tipis gelap di atas form |
| **Berhasil simpan** | Sheet tutup → `SnackbarHelper.success` muncul di home: ikon ✓, "Transaksi berhasil disimpan". Card baru slide-in ke list dengan animasi |
| **Gagal simpan (Firestore error)** | Sheet tetap terbuka → `SnackbarHelper.error`: "Gagal menyimpan. Coba lagi." + tombol Retry di snackbar |
| **Gagal no connection** | Sheet tetap terbuka → Dialog kecil: "Tidak ada koneksi internet. Periksa koneksimu." |

---

### 7.3 History Screen

**Layout:**
- `AppBar` — "Riwayat Transaksi"
- Horizontal scroll `MonthChip` — chip 6 bulan terakhir. Chip aktif: sage solid. Lainnya: outlined sage
- Summary mini bulan dipilih: Pemasukan | Pengeluaran | Selisih (3 chip kecil)
- List transaksi bulan tersebut

**State yang wajib dihandle:**

| State | Tampilan |
|---|---|
| **Loading saat ganti bulan** | Shimmer skeleton replace list lama (300ms min agar tidak flicker) |
| **Bulan kosong** | `EmptyState` spesifik: "Tidak ada transaksi di bulan ini" |
| **Error load** | `ErrorState` dengan tombol Coba Lagi |

---

### 7.4 Transaction Card

```
┌──────────────────────────────────────────────┐
│  👤 Budi          💳 QR           09 Mei 2025 │
│  Makan siang                                  │
│  🟢 Pengeluaran Kecil        - Rp 150.000     │
└──────────────────────────────────────────────┘
```

- Swipe kiri → reveal background merah dengan icon trash → `ConfirmDialog` sebelum delete
- Long press → bottom sheet: Edit / Hapus
- Warna nominal: hijau (pemasukan), merah (pengeluaran)
- Badge metode bayar: chip kecil rounded di kanan atas

---

## 8. Feedback System — Detail Lengkap

### 8.1 Snackbar Helper

```dart
SnackbarHelper.success(context, "Transaksi berhasil disimpan");
SnackbarHelper.error(context, "Gagal menyimpan. Coba lagi.", onRetry: () => _submit());
SnackbarHelper.warning(context, "Nominal tidak boleh kosong");
SnackbarHelper.info(context, "Data sedang disinkronisasi...");
```

**Desain snackbar custom:**
- Background: `cardDark` dengan left border tebal (4px) berwarna sesuai tipe
- Icon kiri: ✓ hijau / ✗ merah / ⚠ amber / ℹ sage
- Teks `textPrimary`, font ringan
- Durasi: 3 detik (success/info), 5 detik (error — ada tombol Retry)
- Posisi: bottom, margin 16px dari tepi
- `borderRadius: 12`, `elevation: 6`

### 8.2 Loading States

**Shimmer Skeleton** — saat data belum tersedia pertama kali:
```dart
// Package: shimmer
Shimmer.fromColors(
  baseColor: shimmerBase,
  highlightColor: shimmerHigh,
  child: TransactionCardSkeleton(), // shape sama persis dengan card asli
)
```

**Inline Button Loading** — saat aksi simpan/hapus sedang proses:
```dart
ElevatedButton(
  onPressed: isLoading ? null : _submit,
  child: isLoading
    ? SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
    : Text("Simpan"),
)
```

**Full overlay loading** — untuk inisialisasi pertama kali:
```dart
Stack(children: [
  MainContent(),
  if (isInitializing)
    Container(
      color: Colors.black54,
      child: Center(child: Column(children: [
        CircularProgressIndicator(color: sagePrimary),
        SizedBox(height: 16),
        Text("Memuat data...", style: TextStyle(color: textSecondary)),
      ])),
    )
])
```

### 8.3 Confirm Dialog

Digunakan sebelum semua aksi destruktif (hapus transaksi):

```dart
showDialog(context, builder: (_) => ConfirmDialog(
  title: "Hapus Transaksi?",
  message: "Transaksi ini akan dihapus permanen dan saldo akan disesuaikan.",
  confirmLabel: "Hapus",
  confirmColor: expenseRed,
  onConfirm: () => _deleteTransaction(id),
));
```

**State dalam dialog:**
- Default: dua tombol — Batal (outlined) / Hapus (merah)
- Loading delete: tombol Hapus → spinner, tombol Batal disabled
- Berhasil: dialog tutup → `SnackbarHelper.success("Transaksi dihapus")`
- Gagal: dialog tetap terbuka → error text merah muncul di dalam dialog + tombol "Coba Lagi"

### 8.4 Form Validation UX

- Validasi `onChanged` untuk nominal → real-time label "Pengeluaran Kecil / Besar" langsung update
- Validasi `onSubmit` untuk semua field wajib
- Error message muncul dengan `AnimatedOpacity` + slide down (bukan langsung snap)
- Field error: border merah, label merah, icon error di suffix
- Saat user mulai edit field yang error → error message langsung clear
- Counter karakter di field catatan: "0 / 100", berubah merah saat mendekati batas

### 8.5 Empty State Widget

```dart
EmptyState(
  icon: Icons.receipt_long_outlined,
  title: "Belum ada transaksi",
  subtitle: "Catat pemasukan atau pengeluaran pertamamu sekarang",
  actionLabel: "+ Catat Sekarang",
  onAction: () => _openAddSheet(context),
)
```

- Icon `textSecondary`, ukuran 64px
- Title `textPrimary`, subtitle `textSecondary`
- Tombol aksi sage outlined
- `actionLabel` dan `onAction` opsional (history screen tidak perlu tombol)

### 8.6 Error State Widget

```dart
ErrorState(
  message: "Gagal memuat data. Periksa koneksi internetmu.",
  onRetry: () => ref.refresh(transactionProvider),
)
```

- Icon `Icons.cloud_off_outlined` berwarna merah muted
- Tombol "Coba Lagi" sage outlined
- Digunakan di semua screen saat stream/future throw error

### 8.7 Connectivity Banner

Dipantau via `connectivity_plus`. Muncul otomatis:

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  height: isOffline ? 40 : 0,
  color: warningAmber.withOpacity(0.15),
  child: Row(children: [
    Icon(Icons.wifi_off, size: 14, color: warningAmber),
    SizedBox(width: 8),
    Text("Tidak ada koneksi — menampilkan data cache",
         style: TextStyle(color: warningAmber, fontSize: 12)),
  ]),
)
```

Saat kembali online → banner collapse animasi + `SnackbarHelper.info("Koneksi pulih, data diperbarui")`

---

## 9. Animasi & Micro-interactions

| Interaksi | Animasi | Durasi |
|---|---|---|
| List item baru masuk | `SlideTransition` dari bawah + `FadeTransition` | 300ms, `easeOut` |
| List item dihapus | `SizeTransition` collapse + `FadeTransition` | 250ms |
| Ganti bulan di History | `CrossFadeState` list lama → baru | 200ms |
| Segmented control switch | `AnimatedContainer` geser indikator | 200ms |
| Tombol Simpan disabled → enabled | `AnimatedOpacity` 0.4 → 1.0 | 200ms |
| Tombol Simpan saat error validasi | Shake translateX ±4px, 3 kali | 300ms |
| Balance header update | `TweenAnimationBuilder` count-up angka | 600ms |
| Bottom sheet buka | `showModalBottomSheet` dengan `isScrollControlled: true` | Native |
| Swipe to delete reveal | `Dismissible` background merah + icon trash, threshold 40% | Native |
| FAB masuk screen | `ScaleTransition` dari 0 → 1 saat screen pertama load | 300ms |
| SnackBar masuk | Slide up dari bawah | Native |
| Nominal label kecil/besar | `AnimatedSwitcher` fade | 200ms |

---

## 10. Phased Implementation

### Phase 1 — Project Setup (Hari 1)
- [ ] `flutter create fintrack`
- [ ] Setup Firebase project (Firestore enabled)
- [ ] `flutterfire configure` → generate `firebase_options.dart`
- [ ] Tambah semua dependencies
- [ ] Setup `theme.dart` lengkap (warna, TextTheme, InputDecorationTheme, ButtonTheme)
- [ ] Buat widget reusable dulu: `SnackbarHelper`, `EmptyState`, `ErrorState`, `ConfirmDialog`, `LoadingShimmer`, `ConnectivityBanner`

### Phase 2 — Data Layer (Hari 2)
- [ ] Buat `TransactionModel` dengan `fromJson` / `toJson`
- [ ] Buat `FirestoreService` — CRUD + getLatestBalance + stream per bulan
- [ ] Buat `TransactionProvider` + `FormProvider`
- [ ] Unit test logic `getExpenseType` dan kalkulasi saldo

### Phase 3 — UI Core (Hari 3–4)
- [ ] `HomeScreen` — semua state: loading shimmer, empty, error, offline banner, data list
- [ ] `AddTransactionScreen` — form lengkap, real-time validation, semua feedback state (loading, sukses, gagal)
- [ ] `HistoryScreen` — month chip, list, semua state per bulan
- [ ] `TransactionCard` — swipe delete, long press menu, animasi masuk/keluar
- [ ] `ConfirmDialog` dengan loading state internal
- [ ] Balance header dengan animasi count-up

### Phase 4 — Polish & Deploy (Hari 5)
- [ ] Responsive layout — mobile / web max-width 480px centered
- [ ] Test manual semua state: loading, empty, error, offline di web dan Android
- [ ] Animasi dan micro-interaction final review
- [ ] `flutter build web` → deploy ke Firebase Hosting
- [ ] `flutter build apk` → Android release APK
- [ ] End-to-end test flow: tambah → lihat di home → history → hapus

---

## 11. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.x.x
  cloud_firestore: ^5.x.x
  flutter_riverpod: ^2.x.x
  intl: ^0.19.x
  go_router: ^14.x.x
  google_fonts: ^6.x.x
  shimmer: ^3.x.x                   # Skeleton loading
  connectivity_plus: ^6.x.x         # Deteksi offline/online
  flutter_animate: ^4.x.x           # Micro-animations helper

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.x.x
```

---

## 12. Yang Bisa Dikurangi / Ditunda ke v2

| Fitur | Rekomendasi |
|---|---|
| Autentikasi | ❌ Skip sesuai requirement |
| Grafik / chart visualisasi | 🔁 Tunda ke v2 |
| Export PDF / Excel | 🔁 Tunda ke v2 |
| Push notification / reminder | ❌ Skip untuk MVP |
| Edit transaksi | 🔁 Bisa ditambah di Phase 3 jika waktu cukup — gunakan form yang sama dengan data pre-filled |
| Pagination infinite scroll | 🔁 Cukup limit 50 per bulan untuk MVP |
| Multi-device sync indicator | 🔁 Firestore real-time sudah handle, indikator visual bisa ditambah di v2 |

---

*Dokumen ini dibuat sebagai brief lengkap untuk agent development. Semua state UI — loading, empty, error, offline, sukses, gagal — wajib diimplementasikan agar UX terasa solid dan production-ready.*
