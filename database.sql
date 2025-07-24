-- Database Schema untuk Aplikasi Pencatatan Pertanian Hidroponik
-- Created: July 2025

-- ========================================
-- TABEL MASTER DATA
-- ========================================

-- Tabel Pengguna sistem
CREATE TABLE pengguna (
    id_pengguna INT PRIMARY KEY AUTO_INCREMENT,
    nama_pengguna VARCHAR(50) NOT NULL UNIQUE,
    nama_lengkap VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    password_hash VARCHAR(255) NOT NULL,
    peran ENUM('admin', 'operator') DEFAULT 'operator',
    aktif BOOLEAN DEFAULT TRUE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diubah_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel Kategori Pengeluaran
CREATE TABLE kategori_pengeluaran (
    id_kategori INT PRIMARY KEY AUTO_INCREMENT,
    nama_kategori VARCHAR(50) NOT NULL,
    keterangan TEXT,
    aktif BOOLEAN DEFAULT TRUE
);

-- Tabel Master Benih
CREATE TABLE jenis_benih (
    id_benih INT PRIMARY KEY AUTO_INCREMENT,
    nama_benih VARCHAR(100) NOT NULL,
    pemasok VARCHAR(100),
    harga_per_satuan DECIMAL(12,2),
    jenis_satuan VARCHAR(20), -- gram, biji, pack
    ukuran_satuan VARCHAR(50), -- 8 gram, 5000 biji, dll
    aktif BOOLEAN DEFAULT TRUE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel Master Pupuk
CREATE TABLE jenis_pupuk (
    id_pupuk INT PRIMARY KEY AUTO_INCREMENT,
    nama_pupuk VARCHAR(100) NOT NULL,
    kode_pupuk VARCHAR(20), -- CEF, Coklat, Putih
    tipe ENUM('makro', 'mikro', 'organik', 'kimia') DEFAULT 'makro',
    keterangan TEXT,
    aktif BOOLEAN DEFAULT TRUE
);

-- Tabel Master Tandon
CREATE TABLE tandon_air (
    id_tandon INT PRIMARY KEY AUTO_INCREMENT,
    kode_tandon VARCHAR(20) NOT NULL UNIQUE, -- P1, P2, R1, R2, dll
    nama_tandon VARCHAR(100),
    kapasitas DECIMAL(8,2), -- liter
    lokasi VARCHAR(100),
    aktif BOOLEAN DEFAULT TRUE
);

-- Tabel Master Pelanggan
CREATE TABLE pelanggan (
    id_pelanggan INT PRIMARY KEY AUTO_INCREMENT,
    nama_pelanggan VARCHAR(100) NOT NULL,
    jenis_pelanggan ENUM('restoran', 'hotel', 'individu') DEFAULT 'restoran',
    kontak_person VARCHAR(100),
    telepon VARCHAR(20),
    alamat TEXT,
    aktif BOOLEAN DEFAULT TRUE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- TABEL PENCATATAN HARIAN
-- ========================================

-- Pencatatan Penggunaan Pupuk Harian
CREATE TABLE penggunaan_pupuk_harian (
    id_penggunaan INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_pakai DATE NOT NULL,
    id_pupuk INT NOT NULL,
    jumlah_digunakan DECIMAL(8,2) NOT NULL,
    satuan VARCHAR(20), -- kg, liter, gram
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pupuk) REFERENCES jenis_pupuk(id_pupuk),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Pencatatan Penjualan Sayur Harian
CREATE TABLE penjualan_harian (
    id_penjualan INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_jual DATE NOT NULL,
    id_pelanggan INT NOT NULL,
    jenis_sayur VARCHAR(50) NOT NULL, -- selada, romaine, dll
    jumlah DECIMAL(8,2) NOT NULL,
    satuan VARCHAR(20), -- kg, ikat, pcs
    harga_per_satuan DECIMAL(10,2),
    total_harga DECIMAL(12,2),
    status_kirim ENUM('pending', 'terkirim', 'batal') DEFAULT 'pending',
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Pencatatan Pengeluaran Modal
CREATE TABLE pengeluaran_harian (
    id_pengeluaran INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_pengeluaran DATE NOT NULL,
    id_kategori INT NOT NULL,
    keterangan VARCHAR(255) NOT NULL,
    jumlah DECIMAL(12,2) NOT NULL,
    nomor_nota VARCHAR(50),
    pemasok VARCHAR(100),
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_kategori) REFERENCES kategori_pengeluaran(id_kategori),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Monitoring Nutrisi & PPM Harian
CREATE TABLE monitoring_nutrisi_harian (
    id_monitoring INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_monitoring DATE NOT NULL,
    id_tandon INT NOT NULL,
    nilai_ppm DECIMAL(6,2) NOT NULL,
    air_ditambah DECIMAL(8,2), -- liter air yang ditambahkan
    nutrisi_ditambah DECIMAL(8,2), -- ml atau gram nutrisi yang ditambahkan
    tingkat_ph DECIMAL(4,2),
    suhu_air DECIMAL(4,1),
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_tandon) REFERENCES tandon_air(id_tandon),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- ========================================
-- TABEL PENCATATAN TANAMAN & PANEN
-- ========================================

-- Pencatatan Pembenihan (Seed Log)
CREATE TABLE catatan_pembenihan (
    id_pembenihan INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_semai DATE NOT NULL,
    id_benih INT NOT NULL,
    jumlah INT NOT NULL,
    satuan VARCHAR(20), -- tray, hampan
    kode_batch VARCHAR(50), -- untuk tracking
    tanggal_panen_target DATE,
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_benih) REFERENCES jenis_benih(id_benih),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Data Sayur yang Ditanam & Status Panen
CREATE TABLE penanaman_sayur (
    id_penanaman INT PRIMARY KEY AUTO_INCREMENT,
    id_pembenihan INT, -- relasi ke pembenihan
    tanggal_tanam DATE NOT NULL,
    jenis_sayur VARCHAR(50) NOT NULL,
    jumlah_ditanam INT NOT NULL,
    lokasi VARCHAR(100), -- area tanam
    tahap_pertumbuhan ENUM('semai', 'vegetatif', 'siap_panen', 'panen', 'gagal') DEFAULT 'semai',
    tanggal_panen DATE NULL,
    jumlah_dipanen INT DEFAULT 0,
    jumlah_gagal INT DEFAULT 0,
    alasan_gagal TEXT,
    tingkat_keberhasilan DECIMAL(5,2) AS (
        CASE 
            WHEN jumlah_ditanam > 0 THEN (jumlah_dipanen / jumlah_ditanam) * 100
            ELSE 0 
        END
    ) STORED,
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diubah_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pembenihan) REFERENCES catatan_pembenihan(id_pembenihan),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Pencatatan Kebusukan/Gagal Panen Harian
CREATE TABLE kegagalan_panen_harian (
    id_kegagalan INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_gagal DATE NOT NULL,
    id_penanaman INT NOT NULL,
    jumlah_gagal INT NOT NULL,
    jenis_kegagalan ENUM('busuk', 'layu', 'hama', 'penyakit', 'cuaca', 'lainnya') NOT NULL,
    penyebab_gagal TEXT,
    lokasi VARCHAR(100),
    tindakan_diambil TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_penanaman) REFERENCES penanaman_sayur(id_penanaman),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- ========================================
-- TABEL JADWAL & TREATMENT
-- ========================================

-- Jadwal Rotasi Pemupukan Bulanan
CREATE TABLE jadwal_pemupukan_bulanan (
    id_jadwal INT PRIMARY KEY AUTO_INCREMENT,
    bulan_tahun DATE NOT NULL, -- format: YYYY-MM-01
    minggu_ke TINYINT NOT NULL, -- 1-4
    hari_dalam_minggu TINYINT NOT NULL, -- 1=Senin, 2=Selasa, dst
    perlakuan_pupuk TEXT NOT NULL, -- "Pupuk CEF + PTh", "Pupuk Coklat", dll
    perlakuan_tambahan VARCHAR(255), -- HIRACOL, ANTRACOL, Bawang Putih
    catatan TEXT,
    sudah_selesai BOOLEAN DEFAULT FALSE,
    diselesaikan_oleh INT NULL,
    diselesaikan_pada TIMESTAMP NULL,
    dibuat_oleh INT NOT NULL,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (diselesaikan_oleh) REFERENCES pengguna(id_pengguna),
    FOREIGN KEY (dibuat_oleh) REFERENCES pengguna(id_pengguna)
);

-- Pencatatan Treatment yang Dilakukan
CREATE TABLE catatan_perlakuan (
    id_perlakuan INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_perlakuan DATE NOT NULL,
    id_jadwal INT NULL, -- relasi ke jadwal jika ada
    jenis_perlakuan VARCHAR(100) NOT NULL,
    area_tanaman VARCHAR(100),
    bahan_digunakan TEXT, -- pupuk dan bahan yang digunakan
    jumlah_digunakan DECIMAL(8,2),
    satuan VARCHAR(20),
    metode VARCHAR(100), -- cara aplikasi
    kondisi_cuaca VARCHAR(50),
    rating_efektivitas TINYINT, -- 1-5 rating efektivitas
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_jadwal) REFERENCES jadwal_pemupukan_bulanan(id_jadwal),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- ========================================
-- TABEL PEMBELIAN & INVENTORY
-- ========================================

-- Pencatatan Pembelian Benih
CREATE TABLE pembelian_benih (
    id_pembelian INT PRIMARY KEY AUTO_INCREMENT,
    tanggal_beli DATE NOT NULL,
    id_benih INT NOT NULL,
    pemasok VARCHAR(100) NOT NULL,
    jumlah DECIMAL(8,2) NOT NULL,
    satuan VARCHAR(20),
    harga_satuan DECIMAL(10,2) NOT NULL,
    total_harga DECIMAL(12,2) NOT NULL,
    nomor_faktur VARCHAR(50),
    tanggal_kadaluarsa DATE,
    lokasi_penyimpanan VARCHAR(100),
    catatan TEXT,
    dicatat_oleh INT NOT NULL,
    dicatat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_benih) REFERENCES jenis_benih(id_benih),
    FOREIGN KEY (dicatat_oleh) REFERENCES pengguna(id_pengguna)
);

-- ========================================
-- DATA MASTER AWAL
-- ========================================

-- Insert kategori pengeluaran
INSERT INTO kategori_pengeluaran (nama_kategori, keterangan) VALUES
('Listrik', 'Biaya listrik untuk operasional'),
('Bensin', 'Bahan bakar kendaraan dan genset'),
('Benih', 'Pembelian benih sayuran'),
('Rockwool', 'Media tanam rockwool'),
('Pupuk', 'Pembelian pupuk dan nutrisi'),
('Lain-lain', 'Pengeluaran operasional lainnya');

-- Insert jenis pupuk
INSERT INTO jenis_pupuk (nama_pupuk, kode_pupuk, tipe, keterangan) VALUES
('Pupuk CEF', 'CEF', 'makro', 'Pupuk campuran unsur hara makro'),
('Pupuk Coklat', 'COKLAT', 'makro', 'Pupuk makro nutrien warna coklat'),
('Pupuk Putih', 'PUTIH', 'makro', 'Pupuk berbasis nitrogen/fosfor'),
('Pythium Treatment', 'PTH', 'kimia', 'Anti jamur akar Pythium'),
('HIRACOL', 'HIRACOL', 'kimia', 'Fungisida/insektisida'),
('ANTRACOL', 'ANTRACOL', 'kimia', 'Fungisida untuk penyakit tanaman'),
('Bawang Putih', 'BAWANG', 'organik', 'Ekstrak alami anti jamur');

-- Insert tandon air
INSERT INTO tandon_air (kode_tandon, nama_tandon, kapasitas, lokasi) VALUES
('P1', 'Tandon P1', 1000, 'Area Produksi 1'),
('P2', 'Tandon P2', 1000, 'Area Produksi 2'),
('P3', 'Tandon P3', 1000, 'Area Produksi 3'),
('R1', 'Tandon R1', 800, 'Area Romaine 1'),
('R2', 'Tandon R2', 800, 'Area Romaine 2'),
('R3', 'Tandon R3', 800, 'Area Romaine 3'),
('S1', 'Tandon S1', 600, 'Area Semai 1'),
('S2', 'Tandon S2', 600, 'Area Semai 2'),
('S3', 'Tandon S3', 600, 'Area Semai 3'),
('6HA', 'Tandon 6HA', 1500, 'Area 6 Hektar');

-- Insert jenis benih
INSERT INTO jenis_benih (nama_benih, pemasok, harga_per_satuan, jenis_satuan, ukuran_satuan) VALUES
('Selada Bumi Grand Rapid', 'Mutiara Bumi', 33000, 'gram', '8 gram'),
('Selada KYS Grand Rapid', 'KYS', 0, 'gram', '8 gram'),
('Romaine Veropas', 'Veropas', 900000, 'biji', '5000 biji'),
('Selada Sonybel', 'Sony', 65000, 'gram', '1 gram'),
('Selada Lilybel', 'Lily', 255000, 'biji', '1000 biji'),
('Selada Kebab', 'Pemasok A', 0, 'tray', '1 tray'),
('Selada Bagus', 'Pemasok B', 0, 'tray', '1 tray'),
('Romain', 'Pemasok C', 0, 'tray', '1 tray'),
('Romaine Maximus', 'Pemasok D', 0, 'hampan', '1 hampan');

-- Insert pengguna default (password: admin123)
INSERT INTO pengguna (nama_pengguna, nama_lengkap, email, password_hash, peran) VALUES
('admin', 'Administrator', 'admin@hidroponik.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('operator1', 'Operator 1', 'operator1@hidroponik.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'operator');

-- ========================================
-- VIEWS UNTUK LAPORAN
-- ========================================

-- View untuk ringkasan penjualan harian
CREATE VIEW v_ringkasan_penjualan_harian AS
SELECT 
    p.tanggal_jual,
    pel.nama_pelanggan,
    p.jenis_sayur,
    SUM(p.jumlah) as total_jumlah,
    p.satuan,
    SUM(p.total_harga) as total_penjualan,
    u.nama_lengkap as dicatat_oleh_nama
FROM penjualan_harian p
JOIN pelanggan pel ON p.id_pelanggan = pel.id_pelanggan
JOIN pengguna u ON p.dicatat_oleh = u.id_pengguna
WHERE p.status_kirim != 'batal'
GROUP BY p.tanggal_jual, p.id_pelanggan, p.jenis_sayur;

-- View untuk monitoring PPM harian semua tandon
CREATE VIEW v_monitoring_ppm_harian AS
SELECT 
    m.tanggal_monitoring,
    t.kode_tandon,
    t.nama_tandon,
    m.nilai_ppm,
    m.air_ditambah,
    m.nutrisi_ditambah,
    m.tingkat_ph,
    u.nama_lengkap as dicatat_oleh_nama
FROM monitoring_nutrisi_harian m
JOIN tandon_air t ON m.id_tandon = t.id_tandon
JOIN pengguna u ON m.dicatat_oleh = u.id_pengguna
ORDER BY m.tanggal_monitoring DESC, t.kode_tandon;

-- View untuk tingkat keberhasilan tanaman
CREATE VIEW v_tingkat_keberhasilan_tanaman AS
SELECT 
    ps.jenis_sayur,
    YEAR(ps.tanggal_tanam) as tahun_tanam,
    MONTH(ps.tanggal_tanam) as bulan_tanam,
    SUM(ps.jumlah_ditanam) as total_ditanam,
    SUM(ps.jumlah_dipanen) as total_dipanen,
    SUM(ps.jumlah_gagal) as total_gagal,
    ROUND(AVG(ps.tingkat_keberhasilan), 2) as rata_rata_keberhasilan
FROM penanaman_sayur ps
GROUP BY ps.jenis_sayur, YEAR(ps.tanggal_tanam), MONTH(ps.tanggal_tanam);

-- View untuk ringkasan pengeluaran bulanan
CREATE VIEW v_pengeluaran_bulanan AS
SELECT 
    YEAR(p.tanggal_pengeluaran) as tahun_pengeluaran,
    MONTH(p.tanggal_pengeluaran) as bulan_pengeluaran,
    kp.nama_kategori,
    SUM(p.jumlah) as total_jumlah,
    COUNT(*) as jumlah_transaksi
FROM pengeluaran_harian p
JOIN kategori_pengeluaran kp ON p.id_kategori = kp.id_kategori
GROUP BY YEAR(p.tanggal_pengeluaran), MONTH(p.tanggal_pengeluaran), kp.nama_kategori;

-- ========================================
-- INDEXES UNTUK PERFORMANCE
-- ========================================

CREATE INDEX idx_penjualan_harian_tanggal ON penjualan_harian(tanggal_jual);
CREATE INDEX idx_pengeluaran_harian_tanggal ON pengeluaran_harian(tanggal_pengeluaran);
CREATE INDEX idx_monitoring_nutrisi_tanggal ON monitoring_nutrisi_harian(tanggal_monitoring);
CREATE INDEX idx_penanaman_sayur_tanggal ON penanaman_sayur(tanggal_tanam);
CREATE INDEX idx_catatan_pembenihan_tanggal ON catatan_pembenihan(tanggal_semai);
CREATE INDEX idx_catatan_perlakuan_tanggal ON catatan_perlakuan(tanggal_perlakuan);