#!/usr/bin/env bash
# Copyright (C) 2022 Muhammad Fadlyas (fadlyas07)
# SPDX-License-Identifier: GPL-3.0-or-later

# Cara Menggunakan Skrip
# 1. (Jika belum) Unduh skrip menggunakan perintah `wget https://github.com/fadlyas07/scripts/raw/master/upload.sh`
# 2. Edit skrip sesuai dengan apa yang dibutuhkan
# 3. Jalankan skrip menggunakan perintah `bash upload.sh <Tempat file> <NamaFile>`
#      contoh: bash upload.sh "/home/greenforce/syberia/out/target/product/chime/Syberia-blablabla.zip" "Syberia-blablabla.zip"

# Lingkungan Utama -> EDIT DISINI <-
export UsernameGitHub=     # Username akun GitHub / Organisasi Anda, contoh -> 'fadlyas07'
export TokenGithub=         # Token GitHub akun Anda, biasanya di mulai dengan -> 'gh_xxxxxx'
export TargetRilisRepository=        # Nama repository yang ingin Anda gunakan sebagai tempat mengunggah file, contoh -> 'android-release'

# JANGAN DIRUBAH!
export FolderSaatIni=$(pwd)
export TempatFile=${1} # Ini adalah "PATH" atau jalan dimana skrip bisa menemukan file Anda, contoh '/home/greenforce/syberia/out/target/product/chime/Syberia-blablabla.zip'
export NamaFile=${2} # Ini adalah nama dari file yang ingin Anda unggah, contoh 'Syberia-blablabla.zip' (nama file dapat dirubah, pastikan ekstensi file tetap sama)
export PerkiraanUkuran=$(echo "$(du -sh ${TempatFile} | cut -c 1-4 | sed 's/	//g')B")

GitHubRilis="${FolderSaatIni}/github-release"
if ! [[ -e "${GitHubRilis}" ]]; then
    curl -Lo "${FolderSaatIni}/github-release" https://github.com/fadlyas07/scripts/raw/master/github/github-release
else
    echo "File 'github-release' sudah ada!"
fi
chmod +x "${GitHubRilis}"

if [[ -e "${TempatFile}" && -e "${GitHubRilis}" ]]; then
    echo "Mengunggah..."
    BuatRilisTag() {
        ./github-release release \
            --security-token "${TokenGithub}" \
            --user "${UsernameGitHub}" \
            --repo "${TargetRilisRepository}" \
            --tag "release" \
            --name "release" \
            --description "Release tag for my files :3" || echo "Tag sudah ada!"
    }   
    UnggahFile() {
        ./github-release upload \
                --security-token "${TokenGithub}" \
                --user "${UsernameGitHub}" \
                --repo "${TargetRilisRepository}" \
                --tag "release" \
                --name "${NamaFile}" \
                --file "${TempatFile}" || echo "GAGAL Mengupload file, periksa kembali!"
    }
    if [[ $(BuatRilisTag) == "Tag sudah ada!" ]]; then
        echo "Tag sudah dibuat, lanjut mengunggah ${NamaFile}..."
    fi
    if [[ $(UnggahFile) == "GAGAL Mengupload file, periksa kembali!" ]]; then
        echo "File gagal di unggah, akan di coba lagi setelah 8 detik..."
        sleep 8s
        chmod +x "${GitHubRilis}"
        UnggahFile || echo "gagal lagi, file tidak bisa di upload ke GitHub Release!"
    else
        echo -e "File sukses di unggah! file berukuran ${PerkiraanUkuran}
        
        Link akan di tampilkan dalam 3 detik..."
        sleep 3s
        LINK="https://github.com/${UsernameGitHub}/${TargetRilisRepository}/releases/download/release/${NamaFile}"
        echo -e "Pengunggahan selesai!
        
        NAMA FILE: ${NamaFile}
        TEMPAT FILE: ${TempatFile}
        UKURAN FILE: ${PerkiraanUkuran}
        LINK: ${LINK}
        
        "
    fi
else
    echo "File di ${TempatFile} tidak terdeteksi

    Mohon periksa kembali!"
    exit 1
fi
